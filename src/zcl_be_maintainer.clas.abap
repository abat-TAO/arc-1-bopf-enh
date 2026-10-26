"! Maintenance of an enhancement object: consistency check, Check & Correct, and regeneration after changes
"! the configuration does not notice, such as appends to the data structures of standard nodes
CLASS zcl_be_maintainer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF check_result,
        enhancement   TYPE string,
        findings      TYPE zcl_be_meta_model=>findings,
        base_findings TYPE zcl_be_meta_model=>findings,
      END OF check_result.

    TYPES:
      BEGIN OF change_result,
        operation           TYPE string,
        enhancement         TYPE string,
        constants_interface TYPE string,
        package             TYPE string,
        transport           TYPE string,
        dry_run             TYPE abap_bool,
        "! Refresh: the constants interface is regenerated, but Check & Correct failed afterwards
        correction_failed   TYPE abap_bool,
      END OF change_result.

    CONSTANTS:
      BEGIN OF operation,
        refresh TYPE string VALUE `refresh`,
        correct TYPE string VALUE `correct`,
      END OF operation.

    "! Findings located at the base business object are SAP's and listed separately
    METHODS check
      IMPORTING
        enhancement   TYPE string
      RETURNING
        VALUE(result) TYPE check_result
      RAISING
        zcx_be_error.

    "! Regenerates the constants interface of the enhancement, runs Check & Correct and invalidates the runtime
    "! buffer of enhancement and base business object
    METHODS refresh
      IMPORTING
        request       TYPE zcl_be_writer=>request
      RETURNING
        VALUE(result) TYPE change_result
      RAISING
        zcx_be_error.

    "! Check & Correct of the BOPF designer. Changes through this service end with it anyway; this is for
    "! enhancements changed elsewhere and for corrections that failed after a change.
    METHODS correct
      IMPORTING
        request       TYPE zcl_be_writer=>request
      RETURNING
        VALUE(result) TYPE change_result
      RAISING
        zcx_be_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS correct_enhancement
      IMPORTING
        context TYPE zcl_be_change_context=>context
      RAISING
        zcx_be_error.
ENDCLASS.



CLASS zcl_be_maintainer IMPLEMENTATION.

  METHOD check.
    DATA(enhancement_object) = NEW zcl_be_change_context( )->find_enhancement( to_upper( enhancement ) ).
    DATA(check_result) = NEW zcl_be_meta_model( )->check( enhancement_object ).
    result = VALUE #( enhancement   = enhancement_object-bo_name
                      findings      = check_result-findings
                      base_findings = check_result-base_findings ).
  ENDMETHOD.


  METHOD refresh.
    DATA(context) = NEW zcl_be_change_context( )->prepare( enhancement = to_upper( request-enhancement )
                                                           transport   = request-transport
                                                           activity    = zcl_be_change_context=>activity-change ).
    result = VALUE #( operation           = operation-refresh
                      enhancement         = context-enhancement-bo_name
                      constants_interface = context-enhancement-const_interface
                      package             = context-package
                      transport           = context-transport
                      dry_run             = request-dry_run ).
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    DATA(session) = NEW zcl_be_session( package = context-package
                                        request = context-transport ).
    /bobf/cl_conf_model_api=>create_constants_interface( context-enhancement-bo_key ).
    session->close( ).
    TRY.
        correct_enhancement( context ).
      CATCH cx_root.
        " The constants interface is regenerated; the caller learns it from the result instead of repeating,
        " and the operation correct reports the cause
        result-correction_failed = abap_true.
    ENDTRY.
    " Only invalidated: running sessions keep their version until they read the buffer again
    /bobf/cl_conf_toolbox=>invalidate_shared_buffer( it_bo_name = VALUE #( ( context-enhancement-bo_name ) ) ).

    SELECT SINGLE @abap_true FROM seoclass
      WHERE clsname = @context-enhancement-const_interface
      INTO @DATA(exists).
    IF exists = abap_false.
      zcx_be_error=>raise_not_saved( entity_type = `constants interface`
                                     name        = context-enhancement-const_interface ).
    ENDIF.
  ENDMETHOD.


  METHOD correct.
    DATA(context) = NEW zcl_be_change_context( )->prepare( enhancement = to_upper( request-enhancement )
                                                           transport   = request-transport
                                                           activity    = zcl_be_change_context=>activity-change ).
    result = VALUE #( operation           = operation-correct
                      enhancement         = context-enhancement-bo_name
                      constants_interface = context-enhancement-const_interface
                      package             = context-package
                      transport           = context-transport
                      dry_run             = request-dry_run ).
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.
    correct_enhancement( context ).
  ENDMETHOD.


  METHOD correct_enhancement.
    DATA(session) = NEW zcl_be_session( package = context-package
                                        request = context-transport ).
    TRY.
        NEW zcl_be_meta_model( )->correct( bo_key = context-enhancement-bo_key
                                           name   = context-enhancement-bo_name ).
      CLEANUP.
        session->close( ).
    ENDTRY.
    session->close( ).
  ENDMETHOD.

ENDCLASS.
