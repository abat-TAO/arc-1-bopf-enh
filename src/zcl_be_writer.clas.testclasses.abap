CLASS ltcl_enhancement_writer DEFINITION DEFERRED.
CLASS zcl_be_writer DEFINITION LOCAL FRIENDS ltcl_enhancement_writer.
CLASS ltcl_enhancement_writer DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION MEDIUM.
  PRIVATE SECTION.
    METHODS setup.
    METHODS missing_names_precede_lookup FOR TESTING RAISING cx_static_check.
    METHODS create_requires_base_object FOR TESTING RAISING cx_static_check.
    METHODS update_needs_no_name FOR TESTING RAISING cx_static_check.
    METHODS names_require_name FOR TESTING RAISING cx_static_check.
    METHODS names_reject_other_operations FOR TESTING RAISING cx_static_check.
    METHODS enhancement_names_need_no_base FOR TESTING RAISING cx_static_check.
    METHODS names_require_enhancement FOR TESTING RAISING cx_static_check.
    METHODS names_reject_invalid_context FOR TESTING RAISING cx_static_check.
    METHODS names_require_node FOR TESTING RAISING cx_static_check.
    METHODS names_require_action_reference FOR TESTING RAISING cx_static_check.
    METHODS node_names_include_ddic FOR TESTING RAISING cx_static_check.
    METHODS long_node_names_return_hint FOR TESTING RAISING cx_static_check.
    METHODS entity_names_include_class FOR TESTING RAISING cx_static_check.
    METHODS action_names_first_proposal FOR TESTING RAISING cx_static_check.
    METHODS enhancement_reports_interface FOR TESTING RAISING cx_static_check.
    METHODS default_interface_is_generated FOR TESTING RAISING cx_static_check.
    METHODS persistent_node_generated FOR TESTING RAISING cx_static_check.
    METHODS transient_node_generated FOR TESTING RAISING cx_static_check.
    METHODS default_node_names_generated FOR TESTING RAISING cx_static_check.
    METHODS entity_creates_report_class FOR TESTING RAISING cx_static_check.
    METHODS reused_class_is_not_generated FOR TESTING RAISING cx_static_check.
    METHODS existing_generates_nothing FOR TESTING RAISING cx_static_check.
    METHODS update_action_generates_class FOR TESTING RAISING cx_static_check.
    METHODS update_action_reuses_class FOR TESTING RAISING cx_static_check.
    METHODS reject_invalid_interface_names FOR TESTING RAISING cx_static_check.
    METHODS reject_invalid_combined_names FOR TESTING RAISING cx_static_check.
    METHODS accept_thirty_character_names FOR TESTING RAISING cx_static_check.
    METHODS reject_equal_combined_names FOR TESTING RAISING cx_static_check.
    METHODS reject_structure_table_name FOR TESTING RAISING cx_static_check.
    METHODS reject_table_type_table_name FOR TESTING RAISING cx_static_check.
    METHODS accept_transient_overrides FOR TESTING RAISING cx_static_check.
    METHODS enhancement_class_generated FOR TESTING RAISING cx_static_check.
    METHODS enhancement_class_reused FOR TESTING RAISING cx_static_check.
    METHODS update_action_keeps_class FOR TESTING RAISING cx_static_check.
    METHODS get_free_base_action RETURNING VALUE(result) TYPE string RAISING cx_static_check.
    METHODS expect_names_error IMPORTING
      request TYPE zcl_be_writer=>request
      status  TYPE i
      number  TYPE symsgno
      RAISING cx_static_check.
    METHODS require_unused_name IMPORTING name TYPE string.
    METHODS require_fixture RAISING cx_static_check.
    METHODS assert_error IMPORTING
      error  TYPE REF TO zcx_be_error
      status TYPE i
      number TYPE symsgno.
    DATA writer TYPE REF TO zcl_be_writer.
    DATA context TYPE zcl_be_change_context=>context.
    DATA root TYPE /bobf/s_conf_model_api_node.
    DATA note TYPE /bobf/s_conf_model_api_node.
    METHODS reject_truncated_proposal FOR TESTING RAISING cx_static_check.
    METHODS accept_requested_table FOR TESTING RAISING cx_static_check.
    METHODS reject_existing_database_table FOR TESTING RAISING cx_static_check.
    METHODS reject_standard_database_table FOR TESTING RAISING cx_static_check.
    METHODS reject_long_database_table FOR TESTING RAISING cx_static_check.
    METHODS ignore_transient_table FOR TESTING RAISING cx_static_check.
    METHODS reject_table_underscore FOR TESTING RAISING cx_static_check.
    METHODS accept_sixteen_char_table FOR TESTING RAISING cx_static_check.
    METHODS prepare_context RAISING cx_static_check.
    METHODS expect_write_error IMPORTING
      request TYPE zcl_be_writer=>request
      status  TYPE i
      number  TYPE symsgno
      RAISING cx_static_check.
    METHODS reject_unknown_operation FOR TESTING RAISING cx_static_check.
    METHODS reject_standard_new_name FOR TESTING RAISING cx_static_check.
    METHODS reject_unknown_base FOR TESTING RAISING cx_static_check.
    METHODS reject_unknown_entity FOR TESTING RAISING cx_static_check.
    METHODS reject_base_entity FOR TESTING RAISING cx_static_check.
    METHODS reject_unknown_node FOR TESTING RAISING cx_static_check.
    METHODS reject_action_cardinality FOR TESTING RAISING cx_static_check.
    METHODS accept_action_cardinalities FOR TESTING RAISING cx_static_check.
    METHODS reject_determination_pattern FOR TESTING RAISING cx_static_check.
    METHODS accept_determination_patterns FOR TESTING RAISING cx_static_check.
    METHODS reject_validation_impact FOR TESTING RAISING cx_static_check.
    METHODS accept_validation_impacts FOR TESTING RAISING cx_static_check.
    METHODS reject_key_uniqueness FOR TESTING RAISING cx_static_check.
    METHODS reject_key_check FOR TESTING RAISING cx_static_check.
    METHODS reject_nonunique_check FOR TESTING RAISING cx_static_check.
    METHODS accept_key_value_combinations FOR TESTING RAISING cx_static_check.
    METHODS dry_run_preserves_model FOR TESTING RAISING cx_static_check.
    METHODS default_triggers_use_own_node FOR TESTING RAISING cx_static_check.
    METHODS preserve_trigger_flags FOR TESTING RAISING cx_static_check.
    METHODS prefer_parent_association FOR TESTING RAISING cx_static_check.
    METHODS use_composition_association FOR TESTING RAISING cx_static_check.
    METHODS use_explicit_root_association FOR TESTING RAISING cx_static_check.
    METHODS reject_unknown_association FOR TESTING RAISING cx_static_check.
    METHODS write_nodes_include_own_node FOR TESTING RAISING cx_static_check.
    METHODS existing_dry_run_has_package FOR TESTING RAISING cx_static_check.
    METHODS fallback_to_root_association FOR TESTING RAISING cx_static_check.
    METHODS require_trigger_association FOR TESTING RAISING cx_static_check.
    METHODS allow_unrelated_write_node FOR TESTING RAISING cx_static_check.
    METHODS reject_write_node_association FOR TESTING RAISING cx_static_check.
    METHODS base_read_after_name_check FOR TESTING RAISING cx_static_check.
    METHODS accept_association_cards FOR TESTING RAISING cx_static_check.
    METHODS reject_association_cardinality FOR TESTING RAISING cx_static_check.
    METHODS accept_base_association_target FOR TESTING RAISING cx_static_check.
