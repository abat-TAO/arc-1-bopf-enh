CLASS ltcl_bopf_exception DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS assert_error IMPORTING
      error TYPE REF TO zcx_be_error
      status TYPE i
      number TYPE symsgno.
    METHODS default_status_is_400 FOR TESTING RAISING cx_static_check.
    METHODS preserve_status_and_previous FOR TESTING RAISING cx_static_check.
    METHODS unbound_messages_have_no_error FOR TESTING RAISING cx_static_check.
    METHODS warnings_have_no_error FOR TESTING RAISING cx_static_check.
    METHODS return_first_error FOR TESTING RAISING cx_static_check.
    METHODS accept_abort_and_exit FOR TESTING RAISING cx_static_check.
    METHODS not_saved_keeps_first_error FOR TESTING RAISING cx_static_check.
    METHODS not_saved_without_messages FOR TESTING RAISING cx_static_check.
ENDCLASS.
CLASS ltcl_bopf_exception IMPLEMENTATION.
  METHOD assert_error.
    cl_abap_unit_assert=>assert_equals(
      act = error->status
      exp = status ).
    cl_abap_unit_assert=>assert_equals(
      act = error->if_t100_message~t100key-msgid
      exp = 'ZBE_BOPF_ENH' ).
    cl_abap_unit_assert=>assert_equals(
      act = error->if_t100_message~t100key-msgno
      exp = number ).
  ENDMETHOD.

  METHOD default_status_is_400.
    DATA(error) = NEW zcx_be_error( ).
    cl_abap_unit_assert=>assert_equals(
      act = error->status
      exp = 400 ).
  ENDMETHOD.

  METHOD preserve_status_and_previous.
    DATA(previous) = NEW zcx_be_error( status = 403 ).
    DATA(error) = NEW zcx_be_error(
      status   = 422
      previous = previous
      textid   = VALUE #( msgid = 'ZBE_BOPF_ENH' msgno = '026' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = error->status
      exp = 422 ).
    cl_abap_unit_assert=>assert_equals(
      act = error->previous
      exp = previous ).
    cl_abap_unit_assert=>assert_equals(
      act = error->if_t100_message~t100key-msgno
      exp = '026' ).
  ENDMETHOD.

  METHOD unbound_messages_have_no_error.
    cl_abap_unit_assert=>assert_not_bound( zcx_be_error=>get_first_error( VALUE #( ) ) ).
  ENDMETHOD.

  METHOD warnings_have_no_error.
    DATA(messages) = /bobf/cl_frw_factory=>get_message( ).
    messages->add_cm( NEW /bobf/cm_frw_symsg( severity = 'W' ) ).
    messages->add_cm( NEW /bobf/cm_frw_symsg( severity = 'I' ) ).
    cl_abap_unit_assert=>assert_not_bound( zcx_be_error=>get_first_error( messages ) ).
  ENDMETHOD.

  METHOD return_first_error.
    DATA(messages) = /bobf/cl_frw_factory=>get_message( ).
    DATA(first_error) = NEW /bobf/cm_frw_symsg( severity = 'E' ).
    messages->add_cm( NEW /bobf/cm_frw_symsg( severity = 'W' ) ).
    messages->add_cm( first_error ).
    messages->add_cm( NEW /bobf/cm_frw_symsg( severity = 'A' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = zcx_be_error=>get_first_error( messages )
      exp = first_error ).
  ENDMETHOD.

  METHOD accept_abort_and_exit.
    DATA messages TYPE REF TO /bobf/if_frw_message.
    DATA first_error TYPE REF TO /bobf/cm_frw_symsg.
    LOOP AT VALUE string_table( ( `A` ) ( `X` ) ) ASSIGNING FIELD-SYMBOL(<severity>).
      messages = /bobf/cl_frw_factory=>get_message( ).
      first_error = NEW /bobf/cm_frw_symsg( severity = CONV #( <severity> ) ).
      messages->add_cm( first_error ).
      cl_abap_unit_assert=>assert_equals(
        act = zcx_be_error=>get_first_error( messages )
        exp = first_error ).
    ENDLOOP.
  ENDMETHOD.

  METHOD not_saved_keeps_first_error.
    DATA(messages) = /bobf/cl_frw_factory=>get_message( ).
    DATA(first_error) = NEW /bobf/cm_frw_symsg( severity = 'E' ).
    messages->add_cm( first_error ).
    TRY.
      zcx_be_error=>raise_not_saved(
        entity_type = 'node'
        name        = 'ZNOTE'
        messages    = messages ).
      cl_abap_unit_assert=>fail( 'Expected save rejection' ).
    CATCH zcx_be_error INTO DATA(error).
      assert_error(
        error  = error
        status = 422
        number = '018' ).
      cl_abap_unit_assert=>assert_equals(
        act = error->previous
        exp = first_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD not_saved_without_messages.
    TRY.
      zcx_be_error=>raise_not_saved(
        entity_type = 'node'
        name        = 'ZNOTE' ).
      cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 018' ).
    CATCH zcx_be_error INTO DATA(error).
      assert_error(
        error  = error
        status = 422
        number = '018' ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
