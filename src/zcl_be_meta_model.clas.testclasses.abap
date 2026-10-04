CLASS ltcl_meta_model DEFINITION DEFERRED.
CLASS zcl_be_meta_model DEFINITION LOCAL FRIENDS ltcl_meta_model.
CLASS ltcl_meta_model DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    CONSTANTS base_key TYPE /bobf/conf_key VALUE '00000000000000000000000000000001'.
    CONSTANTS own_key TYPE /bobf/conf_key VALUE '00000000000000000000000000000002'.
    CONSTANTS unknown_key TYPE /bobf/conf_key VALUE '00000000000000000000000000000003'.
    CONSTANTS base_version_key TYPE /bobf/conf_key VALUE '00000000000000000000000000000004'.
    CONSTANTS own_version_key TYPE /bobf/conf_key VALUE '00000000000000000000000000000005'.
    DATA model TYPE REF TO zcl_be_meta_model.
    DATA locations TYPE zcl_be_meta_model=>locations.
    DATA check_result TYPE zcl_be_meta_model=>check_result.
    METHODS setup.
    METHODS add_message
      IMPORTING
        key      TYPE /bobf/conf_key
        text     TYPE string DEFAULT `Finding`
        severity TYPE c DEFAULT 'W'.
    METHODS classify_base_entity FOR TESTING.
    METHODS classify_own_entity FOR TESTING.
    METHODS classify_unknown_key FOR TESTING.
    METHODS classify_initial_key FOR TESTING.
    METHODS classify_base_version FOR TESTING.
    METHODS classify_own_version FOR TESTING.
    METHODS deduplicate_each_list FOR TESTING.
    METHODS retain_different_findings FOR TESTING.
ENDCLASS.

CLASS ltcl_meta_model IMPLEMENTATION.
  METHOD setup.
    model = NEW #( ).
    locations = VALUE #(
      ( key = base_key entity_type = `determination` entity_name = `DET_PROP_DOCREF_BR` is_base = abap_true )
      ( key = own_key entity_type = `node` entity_name = `ZBE_TEST_NOTE` is_base = abap_false )
      ( key = base_version_key is_base = abap_true ) ).
  ENDMETHOD.

  METHOD add_message.
    DATA(messages) = /bobf/cl_frw_factory=>get_message( ).
    messages->add_cm( NEW /bobf/cm_frw_symsg(
      severity           = severity
      message_text       = text
      ms_origin_location = VALUE #( key = key ) ) ).
    model->add_findings(
      EXPORTING messages     = messages
                locations    = locations
      CHANGING  check_result = check_result ).
  ENDMETHOD.

  METHOD classify_base_entity.
    add_message( base_key ).
    cl_abap_unit_assert=>assert_initial( check_result-findings ).
    cl_abap_unit_assert=>assert_equals(
      act = check_result-base_findings
      exp = VALUE zcl_be_meta_model=>findings(
        ( severity = `W` text = `Finding` entity_type = `determination` entity_name = `DET_PROP_DOCREF_BR` ) ) ).
  ENDMETHOD.

  METHOD classify_own_entity.
    add_message( own_key ).
    cl_abap_unit_assert=>assert_initial( check_result-base_findings ).
    cl_abap_unit_assert=>assert_equals(
      act = check_result-findings
      exp = VALUE zcl_be_meta_model=>findings(
        ( severity = `W` text = `Finding` entity_type = `node` entity_name = `ZBE_TEST_NOTE` ) ) ).
  ENDMETHOD.

  METHOD classify_unknown_key.
    add_message( unknown_key ).
    cl_abap_unit_assert=>assert_initial( check_result-base_findings ).
    cl_abap_unit_assert=>assert_equals(
      act = check_result-findings
      exp = VALUE zcl_be_meta_model=>findings( ( severity = `W` text = `Finding` ) ) ).
  ENDMETHOD.

  METHOD classify_initial_key.
    add_message( VALUE #( ) ).
    cl_abap_unit_assert=>assert_initial( check_result-base_findings ).
    cl_abap_unit_assert=>assert_equals(
      act = check_result-findings
      exp = VALUE zcl_be_meta_model=>findings( ( severity = `W` text = `Finding` ) ) ).
  ENDMETHOD.

  METHOD classify_base_version.
    add_message( base_version_key ).
    cl_abap_unit_assert=>assert_initial( check_result-findings ).
    cl_abap_unit_assert=>assert_equals(
      act = check_result-base_findings
      exp = VALUE zcl_be_meta_model=>findings( ( severity = `W` text = `Finding` ) ) ).
  ENDMETHOD.

  METHOD classify_own_version.
    add_message( own_version_key ).
    cl_abap_unit_assert=>assert_initial( check_result-base_findings ).
    cl_abap_unit_assert=>assert_equals(
      act = check_result-findings
      exp = VALUE zcl_be_meta_model=>findings( ( severity = `W` text = `Finding` ) ) ).
  ENDMETHOD.

  METHOD deduplicate_each_list.
    add_message( own_key ).
    add_message( unknown_key ).
    add_message( base_key ).
    add_message( base_version_key ).
    " Repeated check groups must preserve one entry per list, including its first entity.
    add_message( own_key ).
    add_message( base_key ).
    cl_abap_unit_assert=>assert_equals(
      act = check_result-findings
      exp = VALUE zcl_be_meta_model=>findings(
        ( severity = `W` text = `Finding` entity_type = `node` entity_name = `ZBE_TEST_NOTE` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = check_result-base_findings
      exp = VALUE zcl_be_meta_model=>findings(
        ( severity = `W` text = `Finding` entity_type = `determination` entity_name = `DET_PROP_DOCREF_BR` ) ) ).
  ENDMETHOD.

  METHOD retain_different_findings.
    DATA location TYPE REF TO /bobf/s_frw_key.
    LOOP AT VALUE /bobf/t_frw_key( ( key = own_key ) ( key = base_key ) ) REFERENCE INTO location.
      add_message( key      = location->key
                   text     = `Finding`
                   severity = 'W' ).
      add_message( key      = location->key
                   text     = `Finding`
                   severity = 'I' ).
      add_message( key      = location->key
                   text     = `Other finding`
                   severity = 'W' ).
    ENDLOOP.
    cl_abap_unit_assert=>assert_equals(
      act = check_result-findings
      exp = VALUE zcl_be_meta_model=>findings(
        ( severity = `W` text = `Finding` entity_type = `node` entity_name = `ZBE_TEST_NOTE` )
        ( severity = `I` text = `Finding` entity_type = `node` entity_name = `ZBE_TEST_NOTE` )
        ( severity = `W` text = `Other finding` entity_type = `node` entity_name = `ZBE_TEST_NOTE` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = check_result-base_findings
      exp = VALUE zcl_be_meta_model=>findings(
        ( severity = `W` text = `Finding` entity_type = `determination` entity_name = `DET_PROP_DOCREF_BR` )
        ( severity = `I` text = `Finding` entity_type = `determination` entity_name = `DET_PROP_DOCREF_BR` )
        ( severity = `W` text = `Other finding` entity_type = `determination` entity_name = `DET_PROP_DOCREF_BR` ) ) ).
  ENDMETHOD.
ENDCLASS.