ENDCLASS.
CLASS ltcl_enhancement_writer IMPLEMENTATION.
  METHOD setup.
    " Fixture reads must start clean after earlier tests roll back during SAP name checks.
    /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( )->cleanup( ).
  ENDMETHOD.

  METHOD missing_names_precede_lookup.
    writer = NEW #( ).
    LOOP AT VALUE string_table( ( `` ) ( `createEnhancement` ) ( `createNode` ) ( `createAction` )
        ( `createActionEnhancement` ) ( `createDetermination` ) ( `createValidation` )
        ( `createActionValidation` ) ( `createQuery` ) ( `createAssociation` )
        ( `createAlternativeKey` ) ( `updateAction` ) ( `updateDetermination` )
        ( `updateValidation` ) ( `updateNode` ) ( `updateQuery` ) ( `unknown` ) )
        ASSIGNING FIELD-SYMBOL(<operation>).
      expect_write_error( request = VALUE #( operation = <operation> enhancement = 'ZBE_UNIT_DOES_NOT_EXIST'
        base_business_object = 'ZBE_UNIT_DOES_NOT_EXIST' node = 'UNKNOWN' )
        status                    = 400
        number                    = '004' ).
    ENDLOOP.
  ENDMETHOD.

  METHOD create_requires_base_object.
    writer = NEW #( ).
    expect_write_error( request = VALUE #( operation = 'createEnhancement' name = 'ZBE_UNIT' package = '$TMP' )
      status                    = 400
      number                    = '004' ).
  ENDMETHOD.

  METHOD update_needs_no_name.
    require_fixture( ).
    DATA(reader) = NEW zcl_be_reader( ).
    DATA(before) = reader->get_enhancement( 'ZBE_TEST_SO' ).
    DATA(result) = writer->write( VALUE #( operation = 'updateEnhancement' enhancement = 'ZBE_TEST_SO'
      description = 'Unit dry run only' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    cl_abap_unit_assert=>assert_equals( act = result-entity
                                        exp = 'ZBE_TEST_SO' ).
    cl_abap_unit_assert=>assert_initial( result-generated ).
    cl_abap_unit_assert=>assert_equals( act = reader->get_enhancement( 'ZBE_TEST_SO' )
                                        exp = before ).
  ENDMETHOD.

  METHOD names_require_name.
    writer = NEW #( ).
    LOOP AT VALUE string_table( ( `createEnhancement` ) ( `createNode` ) ( `createAction` )
        ( `createDetermination` ) ( `createValidation` ) ( `createAssociation` )
        ( `createActionEnhancement` ) ( `createActionValidation` ) ) ASSIGNING FIELD-SYMBOL(<operation>).
      expect_names_error( request = VALUE #( operation = <operation> enhancement = 'ZBE_UNIT_DOES_NOT_EXIST' )
        status                    = 400
        number                    = '004' ).
    ENDLOOP.
  ENDMETHOD.

  METHOD names_reject_other_operations.
    writer = NEW #( ).
    LOOP AT VALUE string_table( ( `` ) ( `updateEnhancement` ) ( `updateAction` ) ( `updateNode` )
        ( `updateDetermination` ) ( `updateValidation` ) ( `updateQuery` ) ( `createQuery` )
        ( `createAlternativeKey` ) ( `unknown` ) ) ASSIGNING FIELD-SYMBOL(<operation>).
      expect_names_error( request = VALUE #( operation = <operation> name = 'ZBE_UNIT' )
        status                    = 400
        number                    = '020' ).
    ENDLOOP.
  ENDMETHOD.

  METHOD enhancement_names_need_no_base.
    DATA(result) = NEW zcl_be_writer( )->get_names( VALUE #( operation = 'createEnhancement' name = 'zbe_unit' ) ).
    cl_abap_unit_assert=>assert_equals( act = result-operation
                                        exp = 'createEnhancement' ).
    cl_abap_unit_assert=>assert_equals( act = result-name
                                        exp = 'ZBE_UNIT' ).
    cl_abap_unit_assert=>assert_not_initial( result-constants_interface ).
    cl_abap_unit_assert=>assert_initial( result-class ).
    cl_abap_unit_assert=>assert_initial( result-combined_structure ).
    cl_abap_unit_assert=>assert_initial( result-parameter_structure ).
    cl_abap_unit_assert=>assert_initial( result-hints ).
  ENDMETHOD.

  METHOD names_require_enhancement.
    writer = NEW #( ).
    LOOP AT VALUE string_table( ( `createNode` ) ( `createAction` ) ( `createDetermination` )
        ( `createValidation` ) ( `createAssociation` ) ( `createActionEnhancement` )
        ( `createActionValidation` ) ) ASSIGNING FIELD-SYMBOL(<operation>).
      expect_names_error( request = VALUE #( operation = <operation> name = 'ZBE_TEST_UNIT' node = 'ROOT' )
        status                    = 400
        number                    = '004' ).
    ENDLOOP.
  ENDMETHOD.

  METHOD names_reject_invalid_context.
    writer = NEW #( ).
    expect_names_error( request = VALUE #( operation = 'createNode' name = 'ZBE_TEST_UNIT'
      enhancement = '/BOBF/EPM_SALES_ORDER' node = 'ROOT' )
      status                    = 404
      number                    = '002' ).
    expect_names_error( request = VALUE #( operation = 'createAction' name = 'ZBE_TEST_UNIT'
      enhancement = 'ZBE_UNIT_DOES_NOT_EXIST' node = 'ROOT' )
      status                    = 404
      number                    = '001' ).
  ENDMETHOD.

  METHOD names_require_node.
    require_fixture( ).
    LOOP AT VALUE string_table( ( `createNode` ) ( `createAction` ) ( `createDetermination` )
        ( `createValidation` ) ( `createAssociation` ) ) ASSIGNING FIELD-SYMBOL(<operation>).
      expect_names_error( request = VALUE #( operation = <operation> name = 'ZBE_TEST_UNIT' enhancement = 'ZBE_TEST_SO' )
        status                    = 400
        number                    = '004' ).
      expect_names_error( request = VALUE #( operation = <operation> name = 'ZBE_TEST_UNIT'
        enhancement = 'ZBE_TEST_SO' node = 'UNKNOWN' )
        status                    = 404
        number                    = '010' ).
    ENDLOOP.
  ENDMETHOD.

  METHOD names_require_action_reference.
    require_fixture( ).
    LOOP AT VALUE string_table( ( `createActionEnhancement` ) ( `createActionValidation` ) )
        ASSIGNING FIELD-SYMBOL(<operation>).
      expect_names_error( request = VALUE #( operation = <operation> name = 'ZBE_TEST_UNIT' enhancement = 'ZBE_TEST_SO' )
        status                    = 400
        number                    = '004' ).
      expect_names_error( request = VALUE #( operation = <operation> name = 'ZBE_TEST_UNIT'
        enhancement = 'ZBE_TEST_SO' base_action = 'UNKNOWN' action = 'UNKNOWN' )
        status                    = 404
        number                    = '012' ).
    ENDLOOP.
  ENDMETHOD.

  METHOD node_names_include_ddic.
    require_fixture( ).
    DATA(result) = writer->get_names( VALUE #( operation = 'createNode' enhancement = 'zbe_test_so'
      node = 'zbe_test_sub' name = 'zbe_test_unit_names' ) ).
    cl_abap_unit_assert=>assert_equals( act = result-name
                                        exp = 'ZBE_TEST_UNIT_NAMES' ).
    cl_abap_unit_assert=>assert_equals( act = result-operation
                                        exp = 'createNode' ).
    cl_abap_unit_assert=>assert_not_initial( result-data_structure ).
    cl_abap_unit_assert=>assert_not_initial( result-transient_structure ).
    cl_abap_unit_assert=>assert_not_initial( result-combined_structure ).
    cl_abap_unit_assert=>assert_not_initial( result-combined_table_type ).
    cl_abap_unit_assert=>assert_not_initial( result-database_table ).
    cl_abap_unit_assert=>assert_initial( result-class ).
    cl_abap_unit_assert=>assert_initial( result-constants_interface ).
  ENDMETHOD.

  METHOD long_node_names_return_hint.
    require_fixture( ).
    DATA(result) = writer->get_names( VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_HINT_LONG_NAME' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( strlen( result-database_table ) > 16
      OR result-database_table CP '*_' ) ).
    DATA(message) = NEW zcx_be_error( textid = VALUE #( msgid = 'ZBE_BOPF_ENH' msgno = '032'
      attr1 = 'IF_T100_DYN_MSG~MSGV1' ) ).
    message->if_t100_dyn_msg~msgv1 = result-database_table.
    DATA(expected) = message->get_text( ).
    cl_abap_unit_assert=>assert_equals( act = result-hints
                                        exp = VALUE string_table( ( expected ) ) ).
  ENDMETHOD.

  METHOD entity_names_include_class.
    DATA result TYPE zcl_be_writer=>names.
    require_fixture( ).
    DATA(reader) = NEW zcl_be_reader( ).
    DATA(before) = reader->get_enhancement( 'ZBE_TEST_SO' ).
    LOOP AT VALUE string_table( ( `createAction` ) ( `createDetermination` ) ( `createValidation` )
        ( `createAssociation` ) ( `createActionEnhancement` ) ( `createActionValidation` ) )
        ASSIGNING FIELD-SYMBOL(<operation>).
      result = writer->get_names( VALUE #( operation = <operation> enhancement = 'zbe_test_so'
        node = 'zbe_test_note' name = 'zbe_test_unit_names' base_action = 'confirm' action = 'confirm' ) ).
      cl_abap_unit_assert=>assert_not_initial( result-class ).
      cl_abap_unit_assert=>assert_equals( act = result-operation
                                          exp = <operation> ).
      cl_abap_unit_assert=>assert_equals( act = result-name
                                          exp = 'ZBE_TEST_UNIT_NAMES' ).
      IF <operation> = 'createAction'.
        cl_abap_unit_assert=>assert_not_initial( result-parameter_structure ).
      ELSE.
        cl_abap_unit_assert=>assert_initial( result-parameter_structure ).
      ENDIF.
      cl_abap_unit_assert=>assert_initial( result-combined_structure ).
      cl_abap_unit_assert=>assert_initial( result-hints ).
    ENDLOOP.
    cl_abap_unit_assert=>assert_equals( act = reader->get_enhancement( 'ZBE_TEST_SO' )
                                        exp = before ).
  ENDMETHOD.

  METHOD action_names_first_proposal.
    require_fixture( ).
    require_unused_name( 'ZCL_BE_A_UNIT_ONCE' ).
    require_unused_name( 'ZBE_S_A_UNIT_ONCE' ).
    " A dedicated name avoids counters from earlier proposals in this session.
    DATA(result) = NEW zcl_be_writer( )->get_names( VALUE #( operation = 'createAction'
      enhancement = 'ZBE_TEST_SO' node = 'ROOT' name = 'ZBE_UNIT_ONCE' ) ).
    cl_abap_unit_assert=>assert_not_initial( result-class ).
    cl_abap_unit_assert=>assert_equals( act = result-class
                                        exp = 'ZCL_BE_A_UNIT_ONCE' ).
    " SAP's first proposal uses the fixture prefix ZBE and removes it from the action name.
    cl_abap_unit_assert=>assert_equals( act = result-parameter_structure
                                        exp = 'ZBE_S_A_UNIT_ONCE' ).
  ENDMETHOD.

  METHOD enhancement_reports_interface.
    require_fixture( ).
    require_unused_name( 'ZBE_UNIT_NAMES_SO' ).
    require_unused_name( 'ZIF_BE_UNIT_NAMES' ).
    DATA(result) = writer->write( VALUE #( operation = 'createEnhancement' name = 'ZBE_UNIT_NAMES_SO'
      base_business_object = '/BOBF/EPM_SALES_ORDER' package = '$TMP'
      constants_interface = 'zif_be_unit_names' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    cl_abap_unit_assert=>assert_false( result-already_existed ).
    cl_abap_unit_assert=>assert_equals( act = result-class
                                        exp = 'ZIF_BE_UNIT_NAMES' ).
    cl_abap_unit_assert=>assert_equals( act = result-generated
                                        exp = VALUE zcl_be_writer=>generated_objects(
      ( type = `constantsInterface` name = `ZIF_BE_UNIT_NAMES` ) ) ).
  ENDMETHOD.

  METHOD default_interface_is_generated.
    require_fixture( ).
    require_unused_name( 'ZBE_UNIT_NAMES_SO' ).
    DATA(result) = writer->write( VALUE #( operation = 'createEnhancement' name = 'ZBE_UNIT_NAMES_SO'
      base_business_object = '/BOBF/EPM_SALES_ORDER' package = '$TMP' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_not_initial( result-class ).
    cl_abap_unit_assert=>assert_equals( act = result-generated
                                        exp = VALUE zcl_be_writer=>generated_objects(
      ( type = `constantsInterface` name = result-class ) ) ).
  ENDMETHOD.

  METHOD persistent_node_generated.
    require_fixture( ).
    require_unused_name( 'ZBE_S_UNIT_NAMES_C' ).
    require_unused_name( 'ZBE_T_UNIT_NAMES_C' ).
    require_unused_name( 'ZBE_D_UNIT_NAMES' ).
    DATA(result) = writer->write( VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_NAMES' is_transient = abap_false
      data_structure = CONV #( note-data_data_type ) database_table = 'ZBE_D_UNIT_NAMES'
      combined_structure = 'zbe_s_unit_names_c' combined_table_type = 'zbe_t_unit_names_c' dry_run = abap_true ) ).
    DATA(expected) = VALUE zcl_be_writer=>generated_objects(
      ( type = `combinedStructure` name = `ZBE_S_UNIT_NAMES_C` )
      ( type = `combinedTableType` name = `ZBE_T_UNIT_NAMES_C` ) ).
    INSERT VALUE #( type = `databaseTable` name = `ZBE_D_UNIT_NAMES` ) INTO TABLE expected.
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    cl_abap_unit_assert=>assert_false( result-already_existed ).
    cl_abap_unit_assert=>assert_equals( act = result-class
                                        exp = 'ZBE_S_UNIT_NAMES_C' ).
    cl_abap_unit_assert=>assert_equals( act = result-generated
                                        exp = expected ).
  ENDMETHOD.

  METHOD transient_node_generated.
    require_fixture( ).
    require_unused_name( 'ZBE_S_UNIT_NAMES_C' ).
    require_unused_name( 'ZBE_T_UNIT_NAMES_C' ).
    require_unused_name( 'ZBE_D_UNIT_NAMES' ).
    DATA(result) = writer->write( VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_NAMES' is_transient = abap_true
      data_structure = CONV #( note-data_data_type ) database_table = 'ZBE_D_UNIT_NAMES'
      combined_structure = 'zbe_s_unit_names_c' combined_table_type = 'zbe_t_unit_names_c' dry_run = abap_true ) ).
    DATA(expected) = VALUE zcl_be_writer=>generated_objects(
      ( type = `combinedStructure` name = `ZBE_S_UNIT_NAMES_C` )
      ( type = `combinedTableType` name = `ZBE_T_UNIT_NAMES_C` ) ).
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    cl_abap_unit_assert=>assert_false( result-already_existed ).
    cl_abap_unit_assert=>assert_equals( act = result-class
                                        exp = 'ZBE_S_UNIT_NAMES_C' ).
    cl_abap_unit_assert=>assert_equals( act = result-generated
                                        exp = expected ).
  ENDMETHOD.

  METHOD reject_equal_combined_names.
    require_fixture( ).
    require_unused_name( 'ZBE_UNIT_DDIC' ).
    TRY.
        writer->write( VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
          node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_NAMES' is_transient = abap_true
          combined_structure = 'ZBE_UNIT_DDIC' combined_table_type = 'ZBE_UNIT_DDIC' dry_run = abap_true ) ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 035' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error( error  = error
                      status = 422
                      number = '035' ).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_dyn_msg~msgv1
                                            exp = 'ZBE_UNIT_DDIC' ).
    ENDTRY.
  ENDMETHOD.

  METHOD reject_structure_table_name.
    require_fixture( ).
    require_unused_name( 'ZBE_UNIT_DDIC' ).
    require_unused_name( 'ZBE_T_UNIT_NAMES_C' ).
    TRY.
        writer->write( VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
          node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_NAMES' is_transient = abap_false
          data_structure = CONV #( note-data_data_type ) database_table = 'ZBE_UNIT_DDIC'
          combined_structure = 'ZBE_UNIT_DDIC' combined_table_type = 'ZBE_T_UNIT_NAMES_C' dry_run = abap_true ) ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 035' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error( error  = error
                      status = 422
                      number = '035' ).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_dyn_msg~msgv1
                                            exp = 'ZBE_UNIT_DDIC' ).
    ENDTRY.
  ENDMETHOD.

  METHOD reject_table_type_table_name.
    require_fixture( ).
    require_unused_name( 'ZBE_UNIT_DDIC' ).
    require_unused_name( 'ZBE_S_UNIT_NAMES_C' ).
    TRY.
        writer->write( VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
          node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_NAMES' is_transient = abap_false
          data_structure = CONV #( note-data_data_type ) database_table = 'ZBE_UNIT_DDIC'
          combined_structure = 'ZBE_S_UNIT_NAMES_C' combined_table_type = 'ZBE_UNIT_DDIC' dry_run = abap_true ) ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 035' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error( error  = error
                      status = 422
                      number = '035' ).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_dyn_msg~msgv1
                                            exp = 'ZBE_UNIT_DDIC' ).
    ENDTRY.
  ENDMETHOD.

  METHOD accept_transient_overrides.
    require_fixture( ).
    require_unused_name( 'ZBE_S_UNIT_NAMES_C' ).
    require_unused_name( 'ZBE_T_UNIT_NAMES_C' ).
    DATA(result) = writer->write( VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_NAMES' is_transient = abap_true
      combined_structure = 'ZBE_S_UNIT_NAMES_C' combined_table_type = 'ZBE_T_UNIT_NAMES_C' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    cl_abap_unit_assert=>assert_false( result-already_existed ).
    cl_abap_unit_assert=>assert_equals( act = result-generated
                                        exp = VALUE zcl_be_writer=>generated_objects(
      ( type = `combinedStructure` name = `ZBE_S_UNIT_NAMES_C` )
      ( type = `combinedTableType` name = `ZBE_T_UNIT_NAMES_C` ) ) ).
  ENDMETHOD.

  METHOD default_node_names_generated.
    require_fixture( ).
    DATA(result) = writer->write( VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_NAMES' is_transient = abap_true dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_not_initial( result-class ).
    cl_abap_unit_assert=>assert_equals( act = lines( result-generated )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( result-generated[
      type = 'combinedStructure' name = result-class ] ) ) ).
    cl_abap_unit_assert=>assert_not_initial( result-generated[ type = 'combinedTableType' ]-name ).
  ENDMETHOD.

  METHOD entity_creates_report_class.
    DATA result TYPE zcl_be_writer=>result.
    require_fixture( ).
    require_unused_name( 'ZCL_BE_UNIT_NAMES' ).
    " Resolve the enhancement association target before other operations run SAP name checks.
    LOOP AT VALUE string_table( ( `createAssociation` ) ( `createAction` ) ( `createDetermination` )
        ( `createValidation` ) ( `createActionValidation` ) )
        ASSIGNING FIELD-SYMBOL(<operation>).
      result = writer->write( VALUE #( operation = <operation> enhancement = 'ZBE_TEST_SO'
        node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_NAMES' base_action = 'CONFIRM' action = 'CONFIRM'
        timing = 'pre' class = 'ZCL_BE_UNIT_NAMES' target_business_object = 'ZBE_TEST_SO'
        target_node = 'ROOT' dry_run = abap_true ) ).
      cl_abap_unit_assert=>assert_true( result-dry_run ).
      cl_abap_unit_assert=>assert_false( result-already_existed ).
      cl_abap_unit_assert=>assert_equals( act = result-generated
                                          exp = VALUE zcl_be_writer=>generated_objects(
        ( type = `class` name = `ZCL_BE_UNIT_NAMES` ) ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD reused_class_is_not_generated.
    DATA result TYPE zcl_be_writer=>result.
    require_fixture( ).
    DATA(enhancement) = NEW zcl_be_reader( )->get_enhancement( 'ZBE_TEST_SO' ).
    DATA(class) = enhancement-actions[ name = 'ZBE_TEST_RELEASE' ]-class.
    cl_abap_unit_assert=>assert_not_initial( class ).
    " Resolve the enhancement association target before other operations run SAP name checks.
    LOOP AT VALUE string_table( ( `createAssociation` ) ( `createAction` ) ( `createDetermination` )
        ( `createValidation` ) ( `createActionValidation` ) )
        ASSIGNING FIELD-SYMBOL(<operation>).
      result = writer->write( VALUE #( operation = <operation> enhancement = 'ZBE_TEST_SO'
        node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_REUSE' base_action = 'CONFIRM' action = 'CONFIRM'
        timing = 'pre' class = class target_business_object = 'ZBE_TEST_SO'
        target_node = 'ROOT' dry_run = abap_true ) ).
      cl_abap_unit_assert=>assert_false( result-already_existed ).
      cl_abap_unit_assert=>assert_equals( act = result-class
                                          exp = class ).
      cl_abap_unit_assert=>assert_initial( result-generated ).
    ENDLOOP.
  ENDMETHOD.

  METHOD existing_generates_nothing.
    DATA result TYPE zcl_be_writer=>result.
    TYPES requests TYPE STANDARD TABLE OF zcl_be_writer=>request WITH EMPTY KEY.
    require_fixture( ).
    LOOP AT VALUE requests(
        ( operation = 'createEnhancement' name = 'ZBE_TEST_SO' base_business_object = '/BOBF/EPM_SALES_ORDER' )
        ( operation = 'createNode' node = 'ROOT' name = 'ZBE_TEST_NOTE' )
        ( operation = 'createNode' node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_SUB' )
        ( operation = 'createAction' node = 'ROOT' name = 'ZBE_TEST_RELEASE' )
        ( operation = 'createActionEnhancement' base_action = 'CONFIRM' timing = 'pre' name = 'ZBE_TEST_PRE_CONFIRM' )
        ( operation = 'createActionValidation' action = 'CONFIRM' name = 'ZBE_TEST_AVAL' )
        ( operation = 'createDetermination' node = 'ROOT' name = 'ZBE_TEST_DET' )
        ( operation = 'createValidation' node = 'ROOT' name = 'ZBE_TEST_VAL' )
        ( operation = 'createAssociation' node = 'ROOT' name = 'ZBE_TEST_TO_PRODUCT'
          target_business_object = '/BOBF/EPM_PRODUCT' target_node = 'ROOT' ) ) ASSIGNING FIELD-SYMBOL(<request>).
      result = writer->write( VALUE #( BASE <request> enhancement = 'ZBE_TEST_SO' dry_run = abap_true ) ).
      cl_abap_unit_assert=>assert_true( result-already_existed ).
      cl_abap_unit_assert=>assert_initial( result-generated ).
    ENDLOOP.
  ENDMETHOD.

  METHOD update_action_generates_class.
    require_fixture( ).
    require_unused_name( 'ZCL_BE_UNIT_NAMES' ).
    DATA(reader) = NEW zcl_be_reader( ).
    DATA(before) = reader->get_enhancement( 'ZBE_TEST_SO' ).
    DATA(result) = writer->write( VALUE #( operation = 'updateAction' enhancement = 'ZBE_TEST_SO'
      name = 'ZBE_TEST_RELEASE' class = 'ZCL_BE_UNIT_NAMES' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_false( result-unchanged ).
    cl_abap_unit_assert=>assert_equals( act = result-class
                                        exp = 'ZCL_BE_UNIT_NAMES' ).
    cl_abap_unit_assert=>assert_equals( act = result-generated
                                        exp = VALUE zcl_be_writer=>generated_objects(
      ( type = `class` name = `ZCL_BE_UNIT_NAMES` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = reader->get_enhancement( 'ZBE_TEST_SO' )
                                        exp = before ).
  ENDMETHOD.

  METHOD update_action_reuses_class.
    require_fixture( ).
    DATA(enhancement) = NEW zcl_be_reader( )->get_enhancement( 'ZBE_TEST_SO' ).
    DATA(class) = enhancement-actions[ name = 'ZBE_TEST_PRE_CONFIRM' ]-class.
    DATA(result) = writer->write( VALUE #( operation = 'updateAction' enhancement = 'ZBE_TEST_SO'
      name = 'ZBE_TEST_RELEASE' class = class dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_false( result-unchanged ).
    cl_abap_unit_assert=>assert_initial( result-generated ).
  ENDMETHOD.

  METHOD reject_invalid_interface_names.
    require_fixture( ).
    require_unused_name( 'ZBE_UNIT_NAMES_SO' ).
    LOOP AT VALUE string_table( ( `SAP_UNIT_NAMES` ) ( `ZBE_BAD-NAME` ) ( `ZBE_BAD NAME` )
        ( `Z123456789012345678901234567890` ) ( `ZCL_BE_WRITER` ) ) ASSIGNING FIELD-SYMBOL(<name>).
      expect_write_error( request = VALUE #( operation = 'createEnhancement' name = 'ZBE_UNIT_NAMES_SO'
        base_business_object = '/BOBF/EPM_SALES_ORDER' package = '$TMP' constants_interface = <name> )
        status                    = 422
        number                    = '034' ).
    ENDLOOP.
    DATA(enhancement) = NEW zcl_be_reader( )->get_enhancement( 'ZBE_TEST_SO' ).
    expect_write_error( request = VALUE #( operation = 'createEnhancement' name = 'ZBE_UNIT_NAMES_SO'
      base_business_object = '/BOBF/EPM_SALES_ORDER' package = '$TMP'
      constants_interface = enhancement-header-constants_interface )
      status                    = 422
      number                    = '034' ).
  ENDMETHOD.

  METHOD reject_invalid_combined_names.
    require_fixture( ).
    LOOP AT VALUE string_table( ( `SAP_UNIT_NAMES` ) ( `ZBE_BAD-NAME` ) ( `ZBE_BAD NAME` )
        ( `Z123456789012345678901234567890` ) ( `ZBE_S_TEST_NOTE_D` )
        ( `ZBE_T_TEST_PRIORITY` ) ( `ZBE_TEST_PRIORITY` ) ) ASSIGNING FIELD-SYMBOL(<name>).
      expect_write_error( request = VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
        node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_NAMES' is_transient = abap_true combined_structure = <name> )
        status                    = 422
        number                    = '034' ).
      expect_write_error( request = VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
        node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_NAMES' is_transient = abap_true combined_table_type = <name> )
        status                    = 422
        number                    = '034' ).
    ENDLOOP.
  ENDMETHOD.

  METHOD accept_thirty_character_names.
    require_fixture( ).
    require_unused_name( 'Z12345678901234567890123456789' ).
    require_unused_name( 'Y12345678901234567890123456789' ).
    require_unused_name( 'ZBE_UNIT_NAMES_SO' ).
    DATA(interface_result) = writer->write( VALUE #( operation = 'createEnhancement' name = 'ZBE_UNIT_NAMES_SO'
      base_business_object = '/BOBF/EPM_SALES_ORDER' package = '$TMP'
      constants_interface = 'Z12345678901234567890123456789' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_equals( act = interface_result-class
                                        exp = 'Z12345678901234567890123456789' ).
    DATA(node_result) = writer->write( VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_NAMES' is_transient = abap_true
      combined_structure = 'Z12345678901234567890123456789'
      combined_table_type = 'Y12345678901234567890123456789' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_equals( act = node_result-class
                                        exp = 'Z12345678901234567890123456789' ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( node_result-generated[
      type = 'combinedTableType' name = 'Y12345678901234567890123456789' ] ) ) ).
  ENDMETHOD.

  METHOD get_free_base_action.
    DATA(enhancement) = NEW zcl_be_reader( )->get_enhancement( name = 'ZBE_TEST_SO'
                                                               node = 'ROOT' ).
    LOOP AT enhancement-actions ASSIGNING FIELD-SYMBOL(<action>)
        WHERE category = 'standard' AND is_own = abap_false AND is_extensible = abap_true.
      IF NOT line_exists( enhancement-actions[ base_action = <action>-name category = 'pre' is_own = abap_true ] ).
        result = <action>-name.
        RETURN.
      ENDIF.
    ENDLOOP.
    " CONFIRM already has both enhancement slots occupied in the fixture.
    cl_abap_unit_assert=>skip( 'Test data missing: run ZCL_BE_TEST_FIXTURE first' ).
  ENDMETHOD.

  METHOD enhancement_class_generated.
    require_fixture( ).
    require_unused_name( 'ZCL_BE_UNIT_NAMES' ).
    DATA(base_action) = get_free_base_action( ).
    DATA(result) = writer->write( VALUE #( operation = 'createActionEnhancement' enhancement = 'ZBE_TEST_SO'
      name = 'ZBE_TEST_UNIT_NAMES' base_action = base_action timing = 'pre'
      class = 'ZCL_BE_UNIT_NAMES' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_false( result-already_existed ).
    cl_abap_unit_assert=>assert_equals( act = result-generated
                                        exp = VALUE zcl_be_writer=>generated_objects(
      ( type = `class` name = `ZCL_BE_UNIT_NAMES` ) ) ).
  ENDMETHOD.

  METHOD enhancement_class_reused.
    require_fixture( ).
    DATA(base_action) = get_free_base_action( ).
    DATA(enhancement) = NEW zcl_be_reader( )->get_enhancement( 'ZBE_TEST_SO' ).
    DATA(class) = enhancement-actions[ name = 'ZBE_TEST_PRE_CONFIRM' ]-class.
    DATA(result) = writer->write( VALUE #( operation = 'createActionEnhancement' enhancement = 'ZBE_TEST_SO'
      name = 'ZBE_TEST_UNIT_REUSE' base_action = base_action timing = 'pre' class = class dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_false( result-already_existed ).
    cl_abap_unit_assert=>assert_equals( act = result-class
                                        exp = class ).
    cl_abap_unit_assert=>assert_initial( result-generated ).
  ENDMETHOD.

  METHOD update_action_keeps_class.
    require_fixture( ).
    DATA(enhancement) = NEW zcl_be_reader( )->get_enhancement( 'ZBE_TEST_SO' ).
    DATA(class) = enhancement-actions[ name = 'ZBE_TEST_RELEASE' ]-class.
    DATA(result) = writer->write( VALUE #( operation = 'updateAction' enhancement = 'ZBE_TEST_SO'
      name = 'ZBE_TEST_RELEASE' class = class dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_true( result-unchanged ).
    cl_abap_unit_assert=>assert_initial( result-generated ).
  ENDMETHOD.

  METHOD expect_names_error.
    TRY.
        writer->get_names( request ).
        cl_abap_unit_assert=>fail( |Expected ZBE_BOPF_ENH { number }| ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error( error  = error
                      status = status
                      number = number ).
    ENDTRY.
  ENDMETHOD.

  METHOD require_unused_name.
    SELECT SINGLE @abap_true FROM tadir WHERE pgmid = 'R3TR' AND obj_name = @name INTO @DATA(exists).
    IF sy-subrc = 0 AND exists = abap_true.
      cl_abap_unit_assert=>skip( |Test name already exists: { name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD reject_truncated_proposal.
    require_fixture( ).
    " SAP proposes ZBE_D_TRUNCATES_ with a trailing underscore; this node name is unique to this test.
    " Do not request a separate proposal first: SAP may reserve it and add a numeric suffix on the next call.
    expect_write_error(
      request = VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TRUNCATES_SUB' data_structure = CONV #( note-data_data_type )
      )
      status  = 422
      number  = '032' ).
  ENDMETHOD.

  METHOD reject_existing_database_table.
    require_fixture( ).
    " Depends on the existing database table of the read-only fixture node.
    SELECT SINGLE @abap_true FROM dd02l WHERE tabname = 'ZBE_D_TNOTE' INTO @DATA(exists).
    cl_abap_unit_assert=>assert_true( exists ).
    expect_write_error(
      request = VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_NOTE_SUB' data_structure = CONV #( note-data_data_type )
      database_table = 'ZBE_D_TNOTE' )
      status  = 422
      number  = '032' ).
  ENDMETHOD.

  METHOD reject_standard_database_table.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_NOTE_SUB' data_structure = CONV #( note-data_data_type )
      database_table = 'SAP_UNIT_SUB' )
      status  = 422
      number  = '032' ).
  ENDMETHOD.

  METHOD reject_long_database_table.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_NOTE_SUB' data_structure = CONV #( note-data_data_type )
      database_table = 'ZBE_D_UNIT_SUB1234' )
      status  = 422
      number  = '032' ).
  ENDMETHOD.

  METHOD reject_table_underscore.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_NOTE_SUB' data_structure = CONV #( note-data_data_type )
      database_table = 'ZBE_D_UNIT_SUB_' )
      status  = 422
      number  = '032' ).
  ENDMETHOD.

  METHOD accept_requested_table.
    require_fixture( ).
    " Depends on the read-only fixture structure and a database table name that is not in DD02L.
    SELECT SINGLE @abap_true FROM dd02l WHERE tabname = 'ZBE_D_UNIT_SUB' INTO @DATA(exists).
    cl_abap_unit_assert=>assert_initial( exists ).
    DATA(result) = writer->write( VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_NOTE_SUB' data_structure = CONV #( note-data_data_type )
      database_table = 'ZBE_D_UNIT_SUB' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    cl_abap_unit_assert=>assert_false( result-already_existed ).
  ENDMETHOD.

  METHOD accept_sixteen_char_table.
    require_fixture( ).
    " Depends on the read-only fixture structure and a database table name that is not in DD02L.
    SELECT SINGLE @abap_true FROM dd02l WHERE tabname = 'ZBE_D_UNIT_SUB12' INTO @DATA(exists).
    cl_abap_unit_assert=>assert_initial( exists ).
    DATA(result) = writer->write( VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_NOTE_SUB' data_structure = CONV #( note-data_data_type )
      database_table = 'ZBE_D_UNIT_SUB12' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    cl_abap_unit_assert=>assert_false( result-already_existed ).
  ENDMETHOD.

  METHOD ignore_transient_table.
    DATA result TYPE zcl_be_writer=>result.
    require_fixture( ).
    " Invalid and existing table names are irrelevant for transient nodes without a database table.
    LOOP AT VALUE string_table( ( `` ) ( `ZBE_D_TNOTE` ) ( `SAP_UNIT_SUB` )
        ( `ZBE_D_UNIT_SUB1234` ) ( `ZBE_D_UNIT_SUB_` ) ) ASSIGNING FIELD-SYMBOL(<table>).
      result = writer->write( VALUE #( operation = 'createNode' enhancement = 'ZBE_TEST_SO'
        node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_NOTE_SUB' is_transient = abap_true
        database_table = <table> dry_run = abap_true ) ).
      cl_abap_unit_assert=>assert_true( result-dry_run ).
      cl_abap_unit_assert=>assert_false( result-already_existed ).
    ENDLOOP.
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
    prepare_context( ).
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

  METHOD prepare_context.
    " Depends on the read-only fixture ZBE_TEST_SO with ROOT and ZBE_TEST_NOTE.
    writer = NEW #( ).
    context-enhancement = NEW zcl_be_change_context( )->find_business_object( 'ZBE_TEST_SO' ).
    root = writer->find_node(
      context = context
      name    = 'ROOT' ).
    note = writer->find_node(
      context = context
      name    = 'ZBE_TEST_NOTE' ).
  ENDMETHOD.

  METHOD expect_write_error.
    " All writer requests, including negative cases, are forced to remain dry runs.
    DATA(dry_request) = request.
    dry_request-dry_run = abap_true.
    TRY.
        writer->write( dry_request ).
        cl_abap_unit_assert=>fail( |Expected ZBE_BOPF_ENH { number }| ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = status
          number = number ).
    ENDTRY.
  ENDMETHOD.

  METHOD reject_unknown_operation.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( enhancement = 'ZBE_TEST_SO' node = 'ZBE_TEST_NOTE'
      name = 'ZBE_TEST_UNIT' operation = 'unknown' )
      status  = 400
      number  = '007' ).
  ENDMETHOD.

  METHOD reject_standard_new_name.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( operation = 'createEnhancement' name = 'SAP_UNIT'
      base_business_object = '/BOBF/EPM_SALES_ORDER' package = '$TMP' )
      status  = 422
      number  = '008' ).
  ENDMETHOD.

  METHOD reject_unknown_base.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( operation = 'createEnhancement' name = 'ZBE_UNIT'
      base_business_object = 'ZBE_UNIT_DOES_NOT_EXIST' package = '$TMP' )
      status  = 404
      number  = '001' ).
  ENDMETHOD.

  METHOD reject_unknown_entity.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( enhancement = 'ZBE_TEST_SO' node = 'ZBE_TEST_NOTE'
      name = 'ZBE_TEST_UNIT' operation = 'updateNode' description = 'Unit note' )
      status  = 404
      number  = '025' ).
  ENDMETHOD.

  METHOD reject_base_entity.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( operation = 'updateNode' enhancement = 'ZBE_TEST_SO'
      name = 'ROOT' description = 'Unit root' )
      status  = 422
      number  = '026' ).
  ENDMETHOD.

  METHOD reject_unknown_node.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( enhancement = 'ZBE_TEST_SO'
      name = 'ZBE_TEST_UNIT' operation = 'createAction' node = 'ZBE_UNIT_UNKNOWN' )
      status  = 404
      number  = '010' ).
  ENDMETHOD.

  METHOD reject_action_cardinality.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( enhancement = 'ZBE_TEST_SO' node = 'ZBE_TEST_NOTE'
      name = 'ZBE_TEST_UNIT' operation = 'createAction' cardinality = 'zeroToOne' )
      status  = 400
      number  = '020' ).
  ENDMETHOD.

  METHOD accept_action_cardinalities.
    DATA result TYPE zcl_be_writer=>result.
    require_fixture( ).
    LOOP AT VALUE string_table( ( `` ) ( `many` ) ( `one` ) ( `static` ) ) ASSIGNING FIELD-SYMBOL(<cardinality>).
      result = writer->write( VALUE #( operation = 'createAction' enhancement = 'ZBE_TEST_SO'
        node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_ACT' cardinality = <cardinality> dry_run = abap_true ) ).
      cl_abap_unit_assert=>assert_true( result-dry_run ).
      cl_abap_unit_assert=>assert_false( result-already_existed ).
    ENDLOOP.
  ENDMETHOD.

  METHOD reject_determination_pattern.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( enhancement = 'ZBE_TEST_SO' node = 'ZBE_TEST_NOTE'
      name = 'ZBE_TEST_UNIT' operation = 'createDetermination' pattern = 'invalid' )
      status  = 400
      number  = '020' ).
  ENDMETHOD.

  METHOD accept_determination_patterns.
    DATA result TYPE zcl_be_writer=>result.
    require_fixture( ).
    LOOP AT VALUE string_table( ( `` ) ( `afterModify` ) ( `beforeSave` ) ) ASSIGNING FIELD-SYMBOL(<pattern>).
      result = writer->write( VALUE #( operation = 'createDetermination' enhancement = 'ZBE_TEST_SO'
        node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_DET' pattern = <pattern> dry_run = abap_true ) ).
      cl_abap_unit_assert=>assert_true( result-dry_run ).
      cl_abap_unit_assert=>assert_false( result-already_existed ).
    ENDLOOP.
  ENDMETHOD.

  METHOD reject_validation_impact.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( enhancement = 'ZBE_TEST_SO' node = 'ZBE_TEST_NOTE'
      name = 'ZBE_TEST_UNIT' operation = 'createValidation' impact = 'invalid' )
      status  = 400
      number  = '020' ).
  ENDMETHOD.

  METHOD accept_validation_impacts.
    DATA result TYPE zcl_be_writer=>result.
    require_fixture( ).
    LOOP AT VALUE string_table( ( `` ) ( `messages` ) ( `preventSave` ) ) ASSIGNING FIELD-SYMBOL(<impact>).
      result = writer->write( VALUE #( operation = 'createValidation' enhancement = 'ZBE_TEST_SO'
        node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_VAL' impact = <impact> dry_run = abap_true ) ).
      cl_abap_unit_assert=>assert_true( result-dry_run ).
      cl_abap_unit_assert=>assert_false( result-already_existed ).
    ENDLOOP.
  ENDMETHOD.

  METHOD reject_key_uniqueness.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( enhancement = 'ZBE_TEST_SO' node = 'ZBE_TEST_NOTE'
      name = 'ZBE_TEST_UNIT' operation = 'createAlternativeKey' uniqueness = 'invalid' )
      status  = 400
      number  = '020' ).
  ENDMETHOD.

  METHOD reject_key_check.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( enhancement = 'ZBE_TEST_SO' node = 'ZBE_TEST_NOTE'
      name = 'ZBE_TEST_UNIT' operation = 'createAlternativeKey' uniqueness = 'unique' uniqueness_check = 'invalid' )
      status  = 400
      number  = '020' ).
  ENDMETHOD.

  METHOD reject_nonunique_check.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( enhancement = 'ZBE_TEST_SO' node = 'ZBE_TEST_NOTE'
      name = 'ZBE_TEST_UNIT' operation = 'createAlternativeKey' uniqueness = 'notUnique' uniqueness_check = 'beforeSave' )
      status  = 400
      number  = '020' ).
  ENDMETHOD.

  METHOD accept_key_value_combinations.
    DATA result TYPE zcl_be_writer=>result.
    require_fixture( ).
    " Reuses only DDIC references and fields of the existing read-only fixture key.
    DATA(enhancement) = NEW zcl_be_reader( )->get_enhancement( 'ZBE_TEST_SO' ).
    cl_abap_unit_assert=>assert_not_initial( enhancement-alternative_keys ).
    DATA(key) = enhancement-alternative_keys[ 1 ].
    LOOP AT VALUE string_table( ( `notUnique` ) ( `unique` ) ( `uniqueIfNotInitial` ) ) ASSIGNING FIELD-SYMBOL(<uniqueness>).
      LOOP AT VALUE string_table( ( `` ) ( `none` ) ( `beforeSave` ) ( `afterModify` ) ) ASSIGNING FIELD-SYMBOL(<check>).
        IF <uniqueness> = 'notUnique' AND <check> IS NOT INITIAL AND <check> <> 'none'.
          CONTINUE.
        ENDIF.
        result = writer->write( VALUE #( operation = 'createAlternativeKey' enhancement = 'ZBE_TEST_SO'
          node = key-node name = 'ZBE_TEST_UNIT_KEY' fields = key-fields data_type = key-data_type
          table_type = key-table_type uniqueness = <uniqueness> uniqueness_check = <check> dry_run = abap_true ) ).
        cl_abap_unit_assert=>assert_true( result-dry_run ).
        cl_abap_unit_assert=>assert_false( result-already_existed ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD dry_run_preserves_model.
    require_fixture( ).
    DATA(reader) = NEW zcl_be_reader( ).
    DATA(before) = reader->get_enhancement( 'ZBE_TEST_SO' ).
    DATA(result) = writer->write( VALUE #( operation = 'updateNode' enhancement = 'zbe_test_so'
      name = 'zbe_test_note' description = 'Unit dry run only' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    cl_abap_unit_assert=>assert_equals(
      act = result-enhancement
      exp = 'ZBE_TEST_SO' ).
    cl_abap_unit_assert=>assert_equals(
      act = result-package
      exp = '$TMP' ).
    cl_abap_unit_assert=>assert_equals(
      act = reader->get_enhancement( 'ZBE_TEST_SO' )
      exp = before ).
  ENDMETHOD.

  METHOD default_triggers_use_own_node.
    require_fixture( ).
    DATA(triggers) = writer->get_request_nodes(
      request = VALUE #( dry_run = abap_true )
      context = context
      node    = note ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( triggers )
      exp = 1 ).
    DATA(trigger) = triggers[ 1 ].
    cl_abap_unit_assert=>assert_equals(
      act = trigger-request_node_key
      exp = note-node_key ).
    cl_abap_unit_assert=>assert_true( trigger-trigger_create ).
    cl_abap_unit_assert=>assert_true( trigger-trigger_update ).
    cl_abap_unit_assert=>assert_false( trigger-trigger_delete ).
    cl_abap_unit_assert=>assert_initial( trigger-assoc_key ).
  ENDMETHOD.

  METHOD preserve_trigger_flags.
    require_fixture( ).
    DATA(triggers) = writer->get_request_nodes(
      request = VALUE #( dry_run = abap_true
      triggers                   = VALUE #( ( on_delete = abap_true ) ) )
      context = context
      node    = note ).
    DATA(trigger) = triggers[ 1 ].
    cl_abap_unit_assert=>assert_equals(
      act = trigger-request_node_key
      exp = note-node_key ).
    cl_abap_unit_assert=>assert_false( trigger-trigger_create ).
    cl_abap_unit_assert=>assert_false( trigger-trigger_update ).
    cl_abap_unit_assert=>assert_true( trigger-trigger_delete ).
  ENDMETHOD.

  METHOD prefer_parent_association.
    require_fixture( ).
    /bobf/cl_conf_model_api=>get_association_tab( EXPORTING iv_bo_key = context-enhancement-bo_key
      IMPORTING et_association                                        = DATA(associations) ).
    DATA(parent) = associations[ source_node_key = note-node_key target_node_key = root-node_key assoc_type = 'A' assoc_cat = 'P' ].
    DATA(triggers) = writer->get_request_nodes(
      request = VALUE #( dry_run = abap_true
      triggers                   = VALUE #( ( node = 'ZBE_TEST_NOTE' on_update = abap_true ) ) )
      context = context
      node    = root ).
    cl_abap_unit_assert=>assert_equals(
      act = triggers[ 1 ]-assoc_key
      exp = parent-assoc_key ).
  ENDMETHOD.

  METHOD use_composition_association.
    require_fixture( ).
    /bobf/cl_conf_model_api=>get_association_tab( EXPORTING iv_bo_key = context-enhancement-bo_key
      IMPORTING et_association                                        = DATA(associations) ).
    DATA(composition) = associations[ source_node_key = root-node_key target_node_key = note-node_key assoc_type = 'C' assoc_cat = 'N' ].
    DATA(triggers) = writer->get_request_nodes(
      request = VALUE #( dry_run = abap_true
      triggers                   = VALUE #( ( node = 'ROOT' on_create = abap_true ) ) )
      context = context
      node    = note ).
    cl_abap_unit_assert=>assert_equals(
      act = triggers[ 1 ]-assoc_key
      exp = composition-assoc_key ).
  ENDMETHOD.

  METHOD use_explicit_root_association.
    require_fixture( ).
    /bobf/cl_conf_model_api=>get_association_tab( EXPORTING iv_bo_key = context-enhancement-bo_key
      IMPORTING et_association                                        = DATA(associations) ).
    DATA(to_root) = associations[ source_node_key = note-node_key target_node_key = root-node_key assoc_type = 'A' assoc_cat = 'R' ].
    DATA(triggers) = writer->get_request_nodes(
      request = VALUE #( dry_run = abap_true
      triggers                   = VALUE #( ( node = 'ZBE_TEST_NOTE' association = CONV #( to_root-assoc_name ) on_update = abap_true ) ) )
      context = context
      node    = root ).
    cl_abap_unit_assert=>assert_equals(
      act = triggers[ 1 ]-assoc_key
      exp = to_root-assoc_key ).
  ENDMETHOD.

  METHOD reject_unknown_association.
    require_fixture( ).
    TRY.
        writer->get_request_nodes(
          request = VALUE #( dry_run = abap_true triggers = VALUE #( ( node = 'ROOT' association = 'ZBE_UNKNOWN' ) ) )
          context = context
          node    = note ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 031' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 422
          number = '031' ).
    ENDTRY.
  ENDMETHOD.

  METHOD write_nodes_include_own_node.
    require_fixture( ).
    DATA(nodes) = writer->get_write_nodes(
      request = VALUE #( dry_run = abap_true
      write_nodes                = VALUE #( ( node = 'ZBE_TEST_NOTE' ) ( node = 'ROOT' ) ) )
      context = context
      node    = note ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( nodes )
      exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = nodes[ 1 ]-write_node_key
      exp = note-node_key ).
    cl_abap_unit_assert=>assert_initial( nodes[ 1 ]-assoc_key ).
    cl_abap_unit_assert=>assert_not_initial( nodes[ 2 ]-assoc_key ).
  ENDMETHOD.

  METHOD existing_dry_run_has_package.
    require_fixture( ).
    " Regression: existing enhancements must report their actual package for deployment policy.
    DATA(result) = writer->write( VALUE #( operation = 'createEnhancement' name = 'ZBE_TEST_SO'
      base_business_object = '/BOBF/EPM_SALES_ORDER' package = '$TMP' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_true( result-already_existed ).
    cl_abap_unit_assert=>assert_equals(
      act = result-package
      exp = '$TMP'
      msg = 'Existing enhancement dry run must report its actual package' ).
  ENDMETHOD.

  METHOD fallback_to_root_association.
    require_fixture( ).
    " Depends on the read-only fixture grandchild ZBE_TEST_SUB below ZBE_TEST_NOTE.
    DATA(source) = writer->find_node(
      context = context
      name    = 'ZBE_TEST_SUB' ).
    cl_abap_unit_assert=>assert_equals(
      act = source-parent_node_key
      exp = note-node_key ).
    /bobf/cl_conf_model_api=>get_association_tab( EXPORTING iv_bo_key = context-enhancement-bo_key
      IMPORTING et_association                                        = DATA(associations) ).
    DATA(to_root) = associations[ source_node_key = source-node_key target_node_key = root-node_key
      assoc_type = 'A' assoc_cat = 'R' ].
    DATA(key) = writer->find_association(
      context     = context
      source      = source
      target      = root
      requested   = ''
      is_required = abap_true
      property    = 'triggers' ).
    cl_abap_unit_assert=>assert_equals(
      act = key
      exp = to_root-assoc_key ).
  ENDMETHOD.

  METHOD require_trigger_association.
    require_fixture( ).
    DATA(item) = writer->find_node(
      context = context
      name    = 'ITEM' ).
    TRY.
        writer->find_association(
          context     = context
          source      = item
          target      = note
          requested   = ''
          is_required = abap_true
          property    = 'triggers' ).
        cl_abap_unit_assert=>fail( 'Unrelated trigger nodes need an association' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 422
          number = '031' ).
    ENDTRY.
  ENDMETHOD.

  METHOD allow_unrelated_write_node.
    require_fixture( ).
    DATA(item) = writer->find_node(
      context = context
      name    = 'ITEM' ).
    DATA(key) = writer->find_association(
      context     = context
      source      = item
      target      = note
      requested   = ''
      is_required = abap_false
      property    = 'writeNodes' ).
    cl_abap_unit_assert=>assert_initial( key ).
  ENDMETHOD.

  METHOD reject_write_node_association.
    require_fixture( ).
    TRY.
        writer->get_write_nodes(
          request = VALUE #( dry_run = abap_true
          write_nodes                = VALUE #( ( node = 'ROOT' association = 'ZBE_UNKNOWN' ) ) )
          context = context
          node    = note ).
        cl_abap_unit_assert=>fail( 'Unknown requested write association must be rejected' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 422
          number = '031' ).
    ENDTRY.
  ENDMETHOD.

  METHOD accept_association_cards.
    DATA result TYPE zcl_be_writer=>result.
    require_fixture( ).
    LOOP AT VALUE string_table( ( `` ) ( `many` ) ( `one` ) ( `zeroToOne` ) ( `oneToMany` ) ) ASSIGNING FIELD-SYMBOL(<cardinality>).
      result = writer->write( VALUE #( operation = 'createAssociation' enhancement = 'ZBE_TEST_SO'
        node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_ASSOC' target_business_object = 'ZBE_TEST_SO'
        target_node = 'ROOT' cardinality = <cardinality> dry_run = abap_true ) ).
      cl_abap_unit_assert=>assert_true( result-dry_run ).
      cl_abap_unit_assert=>assert_false( result-already_existed ).
    ENDLOOP.
  ENDMETHOD.

  METHOD reject_association_cardinality.
    require_fixture( ).
    expect_write_error(
      request = VALUE #( operation = 'createAssociation' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_ASSOC' target_business_object = 'ZBE_TEST_SO'
      target_node = 'ROOT' cardinality = 'static' )
      status  = 400
      number  = '020' ).
  ENDMETHOD.

  METHOD accept_base_association_target.
    require_fixture( ).
    DATA(result) = writer->write( VALUE #( operation = 'createAssociation' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_ASSOC' target_business_object = '/BOBF/EPM_SALES_ORDER'
      target_node = 'ROOT' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    cl_abap_unit_assert=>assert_not_initial( result-class ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists(
      result-generated[ type = `class` name = result-class ] ) ) ).
  ENDMETHOD.

  METHOD base_read_after_name_check.
    require_fixture( ).
    " Depends on the read-only fixture; dry runs finish with SAP proposal cleanup.
    DATA(base) = NEW zcl_be_change_context( )->find_business_object( '/BOBF/EPM_SALES_ORDER' ).
    cl_abap_unit_assert=>assert_equals(
      act = base-bo_key
      exp = context-enhancement-super_bo_key ).
    DATA(result) = writer->write( VALUE #( operation = 'createAction' enhancement = 'ZBE_TEST_SO'
      node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_ACT' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key = base-bo_key
      IMPORTING et_node_tab = DATA(nodes) ev_success = DATA(success) ).
    " SAP name checks clear other BO reads until proposal cleanup within the same operation.
    " Association targets must therefore be read before the name check.
    cl_abap_unit_assert=>assert_true( success ).
    cl_abap_unit_assert=>assert_equals( act = lines( nodes )
                                        exp = 5 ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( nodes[ node_name = 'ROOT' ] ) ) ).
  ENDMETHOD.
