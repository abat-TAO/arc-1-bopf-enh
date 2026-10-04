CLASS ltcl_enhancement_deleter DEFINITION DEFERRED.
CLASS zcl_be_deleter DEFINITION LOCAL FRIENDS ltcl_enhancement_deleter.
CLASS ltcl_enhancement_deleter DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS require_fixture RAISING cx_static_check.
    METHODS assert_error IMPORTING
      error  TYPE REF TO zcx_be_error
      status TYPE i
      number TYPE symsgno.
    DATA deleter TYPE REF TO zcl_be_deleter.
    METHODS setup.
    METHODS reject_unknown_enhancement FOR TESTING RAISING cx_static_check.
    METHODS reject_unknown_entity FOR TESTING RAISING cx_static_check.
    METHODS reject_base_entity FOR TESTING RAISING cx_static_check.
    METHODS reject_unknown_entity_type FOR TESTING RAISING cx_static_check.
    METHODS same_state_has_same_token FOR TESTING RAISING cx_static_check.
    METHODS different_entity_changes_token FOR TESTING RAISING cx_static_check.
    METHODS preview_cascades_own_entities FOR TESTING RAISING cx_static_check.
    METHODS preview_uses_fixed_order FOR TESTING RAISING cx_static_check.
    METHODS reject_wrong_enhancement_name FOR TESTING RAISING cx_static_check.
    METHODS cascade_subnodes_in_memory FOR TESTING RAISING cx_static_check.
    METHODS cascade_action_validations FOR TESTING RAISING cx_static_check.
