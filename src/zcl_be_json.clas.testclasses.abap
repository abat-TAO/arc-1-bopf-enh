CLASS ltcl_json DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS overrides_round_trip FOR TESTING.
    METHODS generated_objects_in_json FOR TESTING.
    METHODS names_use_camel_case FOR TESTING.
    METHODS round_trip FOR TESTING.
    METHODS omit_initial_values FOR TESTING.
ENDCLASS.
CLASS ltcl_json IMPLEMENTATION.
  METHOD overrides_round_trip.
    DATA restored TYPE zcl_be_writer=>request.
    DATA(original) = VALUE zcl_be_writer=>request( constants_interface = 'ZIF_BE_UNIT'
      combined_structure = 'ZBE_S_UNIT' combined_table_type = 'ZBE_T_UNIT' ).
    DATA(json) = zcl_be_json=>to_json( original ).
    cl_abap_unit_assert=>assert_true( xsdbool( json CS '"constantsInterface":"ZIF_BE_UNIT"' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( json CS '"combinedStructure":"ZBE_S_UNIT"' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( json CS '"combinedTableType":"ZBE_T_UNIT"' ) ).
    zcl_be_json=>from_json( EXPORTING json = json CHANGING data = restored ).
    cl_abap_unit_assert=>assert_equals( act = restored
                                        exp = original ).
  ENDMETHOD.

  METHOD generated_objects_in_json.
    DATA restored TYPE zcl_be_writer=>result.
    DATA(original) = VALUE zcl_be_writer=>result( dry_run = abap_true class = 'ZBE_S_UNIT'
      generated = VALUE #( ( type = `combinedStructure` name = `ZBE_S_UNIT` )
        ( type = `combinedTableType` name = `ZBE_T_UNIT` ) ( type = `databaseTable` name = `ZBE_D_UNIT` ) ) ).
    DATA(json) = zcl_be_json=>to_json( original ).
    cl_abap_unit_assert=>assert_true( xsdbool( json CS '"generated":[' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( json CS '"type":"combinedStructure"' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( json CS '"name":"ZBE_T_UNIT"' ) ).
    zcl_be_json=>from_json( EXPORTING json = json CHANGING data = restored ).
    cl_abap_unit_assert=>assert_equals( act = restored
                                        exp = original ).
  ENDMETHOD.

  METHOD names_use_camel_case.
    DATA restored TYPE zcl_be_writer=>names.
    DATA(original) = VALUE zcl_be_writer=>names( class = 'ZCL_BE_UNIT' constants_interface = 'ZIF_BE_UNIT'
      parameter_structure = 'ZBE_S_UNIT_P' data_structure = 'ZBE_S_UNIT_D' transient_structure = 'ZBE_S_UNIT_T'
      combined_structure = 'ZBE_S_UNIT_C' combined_table_type = 'ZBE_T_UNIT_C' database_table = 'ZBE_D_UNIT'
      hints = VALUE #( ( `Table proposal cannot be generated` ) ) ).
    DATA(json) = zcl_be_json=>to_json( original ).
    LOOP AT VALUE string_table( ( `class` ) ( `constantsInterface` ) ( `parameterStructure` )
        ( `dataStructure` ) ( `transientStructure` ) ( `combinedStructure` )
        ( `combinedTableType` ) ( `databaseTable` ) ( `hints` ) ) ASSIGNING FIELD-SYMBOL(<property>).
      cl_abap_unit_assert=>assert_true( xsdbool( json CS |"{ <property> }":| ) ).
    ENDLOOP.
    zcl_be_json=>from_json( EXPORTING json = json CHANGING data = restored ).
    cl_abap_unit_assert=>assert_equals( act = restored
                                        exp = original ).
  ENDMETHOD.

  METHOD round_trip.
    DATA restored TYPE zcl_be_writer=>request.
    DATA original TYPE zcl_be_writer=>request.
    original = VALUE #( operation = 'createAction' enhancement = 'ZBE_TEST_SO' dry_run = abap_true
                        triggers = VALUE #( ( node = 'ROOT' on_create = abap_true ) ) ).
    DATA(json) = zcl_be_json=>to_json( original ).
    cl_abap_unit_assert=>assert_true( xsdbool( json CS '"dryRun":true' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( json CS '"onCreate":true' ) ).
    zcl_be_json=>from_json( EXPORTING json = json CHANGING data = restored ).
    cl_abap_unit_assert=>assert_equals(
      act = restored
      exp = original ).
  ENDMETHOD.

  METHOD omit_initial_values.
    DATA original TYPE zcl_be_writer=>request.
    original-operation = 'createAction'.
    DATA(json) = zcl_be_json=>to_json( original ).
    cl_abap_unit_assert=>assert_equals(
      act = json
      exp = '{"operation":"createAction"}' ).
  ENDMETHOD.
ENDCLASS.