ENDCLASS.
CLASS ltcl_base_read DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS setup.
    METHODS require_fixture RAISING cx_static_check.
    METHODS compare_cold_and_warm_reads FOR TESTING RAISING cx_static_check.
    METHODS dry_run_restores_base_reads FOR TESTING RAISING cx_static_check.
ENDCLASS.
CLASS ltcl_base_read IMPLEMENTATION.
  METHOD setup.
    " Fixture reads must start clean after earlier tests roll back during SAP name checks.
    /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( )->cleanup( ).
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

  METHOD compare_cold_and_warm_reads.
    require_fixture( ).
    " Depends on the read-only base BO and ZBE_TEST_SO; simple enhancement reads must preserve base nodes.
    DATA(rules) = NEW zcl_be_change_context( ).
    DATA(base) = rules->find_business_object( '/BOBF/EPM_SALES_ORDER' ).
    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key = base-bo_key
      IMPORTING et_node_tab = DATA(cold_nodes) ev_success = DATA(cold_success) ).
    cl_abap_unit_assert=>assert_true( cold_success ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( cold_nodes[ node_name = 'ROOT' ] ) ) ).
    DATA(enhancement) = rules->find_business_object( 'ZBE_TEST_SO' ).
    cl_abap_unit_assert=>assert_equals(
      act = base-bo_key
      exp = enhancement-super_bo_key ).
    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key = enhancement-bo_key
      IMPORTING et_node_tab                                    = DATA(enhancement_nodes) ).
    cl_abap_unit_assert=>assert_not_initial( enhancement_nodes ).
    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key = base-bo_key
      IMPORTING et_node_tab = DATA(warm_nodes) ev_success = DATA(warm_success) ).
    cl_abap_unit_assert=>assert_true( warm_success ).
    cl_abap_unit_assert=>assert_equals(
      act = warm_nodes
      exp = cold_nodes ).
  ENDMETHOD.

  METHOD dry_run_restores_base_reads.
    require_fixture( ).
    " Depends on the read-only fixture; the action is validated only and is never saved.
    DATA(base) = NEW zcl_be_change_context( )->find_business_object( '/BOBF/EPM_SALES_ORDER' ).
    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key = base-bo_key
      IMPORTING et_node_tab = DATA(before_nodes) ev_success = DATA(before_success) ).
    cl_abap_unit_assert=>assert_true( before_success ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( before_nodes[ node_name = 'ROOT' ] ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( before_nodes[ node_name = 'ITEM' ] ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( before_nodes[ node_name = 'NOTE' ] ) ) ).
    DATA(result) = NEW zcl_be_writer( )->write( VALUE #( operation = 'createAction'
      enhancement = 'ZBE_TEST_SO' node = 'ZBE_TEST_NOTE' name = 'ZBE_TEST_UNIT_ACT' dry_run = abap_true ) ).
    cl_abap_unit_assert=>assert_true( result-dry_run ).
    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key = base-bo_key
      IMPORTING et_node_tab = DATA(after_nodes) ev_success = DATA(after_success) ).
    cl_abap_unit_assert=>assert_true( after_success ).
    " CHECK_ACTION_NAME clears other BO reads until the dry run reaches SAP proposal cleanup.
    " The next writer operation also starts with cleanup, so completed requests allow base reads again.
    cl_abap_unit_assert=>assert_equals( act = lines( after_nodes )
                                        exp = 5 ).
    cl_abap_unit_assert=>assert_equals( act = after_nodes
                                        exp = before_nodes ).
  ENDMETHOD.
ENDCLASS.
