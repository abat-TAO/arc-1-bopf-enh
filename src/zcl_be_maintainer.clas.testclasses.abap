CLASS ltcl_enhancement_maintainer DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS require_fixture RAISING cx_static_check.
    METHODS assert_error IMPORTING
      error  TYPE REF TO zcx_be_error
      status TYPE i
      number TYPE symsgno.
    METHODS reject_unknown_enhancement FOR TESTING RAISING cx_static_check.
    METHODS reject_base_as_enhancement FOR TESTING RAISING cx_static_check.
    METHODS check_fixture_read_only FOR TESTING RAISING cx_static_check.
    METHODS correct_fixture_dry_run FOR TESTING RAISING cx_static_check.
    METHODS correct_rejects_unknown FOR TESTING RAISING cx_static_check.
    METHODS correct_rejects_base FOR TESTING RAISING cx_static_check.
    METHODS refresh_fixture_dry_run FOR TESTING RAISING cx_static_check.
ENDCLASS.
CLASS ltcl_enhancement_maintainer IMPLEMENTATION.
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

  METHOD reject_unknown_enhancement.
    TRY.
        NEW zcl_be_maintainer( )->check( 'ZBE_UNIT_DOES_NOT_EXIST' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 001' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 404
          number = '001' ).
    ENDTRY.
  ENDMETHOD.

  METHOD reject_base_as_enhancement.
    TRY.
        NEW zcl_be_maintainer( )->check( '/BOBF/EPM_SALES_ORDER' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 002' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 404
          number = '002' ).
    ENDTRY.
  ENDMETHOD.

  METHOD correct_fixture_dry_run.
    require_fixture( ).
    DATA(result) = NEW zcl_be_maintainer( )->correct( VALUE #( enhancement = 'zbe_test_so' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_equals(
      act = result-operation
      exp = zcl_be_maintainer=>operation-correct ).
    cl_abap_unit_assert=>assert_equals(
      act = result-enhancement
      exp = 'ZBE_TEST_SO' ).
    cl_abap_unit_assert=>assert_equals(
      act = result-constants_interface
      exp = 'ZIF_BE_TEST_SO_C' ).
    cl_abap_unit_assert=>assert_equals(
      act = result-package
      exp = '$TMP' ).
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    cl_abap_unit_assert=>assert_false( result-correction_failed ).
  ENDMETHOD.

  METHOD correct_rejects_unknown.
    TRY.
        NEW zcl_be_maintainer( )->correct( VALUE #( enhancement = 'ZBE_UNIT_DOES_NOT_EXIST' dry_run = abap_true ) ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 001' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 404
          number = '001' ).
    ENDTRY.
  ENDMETHOD.

  METHOD correct_rejects_base.
    TRY.
        NEW zcl_be_maintainer( )->correct( VALUE #( enhancement = '/BOBF/EPM_SALES_ORDER' dry_run = abap_true ) ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 002' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 404
          number = '002' ).
    ENDTRY.
  ENDMETHOD.

  METHOD refresh_fixture_dry_run.
    require_fixture( ).
    DATA(result) = NEW zcl_be_maintainer( )->refresh( VALUE #( enhancement = 'zbe_test_so' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_equals(
      act = result-operation
      exp = zcl_be_maintainer=>operation-refresh ).
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    cl_abap_unit_assert=>assert_false( result-correction_failed ).
  ENDMETHOD.

  METHOD check_fixture_read_only.
    require_fixture( ).
    " Depends on the read-only fixture ZBE_TEST_SO; no refresh is called.
    DATA(reader) = NEW zcl_be_reader( ).
    DATA(before) = reader->get_enhancement( 'ZBE_TEST_SO' ).
    DATA(result) = NEW zcl_be_maintainer( )->check( 'zbe_test_so' ).
    cl_abap_unit_assert=>assert_equals(
      act = result-enhancement
      exp = 'ZBE_TEST_SO' ).
    cl_abap_unit_assert=>assert_false(
      act = xsdbool( line_exists( result-findings[ severity = `E` ] )
                     OR line_exists( result-findings[ severity = `A` ] )
                     OR line_exists( result-findings[ severity = `X` ] ) )
      msg = 'The fixture must have no own error findings' ).
    cl_abap_unit_assert=>assert_equals(
      act = reader->get_enhancement( 'ZBE_TEST_SO' )
      exp = before ).
  ENDMETHOD.
ENDCLASS.