ENDCLASS.
CLASS ltcl_enhancement_deleter IMPLEMENTATION.
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

  METHOD setup.
    " Preview cases depend on the read-only fixture ZBE_TEST_SO and delete authorization.
    deleter = NEW #( ).
  ENDMETHOD.

  METHOD reject_unknown_enhancement.
    TRY.
        deleter->get_preview(
          enhancement = 'ZBE_UNIT_DOES_NOT_EXIST'
          entity_type = 'node'
          name        = 'ZBE_TEST_NOTE' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 001' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 404
          number = '001' ).
    ENDTRY.
  ENDMETHOD.

  METHOD reject_unknown_entity.
    require_fixture( ).
    TRY.
        deleter->get_preview(
          enhancement = 'ZBE_TEST_SO'
          entity_type = 'node'
          name        = 'ZBE_UNIT_UNKNOWN' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 025' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 404
          number = '025' ).
    ENDTRY.
  ENDMETHOD.

  METHOD reject_base_entity.
    require_fixture( ).
    TRY.
        deleter->get_preview(
          enhancement = 'ZBE_TEST_SO'
          entity_type = 'node'
          name        = 'ROOT' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 026' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 422
          number = '026' ).
    ENDTRY.
  ENDMETHOD.

  METHOD reject_unknown_entity_type.
    require_fixture( ).
    TRY.
        deleter->get_preview(
          enhancement = 'ZBE_TEST_SO'
          entity_type = 'invalid'
          name        = 'ZBE_TEST_NOTE' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 020' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 400
          number = '020' ).
    ENDTRY.
  ENDMETHOD.

  METHOD same_state_has_same_token.
    require_fixture( ).
    DATA(first) = deleter->get_preview(
      enhancement = 'ZBE_TEST_SO'
      entity_type = 'node'
      name        = 'ZBE_TEST_NOTE' ).
    DATA(second) = NEW zcl_be_deleter( )->get_preview(
      enhancement = 'zbe_test_so'
      entity_type = 'node'
      name        = 'zbe_test_note' ).
    cl_abap_unit_assert=>assert_equals(
      act = first-token
      exp = second-token ).
    cl_abap_unit_assert=>assert_equals(
      act = strlen( first-token )
      exp = 64 ).
    cl_abap_unit_assert=>assert_false( xsdbool( first-token CN '0123456789abcdef' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = first-package
      exp = '$TMP' ).
    cl_abap_unit_assert=>assert_initial( first-transport ).
  ENDMETHOD.

  METHOD different_entity_changes_token.
    require_fixture( ).
    DATA(node) = deleter->get_preview(
      enhancement = 'ZBE_TEST_SO'
      entity_type = 'node'
      name        = 'ZBE_TEST_NOTE' ).
    DATA(enhancement) = deleter->get_preview(
      enhancement = 'ZBE_TEST_SO'
      entity_type = 'enhancement'
      name        = 'ZBE_TEST_SO' ).
    cl_abap_unit_assert=>assert_differs(
      act = node-token
      exp = enhancement-token ).
  ENDMETHOD.

  METHOD preview_cascades_own_entities.
    require_fixture( ).
    DATA(enhancement) = NEW zcl_be_reader( )->get_enhancement( 'ZBE_TEST_SO' ).
    DATA(preview) = deleter->get_preview(
      enhancement = 'ZBE_TEST_SO'
      entity_type = 'node'
      name        = 'ZBE_TEST_NOTE' ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( preview-deletes[ type = 'node' name = 'ZBE_TEST_NOTE' ] ) ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( line_exists( preview-deletes[ type = 'node' name = 'ROOT' ] ) ) ).
    LOOP AT enhancement-actions ASSIGNING FIELD-SYMBOL(<action>) WHERE node = 'ZBE_TEST_NOTE' AND is_own = abap_true.
      cl_abap_unit_assert=>assert_true( xsdbool( line_exists( preview-deletes[ type = 'action' name = <action>-name ] ) ) ).
      IF <action>-class IS NOT INITIAL.
        cl_abap_unit_assert=>assert_true( xsdbool( line_exists( preview-remains[ type = 'class' name = <action>-class ] ) ) ).
      ENDIF.
    ENDLOOP.
    LOOP AT enhancement-determinations ASSIGNING FIELD-SYMBOL(<determination>) WHERE node = 'ZBE_TEST_NOTE'.
      cl_abap_unit_assert=>assert_true( xsdbool( line_exists( preview-deletes[ type = 'determination' name = <determination>-name ] ) ) ).
    ENDLOOP.
    LOOP AT enhancement-queries ASSIGNING FIELD-SYMBOL(<query>) WHERE node = 'ZBE_TEST_NOTE'.
      cl_abap_unit_assert=>assert_true( xsdbool( line_exists( preview-deletes[ type = 'query' name = <query>-name ] ) ) ).
    ENDLOOP.
    LOOP AT enhancement-alternative_keys ASSIGNING FIELD-SYMBOL(<key>) WHERE node = 'ZBE_TEST_NOTE'.
      cl_abap_unit_assert=>assert_true( xsdbool( line_exists( preview-deletes[ type = 'alternativeKey' name = <key>-name ] ) ) ).
    ENDLOOP.
    cl_abap_unit_assert=>assert_equals(
      act = NEW zcl_be_reader( )->get_enhancement( 'ZBE_TEST_SO' )
      exp = enhancement ).
  ENDMETHOD.

  METHOD preview_uses_fixed_order.
    DATA rank TYPE i.
    require_fixture( ).
    DATA(preview) = deleter->get_preview(
      enhancement = 'ZBE_TEST_SO'
      entity_type = 'enhancement'
      name        = 'ZBE_TEST_SO' ).
    DATA(previous_rank) = 0.
    LOOP AT preview-deletes ASSIGNING FIELD-SYMBOL(<entry>).
      rank = SWITCH #( <entry>-type
        WHEN 'alternativeKey' THEN 1 WHEN 'association' THEN 2 WHEN 'query' THEN 3
        WHEN 'validation' THEN 4 WHEN 'determination' THEN 5 WHEN 'action' THEN 6
        WHEN 'node' THEN 7 WHEN 'enhancement' THEN 8 WHEN 'ddicObject' THEN 9 WHEN 'constantsInterface' THEN 9 ELSE 0 ).
      cl_abap_unit_assert=>assert_true( xsdbool( rank >= previous_rank AND rank > 0 ) ).
      previous_rank = rank.
    ENDLOOP.
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( preview-deletes[ type = 'enhancement' name = 'ZBE_TEST_SO' ] ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( preview-deletes[ type = 'constantsInterface' ] ) ) ).
  ENDMETHOD.

  METHOD reject_wrong_enhancement_name.
    require_fixture( ).
    " Regression: enhancement previews must reject a requested name that differs from the enhancement.
    TRY.
        deleter->get_preview(
          enhancement = 'ZBE_TEST_SO'
          entity_type = 'enhancement'
          name        = 'ZBE_UNIT_UNKNOWN' ).
        cl_abap_unit_assert=>fail( 'Expected ZBE_BOPF_ENH 025' ).
      CATCH zcx_be_error INTO DATA(error).
        assert_error(
          error  = error
          status = 404
          number = '025' ).
    ENDTRY.
  ENDMETHOD.

  METHOD cascade_subnodes_in_memory.
    " Synthetic nodes keep every DDIC and database reference initial; nothing is persisted.
    deleter->context-enhancement-bo_key = '00000000000000000000000000000001'.
    DATA(parent) = VALUE /bobf/s_conf_model_api_node( node_key = '00000000000000000000000000000002'
      node_name = 'ZUNIT_PARENT' node_type = 'N' origin_bo_key = deleter->context-enhancement-bo_key ).
    DATA(child) = VALUE /bobf/s_conf_model_api_node( node_key = '00000000000000000000000000000003'
      node_name = 'ZUNIT_CHILD' node_type = 'N' origin_bo_key = deleter->context-enhancement-bo_key
      parent_node_key = parent-node_key ).
    deleter->model-nodes = VALUE #( ( parent ) ( child ) ).
    deleter->add_node(
      node  = parent
      depth = 0 ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( deleter->plan-steps )
      exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = deleter->plan-steps[ name = 'ZUNIT_CHILD' ]-depth
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = deleter->plan-steps[ name = 'ZUNIT_PARENT' ]-depth
      exp = 0 ).
    cl_abap_unit_assert=>assert_equals(
      act = deleter->plan-steps[ 1 ]-name
      exp = 'ZUNIT_CHILD' ).
    cl_abap_unit_assert=>assert_initial( deleter->plan-generated ).
  ENDMETHOD.

  METHOD cascade_action_validations.
    " Synthetic model entries have no persistent backing objects.
    deleter->context-enhancement-bo_key = '00000000000000000000000000000001'.
    DATA(action) = VALUE /bobf/s_conf_model_api_action( act_key = '00000000000000000000000000000002'
      act_name = 'ZUNIT_ACTION' act_class = 'ZUNIT_IMPLEMENTATION' ).
    deleter->model-validations = VALUE #( ( val_key = '00000000000000000000000000000003'
      val_name = 'ZUNIT_VALIDATION' action_key = action-act_key origin_bo_key = deleter->context-enhancement-bo_key ) ).
    deleter->add_action( action ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( deleter->plan-steps )
      exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = deleter->plan-steps[ 1 ]-type
      exp = 'validation' ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( deleter->plan-remains[ type = 'class' name = 'ZUNIT_IMPLEMENTATION' ] ) ) ).
  ENDMETHOD.
ENDCLASS.
