"! Checks and settings every change of an enhancement object needs: the enhancement itself,
"! customer namespace, authorization, package, transport request and text language.
CLASS zcl_be_change_context DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF context,
        enhancement TYPE /bobf/s_conf_model_api_bo,
        package     TYPE devclass,
        transport   TYPE trkorr,
        language    TYPE sy-langu,
      END OF context.

    CONSTANTS:
      BEGIN OF activity,
        create TYPE activ_auth VALUE '01',
        change TYPE activ_auth VALUE '02',
        delete TYPE activ_auth VALUE '06',
      END OF activity.

    "! Context for changing an existing enhancement object
    METHODS prepare
      IMPORTING
        enhancement   TYPE string
        transport     TYPE string OPTIONAL
        language      TYPE string OPTIONAL
        activity      TYPE activ_auth
      RETURNING
        VALUE(result) TYPE context
      RAISING
        zcx_be_error.

    METHODS find_business_object
      IMPORTING
        name          TYPE csequence
      RETURNING
        VALUE(result) TYPE /bobf/s_conf_model_api_bo
      RAISING
        zcx_be_error.

    "! Existing enhancement object; a standard business object of that name is no enhancement
    METHODS find_enhancement
      IMPORTING
        name          TYPE csequence
      RETURNING
        VALUE(result) TYPE /bobf/s_conf_model_api_bo
      RAISING
        zcx_be_error.

    METHODS check_authority
      IMPORTING
        package  TYPE devclass
        name     TYPE csequence
        activity TYPE activ_auth
      RAISING
        zcx_be_error.

    "! No request for local packages; otherwise the requested one or the one the object is locked in
    METHODS resolve_transport
      IMPORTING
        package       TYPE devclass
        object_name   TYPE csequence
        requested     TYPE string
      RETURNING
        VALUE(result) TYPE trkorr
      RAISING
        zcx_be_error.

    "! Accepts the SAP language key (D) or the ISO code (DE)
    METHODS resolve_language
      IMPORTING
        requested     TYPE string
        fallback      TYPE sy-langu
      RETURNING
        VALUE(result) TYPE sy-langu
      RAISING
        zcx_be_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
    "! The requested transport must be a modifiable workbench request or task
    METHODS check_requested_transport
      IMPORTING
        requested     TYPE string
      RETURNING
        VALUE(result) TYPE trkorr
      RAISING
        zcx_be_error.
ENDCLASS.



CLASS zcl_be_change_context IMPLEMENTATION.

  METHOD prepare.
    result-enhancement = find_enhancement( enhancement ).
    IF zcl_be_reader=>is_customer_name( enhancement ) = abap_false.
      zcx_be_error=>raise_not_customer_name( enhancement ).
    ENDIF.

    DATA(object_name) = CONV tadir-obj_name( enhancement ).
    SELECT SINGLE devclass, masterlang FROM tadir
      WHERE pgmid = 'R3TR' AND object = 'BOBX' AND obj_name = @object_name
      INTO @DATA(directory_entry).
    " Without directory entry neither package nor authorization can be checked
    IF sy-subrc <> 0.
      zcx_be_error=>raise_unknown_enhancement( enhancement ).
    ENDIF.
    result-package = directory_entry-devclass.
    check_authority( package  = result-package
                     name     = enhancement
                     activity = activity ).
    result-transport = resolve_transport( package     = result-package
                                          object_name = enhancement
                                          requested   = transport ).
    " Texts are maintained in the original language unless the caller asks for another one
    result-language = resolve_language( requested = language
                                        fallback  = COND #( WHEN directory_entry-masterlang IS INITIAL THEN sy-langu
                                                            ELSE directory_entry-masterlang ) ).
  ENDMETHOD.


  METHOD find_business_object.
    /bobf/cl_conf_model_api=>get_bo_tab( IMPORTING et_bo_tab = DATA(business_objects) ).
    result = VALUE #( business_objects[ bo_name = name ] OPTIONAL ).
    IF result-bo_key IS INITIAL.
      zcx_be_error=>raise_unknown_business_object( name ).
    ENDIF.
  ENDMETHOD.


  METHOD find_enhancement.
    IF name IS INITIAL.
      zcx_be_error=>raise_missing_parameter( `enhancement` ).
    ENDIF.
    result = find_business_object( to_upper( name ) ).
    IF result-extension = abap_false.
      zcx_be_error=>raise_unknown_enhancement( name ).
    ENDIF.
  ENDMETHOD.


  METHOD check_authority.
    DATA(object_name) = CONV tadir-obj_name( name ).
    AUTHORITY-CHECK OBJECT 'S_DEVELOP'
      ID 'DEVCLASS' FIELD package
      ID 'OBJTYPE'  FIELD 'BOBX'
      ID 'OBJNAME'  FIELD object_name
      ID 'P_GROUP'  DUMMY
      ID 'ACTVT'    FIELD activity.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e016(zbe_bopf_enh) WITH name package EXPORTING status = 403.
    ENDIF.
  ENDMETHOD.


  METHOD resolve_transport.
    IF package CP '$*'.
      RETURN.
    ENDIF.
    SELECT SINGLE korrflag FROM tdevc WHERE devclass = @package INTO @DATA(records_changes).
    IF sy-subrc <> 0 OR records_changes = abap_false.
      RETURN.
    ENDIF.

    IF requested IS NOT INITIAL.
      result = check_requested_transport( requested ).
      RETURN.
    ENDIF.

    " An object already recorded in a modifiable request stays in that request
    DATA(object) = CONV trobj_name( object_name ).
    SELECT e070~trkorr, e070~strkorr FROM e071
        INNER JOIN e070 ON e070~trkorr = e071~trkorr
        WHERE e071~pgmid = 'R3TR' AND e071~object = 'BOBX' AND e071~obj_name = @object
        AND ( e070~trstatus = 'D' OR e070~trstatus = 'L' )
        ORDER BY e070~trkorr
        INTO TABLE @DATA(recordings)
        UP TO 1 ROWS.
    IF sy-subrc = 0.
      result = COND #( WHEN recordings[ 1 ]-strkorr IS NOT INITIAL THEN recordings[ 1 ]-strkorr
                       ELSE recordings[ 1 ]-trkorr ).
      RETURN.
    ENDIF.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e017(zbe_bopf_enh) WITH package EXPORTING status = 400.
  ENDMETHOD.


  METHOD resolve_language.
    IF requested IS INITIAL.
      result = fallback.
      RETURN.
    ENDIF.
    DATA(code) = to_upper( requested ).
    " An unknown code leaves the result initial
    CASE strlen( code ).
      WHEN 1.
        SELECT SINGLE spras FROM t002 WHERE spras = @( CONV sy-langu( code ) ) INTO @result ##SUBRC_OK.
      WHEN 2.
        SELECT SINGLE spras FROM t002 WHERE laiso = @( CONV laiso( code ) ) INTO @result ##SUBRC_OK.
    ENDCASE.
    IF result IS INITIAL.
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e024(zbe_bopf_enh) WITH requested EXPORTING status = 400.
    ENDIF.
  ENDMETHOD.


  METHOD check_requested_transport.
    result = CONV #( requested ).
    SELECT SINGLE trfunction, trstatus FROM e070 WHERE trkorr = @result INTO @DATA(request_header).
    IF sy-subrc <> 0
        OR ( request_header-trstatus <> 'D' AND request_header-trstatus <> 'L' )
        OR ( request_header-trfunction <> 'K' AND request_header-trfunction <> 'S' ).
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e021(zbe_bopf_enh) WITH requested EXPORTING status = 400.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
