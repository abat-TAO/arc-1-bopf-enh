CLASS ltcl_enhancement_reader DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS require_fixture RAISING cx_static_check.
    METHODS assert_error IMPORTING
      error  TYPE REF TO zcx_be_error
      status TYPE i
      number TYPE symsgno.
    METHODS accept_customer_names FOR TESTING RAISING cx_static_check.
    METHODS reject_standard_names FOR TESTING RAISING cx_static_check.
    METHODS reject_unknown_enhancement FOR TESTING RAISING cx_static_check.
    METHODS reject_base_as_enhancement FOR TESTING RAISING cx_static_check.
    METHODS read_fixture_header_and_nodes FOR TESTING RAISING cx_static_check.
    METHODS include_fixture_in_list FOR TESTING RAISING cx_static_check.
    METHODS respect_entity_scope FOR TESTING RAISING cx_static_check.
    METHODS compact_base_nodes FOR TESTING RAISING cx_static_check.
    METHODS include_base_actions FOR TESTING RAISING cx_static_check.
    METHODS read_root_in_full FOR TESTING RAISING cx_static_check.
    METHODS accept_lowercase_node FOR TESTING RAISING cx_static_check.
    METHODS reject_unknown_node FOR TESTING RAISING cx_static_check.
    METHODS alternative_keys_are_own FOR TESTING RAISING cx_static_check.
    METHODS assert_root_entities IMPORTING result TYPE zcl_be_reader=>enhancement.
