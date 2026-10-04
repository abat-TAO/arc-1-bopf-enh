CLASS zcl_be_test_fixture DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_be_test_fixture IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA result TYPE zcl_be_writer=>result.
    DATA status TYPE string.
    TYPES requests TYPE STANDARD TABLE OF zcl_be_writer=>request WITH EMPTY KEY.
    " Only these fixed create requests are executed; existing entities are never updated or deleted.
    DATA(steps) = VALUE requests(
      ( operation = 'createEnhancement' name = 'ZBE_TEST_SO' base_business_object = '/BOBF/EPM_SALES_ORDER'
        package = '$TMP' description = 'Test enhancement' )
      " Read the external association target before other operations perform SAP name checks.
      ( operation = 'createAssociation' name = 'ZBE_TEST_TO_PRODUCT' node = 'ROOT'
        target_business_object = '/BOBF/EPM_PRODUCT' target_node = 'ROOT'
        class = 'ZCL_BE_C_TEST_TO_PRODUCT' cardinality = 'many' description = 'To product' )
      ( operation = 'createNode' name = 'ZBE_TEST_NOTE' node = 'ROOT'
        data_structure = 'ZBE_S_TEST_NOTE_D' database_table = 'ZBE_D_TNOTE'
        description = 'Notes of the sales order' )
      ( operation = 'createNode' name = 'ZBE_TEST_SUB' node = 'ZBE_TEST_NOTE'
        data_structure = 'ZBE_S_TEST_SUB_D' database_table = 'ZBE_D_TSUB'
        description = 'Remarks of a note' )
      ( operation = 'createAction' name = 'ZBE_TEST_RELEASE' node = 'ROOT'
        class = 'ZCL_BE_A_TEST_RELEASE' cardinality = 'many' description = 'Release the sales order' )
      ( operation = 'createActionEnhancement' name = 'ZBE_TEST_PRE_CONFIRM' node = 'ROOT'
        base_action = 'CONFIRM' timing = 'pre' class = 'ZCL_BE_A_TEST_PRE_CONFIRM' description = 'Before confirm' )
      ( operation = 'createActionEnhancement' name = 'ZBE_TEST_POST_CONFIRM' node = 'ROOT'
        base_action = 'CONFIRM' timing = 'post' class = 'ZCL_BE_A_TEST_POST_CONFIRM' )
      ( operation = 'createDetermination' name = 'ZBE_TEST_DET' node = 'ROOT'
        class = 'ZCL_BE_D_TEST_DET' pattern = 'afterModify' description = 'Determination changed'
        triggers = VALUE #( ( node = 'ROOT' on_create = abap_true on_update = abap_true )
          ( node = 'ZBE_TEST_NOTE' association = 'TO_PARENT' on_create = abap_true on_delete = abap_true ) )
        write_nodes = VALUE #( ( node = 'ROOT' ) ) )
      ( operation = 'createDetermination' name = 'ZBE_TEST_DET_ARC1' node = 'ROOT'
        class = 'ZCL_BE_D_TEST_DET_ARC1' pattern = 'afterModify' description = 'Items to header, through ARC-1'
        triggers = VALUE #( ( node = 'ITEM' association = 'TO_PARENT'
          on_create = abap_true on_update = abap_true on_delete = abap_true ) )
        write_nodes = VALUE #( ( node = 'ROOT' ) ( node = 'ITEM' association = 'TO_PARENT' ) ) )
      ( operation = 'createDetermination' name = 'ZBE_TEST_DET_ITEM' node = 'ROOT'
        class = 'ZCL_BE_D_TEST_DET_ITEM' pattern = 'afterModify' description = 'Summary from items'
        triggers = VALUE #( ( node = 'ITEM' association = 'TO_PARENT'
          on_create = abap_true on_update = abap_true on_delete = abap_true ) )
        write_nodes = VALUE #( ( node = 'ROOT' ) ( node = 'ITEM' association = 'TO_PARENT' ) ) )
      ( operation = 'createValidation' name = 'ZBE_TEST_VAL' node = 'ROOT'
        class = 'ZCL_BE_V_TEST_VAL' impact = 'messages' description = 'Validation changed'
        triggers = VALUE #( ( node = 'ROOT' on_create = abap_true on_update = abap_true ) ) )
      ( operation = 'createValidation' name = 'ZBE_TEST_VAL_NOTE' node = 'ZBE_TEST_NOTE'
        class = 'ZCL_BE_V_TEST_VAL_NOTE' impact = 'messages'
        triggers = VALUE #( ( node = 'ROOT' association = 'ZBE_TEST_NOTE' on_update = abap_true ) ) )
      ( operation = 'createActionValidation' name = 'ZBE_TEST_AVAL' node = 'ROOT' action = 'CONFIRM'
        class = 'ZCL_BE_V_TEST_AVAL' description = 'Action validation changed' )
      ( operation = 'createQuery' name = 'ZBE_TEST_Q_NOTE' node = 'ZBE_TEST_NOTE' description = 'Notes by elements' )
      ( operation = 'createAlternativeKey' name = 'ZBE_TEST_PRIORITY' node = 'ZBE_TEST_NOTE'
        fields = VALUE #( ( `PRIORITY` ) ) data_type = 'ZBE_TEST_PRIORITY' table_type = 'ZBE_T_TEST_PRIORITY'
        uniqueness = 'notUnique' uniqueness_check = 'none' ) ).

    DATA(writer) = NEW zcl_be_writer( ).
    TRY.
        LOOP AT steps ASSIGNING FIELD-SYMBOL(<step>).
          result = writer->write( VALUE #( BASE <step>
            enhancement = 'ZBE_TEST_SO' language = 'E' dry_run = abap_false ) ).
          status = COND #( WHEN result-already_existed = abap_true THEN `alreadyExisted` ELSE `created` ).
          out->write( |{ <step>-operation } { <step>-name }: { status }| ).
        ENDLOOP.
      CATCH cx_root INTO DATA(error).
        out->write( |{ <step>-operation } { <step>-name }: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
