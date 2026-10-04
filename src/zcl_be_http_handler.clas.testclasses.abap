CLASS ltcl_http_server DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    INTERFACES if_http_server PARTIALLY IMPLEMENTED.
    METHODS constructor.
ENDCLASS.

CLASS ltcl_http_server IMPLEMENTATION.
  METHOD constructor.
    if_http_server~request = NEW cl_http_request( add_c_msg = 1 ).
    if_http_server~response = NEW cl_http_response( add_c_msg = 1 ).
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_names_http DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF message,
        id     TYPE string,
        number TYPE string,
      END OF message,
      messages TYPE STANDARD TABLE OF message WITH EMPTY KEY,
      BEGIN OF error_response,
        messages TYPE messages,
      END OF error_response,
      BEGIN OF names_response,
        result TYPE zcl_be_writer=>names,
      END OF names_response.
    DATA server TYPE REF TO if_http_server.
    METHODS setup.
    METHODS get_names_returns_json FOR TESTING.
    METHODS get_names_requires_operation FOR TESTING.
    METHODS get_names_requires_name FOR TESTING.
    METHODS get_names_rejects_update FOR TESTING.
    METHODS enhancement_passes_node FOR TESTING RAISING cx_static_check.
    METHODS assert_http_error IMPORTING
      status TYPE i
      number TYPE string.
ENDCLASS.

CLASS ltcl_names_http IMPLEMENTATION.
  METHOD setup.
    " In-memory HTTP messages exercise GET dispatch without an ICF call or SAP changes.
    server = NEW ltcl_http_server( ).
    server->request->set_method( 'GET' ).
    server->request->set_header_field( name  = '~path_info'
                                       value = '/names' ).
  ENDMETHOD.

  METHOD get_names_returns_json.
    DATA response TYPE names_response.
    server->request->set_form_field( name  = 'operation'
                                     value = 'createEnhancement' ).
    server->request->set_form_field( name  = 'name'
                                     value = 'zbe_unit_http' ).
    NEW zcl_be_http_handler( )->if_http_extension~handle_request( server ).
    server->response->get_status( IMPORTING code = DATA(status) ).
    cl_abap_unit_assert=>assert_equals( act = status
                                        exp = 200 ).
    cl_abap_unit_assert=>assert_equals( act = server->response->get_content_type( )
      exp                                   = 'application/json; charset=utf-8' ).
    zcl_be_json=>from_json( EXPORTING json = server->response->get_cdata( ) CHANGING data = response ).
    cl_abap_unit_assert=>assert_equals( act = response-result-operation
                                        exp = 'createEnhancement' ).
    cl_abap_unit_assert=>assert_equals( act = response-result-name
                                        exp = 'ZBE_UNIT_HTTP' ).
    cl_abap_unit_assert=>assert_not_initial( response-result-constants_interface ).
  ENDMETHOD.

  METHOD get_names_requires_operation.
    server->request->set_form_field( name  = 'name'
                                     value = 'ZBE_UNIT_HTTP' ).
    assert_http_error( status = 400
                       number = '004' ).
  ENDMETHOD.

  METHOD get_names_requires_name.
    server->request->set_form_field( name  = 'operation'
                                     value = 'createEnhancement' ).
    assert_http_error( status = 400
                       number = '004' ).
  ENDMETHOD.

  METHOD get_names_rejects_update.
    server->request->set_form_field( name  = 'operation'
                                     value = 'updateEnhancement' ).
    server->request->set_form_field( name  = 'name'
                                     value = 'ZBE_UNIT_HTTP' ).
    assert_http_error( status = 400
                       number = '020' ).
  ENDMETHOD.

  METHOD enhancement_passes_node.
    TRY.
        NEW zcl_be_change_context( )->find_business_object( 'ZBE_TEST_SO' ).
      CATCH zcx_be_error INTO DATA(error).
        IF error->status = 404 AND error->if_t100_message~t100key-msgid = 'ZBE_BOPF_ENH'
            AND error->if_t100_message~t100key-msgno = '001'.
          cl_abap_unit_assert=>skip( 'Test data missing: run ZCL_BE_TEST_FIXTURE first' ).
          RETURN.
        ENDIF.
        RAISE EXCEPTION error.
    ENDTRY.
    server->request->set_header_field( name  = '~path_info'
                                       value = '/enhancement' ).
    server->request->set_form_field( name  = 'name'
                                     value = 'ZBE_TEST_SO' ).
    server->request->set_form_field( name  = 'node'
                                     value = 'ZBE_UNIT_UNKNOWN_NODE' ).
    assert_http_error( status = 404
                       number = '010' ).
  ENDMETHOD.

  METHOD assert_http_error.
    DATA response TYPE error_response.
    NEW zcl_be_http_handler( )->if_http_extension~handle_request( server ).
    server->response->get_status( IMPORTING code = DATA(actual_status) ).
    cl_abap_unit_assert=>assert_equals( act = actual_status
                                        exp = status ).
    zcl_be_json=>from_json( EXPORTING json = server->response->get_cdata( ) CHANGING data = response ).
    cl_abap_unit_assert=>assert_equals( act = lines( response-messages )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = response-messages[ 1 ]-id
                                        exp = 'ZBE_BOPF_ENH' ).
    cl_abap_unit_assert=>assert_equals( act = response-messages[ 1 ]-number
                                        exp = number ).
  ENDMETHOD.
ENDCLASS.
