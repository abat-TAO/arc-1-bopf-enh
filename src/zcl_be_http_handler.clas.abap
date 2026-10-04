"! ICF handler of the BOPF enhancement API; answers {"result": ...} or {"messages": [...]}
CLASS zcl_be_http_handler DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF message,
        severity TYPE string,
        id       TYPE string,
        number   TYPE string,
        text     TYPE string,
      END OF message,
      messages TYPE STANDARD TABLE OF message WITH EMPTY KEY.

    METHODS check_csrf_token
      IMPORTING
        server TYPE REF TO if_http_server
      RAISING
        zcx_be_error.

    METHODS dispatch
      IMPORTING
        request       TYPE REF TO if_http_request
      RETURNING
        VALUE(result) TYPE string
      RAISING
        zcx_be_error.

    METHODS read
      IMPORTING
        request       TYPE REF TO if_http_request
        resource      TYPE string
      RETURNING
        VALUE(result) TYPE string
      RAISING
        zcx_be_error.

    METHODS write
      IMPORTING
        request       TYPE REF TO if_http_request
      RETURNING
        VALUE(result) TYPE string
      RAISING
        zcx_be_error.

    METHODS get_required_field
      IMPORTING
        request       TYPE REF TO if_http_request
        name          TYPE string
      RETURNING
        VALUE(result) TYPE string
      RAISING
        zcx_be_error.

    METHODS to_messages
      IMPORTING
        error         TYPE REF TO cx_root
      RETURNING
        VALUE(result) TYPE messages.

    METHODS respond
      IMPORTING
        response TYPE REF TO if_http_response
        status   TYPE i
        body     TYPE string.
    METHODS raise_unknown_resource
      IMPORTING
        resource TYPE string
      RAISING
        zcx_be_error.
ENDCLASS.



