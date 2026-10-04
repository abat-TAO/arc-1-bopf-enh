CLASS ltcl_change_context DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS find_requires_name FOR TESTING RAISING cx_static_check.
    METHODS find_rejects_standard FOR TESTING RAISING cx_static_check.
    METHODS find_rejects_unknown FOR TESTING RAISING cx_static_check.
    METHODS find_returns_fixture FOR TESTING RAISING cx_static_check.
    METHODS require_fixture RAISING cx_static_check.
    METHODS assert_error IMPORTING
      error  TYPE REF TO zcx_be_error
      status TYPE i
      number TYPE symsgno.
    METHODS resolve_language_codes FOR TESTING RAISING cx_static_check.
    METHODS use_fallback_language FOR TESTING RAISING cx_static_check.
    METHODS reject_unknown_language FOR TESTING RAISING cx_static_check.
    METHODS reject_long_language FOR TESTING RAISING cx_static_check.
    METHODS ignore_local_transport FOR TESTING RAISING cx_static_check.
    METHODS reject_missing_enhancement FOR TESTING RAISING cx_static_check.
    METHODS reject_unknown_object FOR TESTING RAISING cx_static_check.
    METHODS reject_base_object FOR TESTING RAISING cx_static_check.
    METHODS prepare_local_fixture FOR TESTING RAISING cx_static_check.
ENDCLASS.
CLASS ltcl_change_context IMPLEMENTATION.
  METHOD find_requires_name.
    TRY.
        NEW zcl_be_change_context( )->find_enhancement( '' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 004' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error( error  = error
                      status = 400
                      number = '004' ).
    ENDTRY.
  ENDMETHOD.

  METHOD find_rejects_standard.
    TRY.
        NEW zcl_be_change_context( )->find_enhancement( '/BOBF/EPM_SALES_ORDER' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 002' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error( error  = error
                      status = 404
                      number = '002' ).
    ENDTRY.
  ENDMETHOD.

  METHOD find_rejects_unknown.
    TRY.
        NEW zcl_be_change_context( )->find_enhancement( 'ZBE_UNIT_DOES_NOT_EXIST' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 001' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error( error  = error
                      status = 404
                      number = '001' ).
    ENDTRY.
  ENDMETHOD.

  METHOD find_returns_fixture.
    DATA result TYPE /bobf/s_conf_model_api_bo.
    require_fixture( ).
    result = NEW zcl_be_change_context( )->find_enhancement( 'zbe_test_so' ).
    cl_abap_unit_assert=>assert_equals( act = result-bo_name
                                        exp = 'ZBE_TEST_SO' ).
    cl_abap_unit_assert=>assert_equals( act = result-super_bo_name
                                        exp = '/BOBF/EPM_SALES_ORDER' ).
    cl_abap_unit_assert=>assert_true( result-extension ).
    cl_abap_unit_assert=>assert_not_initial( result-bo_key ).
  ENDMETHOD.

  METHOD require_fixture.
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
  ENDMETHOD.

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

  METHOD resolve_language_codes.
    DATA(context) = NEW zcl_be_change_context( ).
    cl_abap_unit_assert=>assert_equals(
      act = context->resolve_language( requested = 'E' fallback = 'D' )
      exp = 'E' ).
    cl_abap_unit_assert=>assert_equals(
      act = context->resolve_language( requested = 'D' fallback = 'E' )
      exp = 'D' ).
    cl_abap_unit_assert=>assert_equals(
      act = context->resolve_language( requested = 'en' fallback = 'D' )
      exp = 'E' ).
    cl_abap_unit_assert=>assert_equals(
      act = context->resolve_language( requested = 'de' fallback = 'E' )
      exp = 'D' ).
  ENDMETHOD.

  METHOD use_fallback_language.
    cl_abap_unit_assert=>assert_equals(
      act = NEW zcl_be_change_context( )->resolve_language( requested = '' fallback = 'D' )
      exp = 'D' ).
  ENDMETHOD.

  METHOD reject_unknown_language.
    TRY.
        NEW zcl_be_change_context( )->resolve_language(
          requested = 'ZZ'
          fallback  = 'E' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 024' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 400
          number = '024' ).
    ENDTRY.
  ENDMETHOD.

  METHOD reject_long_language.
    TRY.
        NEW zcl_be_change_context( )->resolve_language(
          requested = 'UNKNOWN'
          fallback  = 'E' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 024' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 400
          number = '024' ).
    ENDTRY.
  ENDMETHOD.

  METHOD ignore_local_transport.
    DATA(context) = NEW zcl_be_change_context( ).
    LOOP AT VALUE string_table( ( `$TMP` ) ( `$ZBE_BOPF_ENH` ) ) ASSIGNING FIELD-SYMBOL(<package>).
      cl_abap_unit_assert=>assert_initial( context->resolve_transport(
        package     = CONV #( <package> )
        object_name = 'ZBE_TEST_SO'
        requested   = 'INVALID' ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD reject_missing_enhancement.
    TRY.
        NEW zcl_be_change_context( )->prepare(
          enhancement = ''
          activity    = '02' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 004' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 400
          number = '004' ).
    ENDTRY.
  ENDMETHOD.

  METHOD reject_unknown_object.
    TRY.
        NEW zcl_be_change_context( )->find_business_object( 'ZBE_UNIT_DOES_NOT_EXIST' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 001' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 404
          number = '001' ).
    ENDTRY.
  ENDMETHOD.

  METHOD reject_base_object.
    TRY.
        NEW zcl_be_change_context( )->prepare(
          enhancement = '/BOBF/EPM_SALES_ORDER'
          activity    = '02' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 002' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 404
          number = '002' ).
    ENDTRY.
  ENDMETHOD.

  METHOD prepare_local_fixture.
    require_fixture( ).
    " Depends on the read-only fixture ZBE_TEST_SO and change authorization.
    DATA(result) = NEW zcl_be_change_context( )->prepare(
      enhancement = 'ZBE_TEST_SO'
      activity    = '02'
      language    = 'EN' ).
    cl_abap_unit_assert=>assert_equals(
      act = result-enhancement-bo_name
      exp = 'ZBE_TEST_SO' ).
    cl_abap_unit_assert=>assert_equals(
      act = result-package
      exp = '$TMP' ).
    cl_abap_unit_assert=>assert_initial( result-transport ).
    cl_abap_unit_assert=>assert_equals(
      act = result-language
      exp = 'E' ).
  ENDMETHOD.
ENDCLASS.