ENDCLASS.
CLASS ltcl_enhancement_reader IMPLEMENTATION.
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

  METHOD accept_customer_names.
    cl_abap_unit_assert=>assert_true( zcl_be_reader=>is_customer_name( 'ZCUSTOMER' ) ).
    cl_abap_unit_assert=>assert_true( zcl_be_reader=>is_customer_name( 'YCUSTOMER' ) ).
  ENDMETHOD.

  METHOD reject_standard_names.
    cl_abap_unit_assert=>assert_false( zcl_be_reader=>is_customer_name( 'SAP_STANDARD' ) ).
    cl_abap_unit_assert=>assert_false( zcl_be_reader=>is_customer_name( '/BOBF/EPM_SALES_ORDER' ) ).
    cl_abap_unit_assert=>assert_false( zcl_be_reader=>is_customer_name( '' ) ).
  ENDMETHOD.

  METHOD reject_unknown_enhancement.
    TRY.
        NEW zcl_be_reader( )->get_enhancement( 'ZBE_UNIT_DOES_NOT_EXIST' ).
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
        NEW zcl_be_reader( )->get_enhancement( '/BOBF/EPM_SALES_ORDER' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 002' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 404
          number = '002' ).
    ENDTRY.
  ENDMETHOD.

  METHOD read_fixture_header_and_nodes.
    require_fixture( ).
    " Depends on the read-only fixture ZBE_TEST_SO with node ZBE_TEST_NOTE.
    DATA(result) = NEW zcl_be_reader( )->get_enhancement( 'ZBE_TEST_SO' ).
    cl_abap_unit_assert=>assert_equals(
      act = result-header-base_business_object
      exp = '/BOBF/EPM_SALES_ORDER' ).
    cl_abap_unit_assert=>assert_equals(
      act = result-header-package
      exp = '$TMP' ).
    cl_abap_unit_assert=>assert_true( result-header-is_changeable ).
    cl_abap_unit_assert=>assert_true( result-nodes[ name = 'ZBE_TEST_NOTE' ]-is_own ).
    cl_abap_unit_assert=>assert_false( result-nodes[ name = 'ROOT' ]-is_own ).
  ENDMETHOD.

  METHOD include_fixture_in_list.
    require_fixture( ).
    " Depends on the read-only fixture ZBE_TEST_SO.
    DATA(enhancements) = NEW zcl_be_reader( )->get_enhancements( '/BOBF/EPM_SALES_ORDER' ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( enhancements[ name = 'ZBE_TEST_SO' ] ) ) ).
  ENDMETHOD.

  METHOD respect_entity_scope.
    require_fixture( ).
    " Depends on the read-only fixture ZBE_TEST_SO and its base entities.
    DATA(reader) = NEW zcl_be_reader( ).
    DATA(own) = reader->get_enhancement( 'ZBE_TEST_SO' ).
    DATA(all) = reader->get_enhancement(
      name  = 'ZBE_TEST_SO'
      scope = 'all' ).
    LOOP AT own-determinations ASSIGNING FIELD-SYMBOL(<determination>).
      cl_abap_unit_assert=>assert_true( <determination>-is_own ).
      cl_abap_unit_assert=>assert_true( xsdbool( line_exists( all-determinations[ name = <determination>-name ] ) ) ).
    ENDLOOP.
    LOOP AT own-validations ASSIGNING FIELD-SYMBOL(<validation>).
      cl_abap_unit_assert=>assert_true( <validation>-is_own ).
    ENDLOOP.
    LOOP AT own-queries ASSIGNING FIELD-SYMBOL(<query>).
      cl_abap_unit_assert=>assert_true( <query>-is_own ).
    ENDLOOP.
    cl_abap_unit_assert=>assert_equals(
      act = own-nodes
      exp = all-nodes ).
    cl_abap_unit_assert=>assert_true( xsdbool( lines( all-determinations ) > lines( own-determinations ) ) ).
  ENDMETHOD.

  METHOD compact_base_nodes.
    require_fixture( ).
    DATA(result) = NEW zcl_be_reader( )->get_enhancement( 'ZBE_TEST_SO' ).
    DATA(root) = result-nodes[ name = 'ROOT' ].
    cl_abap_unit_assert=>assert_initial( root-database_table ).
    cl_abap_unit_assert=>assert_initial( root-combined_structure ).
    cl_abap_unit_assert=>assert_initial( root-transient_structure ).
    cl_abap_unit_assert=>assert_initial( root-table_type ).
    cl_abap_unit_assert=>assert_initial( root-description ).
    cl_abap_unit_assert=>assert_initial( root-is_transient ).
    cl_abap_unit_assert=>assert_not_initial( root-data_structure ).
    DATA(note) = result-nodes[ name = 'ZBE_TEST_NOTE' ].
    cl_abap_unit_assert=>assert_true( note-is_own ).
    cl_abap_unit_assert=>assert_equals( act = note-parent
                                        exp = 'ROOT' ).
    cl_abap_unit_assert=>assert_not_initial( note-data_structure ).
    cl_abap_unit_assert=>assert_not_initial( note-database_table ).
    cl_abap_unit_assert=>assert_not_initial( note-combined_structure ).
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( result-actions[ is_own = abap_false ] ) ) ).
  ENDMETHOD.

  METHOD include_base_actions.
    require_fixture( ).
    DATA(result) = NEW zcl_be_reader( )->get_enhancement( name  = 'ZBE_TEST_SO'
                                                          scope = 'all' ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( result-actions[
      is_own = abap_false category = 'standard' ] ) ) ).
  ENDMETHOD.

  METHOD assert_root_entities.
    cl_abap_unit_assert=>assert_equals( act = lines( result-nodes )
                                        exp = 1 ).
    DATA(root) = result-nodes[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = root-name
                                        exp = 'ROOT' ).
    cl_abap_unit_assert=>assert_false( root-is_own ).
    cl_abap_unit_assert=>assert_not_initial( root-database_table ).
    cl_abap_unit_assert=>assert_not_initial( root-combined_structure ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( result-actions[
      node = 'ROOT' category = 'standard' is_own = abap_false ] ) ) ).
    LOOP AT result-actions ASSIGNING FIELD-SYMBOL(<action>).
      cl_abap_unit_assert=>assert_equals( act = <action>-node
                                          exp = 'ROOT' ).
    ENDLOOP.
    LOOP AT result-determinations ASSIGNING FIELD-SYMBOL(<determination>).
      cl_abap_unit_assert=>assert_equals( act = <determination>-node
                                          exp = 'ROOT' ).
    ENDLOOP.
    LOOP AT result-validations ASSIGNING FIELD-SYMBOL(<validation>).
      cl_abap_unit_assert=>assert_equals( act = <validation>-node
                                          exp = 'ROOT' ).
    ENDLOOP.
    LOOP AT result-queries ASSIGNING FIELD-SYMBOL(<query>).
      cl_abap_unit_assert=>assert_equals( act = <query>-node
                                          exp = 'ROOT' ).
    ENDLOOP.
    LOOP AT result-alternative_keys ASSIGNING FIELD-SYMBOL(<key>).
      cl_abap_unit_assert=>assert_equals( act = <key>-node
                                          exp = 'ROOT' ).
    ENDLOOP.
    LOOP AT result-associations ASSIGNING FIELD-SYMBOL(<association>).
      cl_abap_unit_assert=>assert_equals( act = <association>-source_node
                                          exp = 'ROOT' ).
    ENDLOOP.
  ENDMETHOD.

  METHOD read_root_in_full.
    require_fixture( ).
    DATA(reader) = NEW zcl_be_reader( ).
    DATA(own) = reader->get_enhancement( name  = 'ZBE_TEST_SO'
                                         node  = 'ROOT'
                                         scope = 'own' ).
    assert_root_entities( own ).
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( own-determinations[ is_own = abap_false ] ) ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( own-validations[ is_own = abap_false ] ) ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( own-queries[ is_own = abap_false ] ) ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( own-associations[ is_own = abap_false ] ) ) ).
    DATA(all) = reader->get_enhancement( name  = 'ZBE_TEST_SO'
                                         node  = 'ROOT'
                                         scope = 'all' ).
    assert_root_entities( all ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( all-determinations[ is_own = abap_false ] ) ) ).
  ENDMETHOD.

  METHOD accept_lowercase_node.
    require_fixture( ).
    DATA(reader) = NEW zcl_be_reader( ).
    DATA(result) = reader->get_enhancement( name = 'ZBE_TEST_SO'
                                            node = 'root' ).
    assert_root_entities( result ).
    cl_abap_unit_assert=>assert_equals( act = result
      exp                                   = reader->get_enhancement( name = 'ZBE_TEST_SO' node = 'ROOT' ) ).
  ENDMETHOD.

  METHOD reject_unknown_node.
    require_fixture( ).
    TRY.
        NEW zcl_be_reader( )->get_enhancement( name = 'ZBE_TEST_SO'
                                               node = 'ZBE_UNIT_UNKNOWN_NODE' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 010' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error( error  = error
                      status = 404
                      number = '010' ).
    ENDTRY.
  ENDMETHOD.

  METHOD alternative_keys_are_own.
    require_fixture( ).
    DATA(result) = NEW zcl_be_reader( )->get_enhancement( 'ZBE_TEST_SO' ).
    IF result-alternative_keys IS INITIAL.
      cl_abap_unit_assert=>skip( 'Test data missing: fixture has no alternative keys' ).
      RETURN.
    ENDIF.
    LOOP AT result-alternative_keys ASSIGNING FIELD-SYMBOL(<key>).
      cl_abap_unit_assert=>assert_true( <key>-is_own ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