CLASS zcl_be_http_handler IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    TRY.
        IF server->request->get_method( ) <> 'GET'.
          check_csrf_token( server ).
        ENDIF.
        DATA(result) = dispatch( server->request ).
        respond( response = server->response
                 status   = 200
                 body     = |\{"result":{ result }\}| ).
      CATCH zcx_be_error INTO DATA(error).
        respond( response = server->response
                 status   = error->status
                 body     = |\{"messages":{ zcl_be_json=>to_json( to_messages( error ) ) }\}| ).
      CATCH cx_root INTO DATA(unexpected).
        respond( response = server->response
                 status   = 500
                 body     = |\{"messages":{ zcl_be_json=>to_json( to_messages( unexpected ) ) }\}| ).
    ENDTRY.
  ENDMETHOD.


  METHOD check_csrf_token.
    server->validate_xsrf_token(
      EXPORTING
        token      = server->request->get_header_field( 'x-csrf-token' )
      IMPORTING
        successful = DATA(is_valid)
      EXCEPTIONS
        OTHERS     = 1 ).
    IF sy-subrc <> 0 OR is_valid = abap_false.
      " Tells the caller to fetch a new token and repeat the request
      server->response->set_header_field( name  = 'x-csrf-token'
                                          value = 'Required' ).
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e019(zbe_bopf_enh) EXPORTING status = 403.
    ENDIF.
  ENDMETHOD.


  METHOD dispatch.
    DATA(resource) = to_lower( request->get_header_field( '~path_info' ) ).
    SHIFT resource LEFT DELETING LEADING '/'.
    DATA(method) = request->get_method( ).
    CASE method.
      WHEN 'GET'.
        result = read( request  = request
                       resource = resource ).
      WHEN 'POST'.
        IF resource <> `write`.
          raise_unknown_resource( resource ).
        ENDIF.
        result = write( request ).
      WHEN OTHERS.
        RAISE EXCEPTION TYPE zcx_be_error MESSAGE e005(zbe_bopf_enh) WITH method resource EXPORTING status = 405.
    ENDCASE.
  ENDMETHOD.


  METHOD read.
    DATA(reader) = NEW zcl_be_reader( ).
    DATA(scope) = to_lower( request->get_form_field( `scope` ) ).
    CASE resource.
      WHEN `businessobjects`.
        result = zcl_be_json=>to_json( reader->get_business_objects( ) ).
      WHEN `enhancements`.
        result = zcl_be_json=>to_json( reader->get_enhancements( get_required_field( request = request
                                                                                     name    = `baseBo` ) ) ).
      WHEN `enhancement`.
        result = zcl_be_json=>to_json( reader->get_enhancement(
                   name  = get_required_field( request = request
                                               name    = `name` )
                   scope = COND #( WHEN scope IS INITIAL THEN zcl_be_reader=>scope-own ELSE scope )
                   node  = request->get_form_field( `node` ) ) ).
      WHEN `deletepreview`.
        result = zcl_be_json=>to_json( NEW zcl_be_deleter( )->get_preview(
                   enhancement = get_required_field( request = request
                                                     name    = `enhancement` )
                   entity_type = get_required_field( request = request
                                                     name    = `entityType` )
                   name        = get_required_field( request = request
                                                     name    = `name` )
                   transport   = request->get_form_field( `transport` ) ) ).
      WHEN `names`.
        result = zcl_be_json=>to_json( NEW zcl_be_writer( )->get_names( VALUE #(
                   operation   = get_required_field( request = request
                                                     name    = `operation` )
                   name        = request->get_form_field( `name` )
                   enhancement = request->get_form_field( `enhancement` )
                   node        = request->get_form_field( `node` )
                   base_action = request->get_form_field( `baseAction` )
                   action      = request->get_form_field( `action` ) ) ) ).
      WHEN `check`.
        result = zcl_be_json=>to_json( NEW zcl_be_maintainer( )->check(
                   get_required_field( request = request
                                       name    = `enhancement` ) ) ).
      WHEN OTHERS.
        raise_unknown_resource( resource ).
    ENDCASE.
  ENDMETHOD.


  METHOD write.
    DATA change_request TYPE zcl_be_writer=>request.

    DATA(body) = request->get_cdata( ).
    zcl_be_json=>from_json( EXPORTING json = body
                            CHANGING  data = change_request ).
    CASE change_request-operation.
      WHEN ``.
        RAISE EXCEPTION TYPE zcx_be_error MESSAGE e006(zbe_bopf_enh) EXPORTING status = 400.
      WHEN zcl_be_deleter=>operation.
        result = zcl_be_json=>to_json( NEW zcl_be_deleter( )->delete( change_request ) ).
      WHEN zcl_be_maintainer=>operation.
        result = zcl_be_json=>to_json( NEW zcl_be_maintainer( )->refresh( change_request ) ).
      WHEN OTHERS.
        result = zcl_be_json=>to_json( NEW zcl_be_writer( )->write( change_request ) ).
    ENDCASE.
  ENDMETHOD.


  METHOD get_required_field.
    result = request->get_form_field( name ).
    IF result IS INITIAL.
      zcx_be_error=>raise_missing_parameter( name ).
    ENDIF.
  ENDMETHOD.


  METHOD to_messages.
    DATA(current) = error.
    WHILE current IS BOUND.
      IF current IS INSTANCE OF if_t100_message.
        INSERT VALUE #( LET t100_key = CAST if_t100_message( current )->t100key IN
                        severity = `E`
                        id       = t100_key-msgid
                        number   = t100_key-msgno
                        text     = current->get_text( ) ) INTO TABLE result.
      ELSE.
        INSERT VALUE #( severity = `E`
                        text     = current->get_text( ) ) INTO TABLE result.
      ENDIF.
      current = current->previous.
    ENDWHILE.
  ENDMETHOD.


  METHOD respond.
    response->set_status( code   = status
                          reason = SWITCH string( status
                                                  WHEN 200 THEN `OK`
                                                  WHEN 400 THEN `Bad Request`
                                                  WHEN 403 THEN `Forbidden`
                                                  WHEN 404 THEN `Not Found`
                                                  WHEN 405 THEN `Method Not Allowed`
                                                  WHEN 409 THEN `Conflict`
                                                  WHEN 422 THEN `Unprocessable Content`
                                                  ELSE `Internal Server Error` ) ).
    response->set_content_type( `application/json; charset=utf-8` ).
    " Browsers must not interpret the JSON as HTML
    response->set_header_field( name  = 'x-content-type-options'
                                value = 'nosniff' ).
    response->set_cdata( body ).
  ENDMETHOD.


  METHOD raise_unknown_resource.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e003(zbe_bopf_enh) WITH resource EXPORTING status = 404.
  ENDMETHOD.
ENDCLASS.

