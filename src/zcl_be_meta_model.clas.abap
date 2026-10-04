"! Direct access to the BOPF meta model /BOBF/CONF_MODEL for what /BOBF/CL_CONF_MODEL_API lacks
CLASS zcl_be_meta_model DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF finding,
        severity    TYPE string,
        text        TYPE string,
        entity_type TYPE string,
        entity_name TYPE string,
      END OF finding,
      findings TYPE STANDARD TABLE OF finding WITH EMPTY KEY.

    TYPES:
      BEGIN OF check_result,
        findings      TYPE findings,
        base_findings TYPE findings,
      END OF check_result.

    "! Same mapping SAP's ADT backend uses in /BOBF/CL_CONF_MODEL_API_ADT->PROCESS_ALTERNATIVE_KEYS,
    "! including the uniqueness validation of the node for keys checked after modify
    METHODS create_alternative_key
      IMPORTING
        bo_key            TYPE /bobf/obm_bo_key
        node              TYPE /bobf/s_conf_model_api_node
        alternative_key   TYPE /bobf/s_conf_model_adt_alt
        smart_validations TYPE abap_bool
      RAISING
        zcx_be_error.

    "! Also removes the uniqueness validation of the node when no key needs it anymore
    METHODS delete_alternative_key
      IMPORTING
        bo_key TYPE /bobf/obm_bo_key
        name   TYPE csequence
      RAISING
        zcx_be_error.

    "! Deletes an action with its configuration. /BOBF/CL_CONF_MODEL_API=>DELETE_ACTION deletes the
    "! read and write nodes with the key of the last configuration entry and fails for actions with write nodes.
    METHODS delete_action
      IMPORTING
        bo_key TYPE /bobf/obm_bo_key
        name   TYPE csequence
      RAISING
        zcx_be_error.

    "! Consistency check of the active version of an enhancement, as the BOPF designer runs it. Findings
    "! located at entities or the version of the base business object are SAP's and come as base findings.
    METHODS check
      IMPORTING
        enhancement   TYPE /bobf/s_conf_model_api_bo
      RETURNING
        VALUE(result) TYPE check_result.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF dependent_node,
        association TYPE /bobf/obm_assoc_key,
        node        TYPE /bobf/obm_node_key,
      END OF dependent_node,
      dependent_nodes TYPE STANDARD TABLE OF dependent_node WITH EMPTY KEY.

    TYPES:
      BEGIN OF location,
        key         TYPE /bobf/conf_key,
        entity_type TYPE string,
        entity_name TYPE string,
        is_base     TYPE abap_bool,
      END OF location,
      locations TYPE SORTED TABLE OF location WITH NON-UNIQUE KEY key.

    "! Applies the modifications, regenerates the constants interface and saves
    METHODS apply
      IMPORTING
        version_key   TYPE /bobf/conf_key
        modifications TYPE /bobf/t_frw_modification
        entity_type   TYPE string
        name          TYPE csequence
      RAISING
        zcx_be_error.

    METHODS get_version_key
      IMPORTING
        bo_key        TYPE /bobf/obm_bo_key
      RETURNING
        VALUE(result) TYPE /bobf/conf_key.

    "! Model entities of the enhancement and the base version, by the key check messages point to
    METHODS get_locations
      IMPORTING
        enhancement   TYPE /bobf/s_conf_model_api_bo
      RETURNING
        VALUE(result) TYPE locations.

    "! Adds the messages of a container that are not among the findings yet
    METHODS add_findings
      IMPORTING
        messages     TYPE REF TO /bobf/if_frw_message
        locations    TYPE locations
      CHANGING
        check_result TYPE check_result.

    "! Deletion of the uniqueness validation of the node, unless another key of the node is checked after modify
    METHODS get_uniqueness_check_deletion
      IMPORTING
        alternative_key  TYPE LINE OF /bobf/t_conf_altkey
        alternative_keys TYPE /bobf/t_conf_altkey
      RETURNING
        VALUE(result)    TYPE /bobf/t_frw_modification.
ENDCLASS.



CLASS zcl_be_meta_model IMPLEMENTATION.

  METHOD create_alternative_key.
    DATA modifications TYPE /bobf/t_frw_modification.

    DATA(version_key) = get_version_key( bo_key ).
    /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( )->cleanup( ).

    DATA(new_key) = alternative_key.
    new_key-altkey_key = /bobf/cl_frw_factory=>get_new_key( ).
    DATA(mapper) = NEW /bobf/cl_conf_model_api_map( ).
    mapper->map_altkey_for_create( EXPORTING iv_create_with_header = abap_true
                                             is_alternative_key    = new_key
                                             iv_version_key        = version_key
                                             iv_bo_key             = bo_key
                                             iv_node_key           = node-node_key
                                   CHANGING  ct_modification       = modifications ).
    " One validation per node checks all keys that are unique after modify
    IF alternative_key-uniqueness_check = /bobf/if_conf_c=>sc_altkey_uniqcheck_after_mod
        AND /bobf/cl_conf_model_api_reuse=>get_val_key_altkey_uniq_check( node-node_key ) IS INITIAL.
      mapper->map_val_unique_for_create( EXPORTING is_node              = node
                                                   iv_version_key       = version_key
                                                   iv_bo_key            = bo_key
                                                   iv_node_key          = node-node_key
                                                   iv_smart_validations = smart_validations
                                         CHANGING  ct_modification      = modifications ).
    ENDIF.
    apply( version_key   = version_key
           modifications = modifications
           entity_type   = `alternative key`
           name          = alternative_key-altkey_name ).
  ENDMETHOD.


  METHOD delete_alternative_key.
    DATA alternative_keys TYPE /bobf/t_conf_altkey.
    DATA alternative_key LIKE LINE OF alternative_keys.
    DATA field_keys TYPE /bobf/t_frw_key.
    DATA modifications TYPE /bobf/t_frw_modification.

    DATA(version_key) = get_version_key( bo_key ).
    DATA(service_manager) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /bobf/if_conf_obj_c=>sc_bo_key ).
    /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( )->cleanup( ).

    " The instances have to be in the meta model buffer; their database keys alone are not found
    service_manager->retrieve_by_association(
      EXPORTING
        iv_node_key    = /bobf/if_conf_obj_c=>sc_node-version
        it_key         = VALUE #( ( key = version_key ) )
        iv_association = /bobf/if_conf_obj_c=>sc_association-version-alternative_key
        iv_fill_data   = abap_true
      IMPORTING
        et_data        = alternative_keys ).

    LOOP AT alternative_keys INTO alternative_key WHERE altkey_name_aie = name AND origin_bo_key = bo_key.
      service_manager->retrieve_by_association(
        EXPORTING
          iv_node_key    = /bobf/if_conf_obj_c=>sc_node-alternative_key
          it_key         = VALUE #( ( key = alternative_key-key ) )
          iv_association = /bobf/if_conf_obj_c=>sc_association-alternative_key-alternative_key_field
        IMPORTING
          et_target_key  = field_keys ).
      INSERT VALUE #( node        = /bobf/if_conf_obj_c=>sc_node-alternative_key
                      key         = alternative_key-key
                      change_mode = /bobf/if_frw_c=>sc_modify_delete ) INTO TABLE modifications.
      modifications = VALUE #( BASE modifications
                               FOR field_key IN field_keys
                               ( node        = /bobf/if_conf_obj_c=>sc_node-alternative_key_field
                                 key         = field_key-key
                                 change_mode = /bobf/if_frw_c=>sc_modify_delete ) ).
      INSERT LINES OF get_uniqueness_check_deletion( alternative_key  = alternative_key
                                                     alternative_keys = alternative_keys ) INTO TABLE modifications.
    ENDLOOP.
    apply( version_key   = version_key
           modifications = modifications
           entity_type   = `alternative key`
           name          = name ).
  ENDMETHOD.


  METHOD delete_action.
    DATA actions TYPE /bobf/t_conf_act_list.
    DATA action LIKE LINE OF actions.
    DATA dependent TYPE dependent_node.
    DATA dependent_keys TYPE /bobf/t_frw_key.
    DATA modifications TYPE /bobf/t_frw_modification.

    " The same dependents DELETE_ACTION deletes, each with its own keys
    DATA(dependents) = VALUE dependent_nodes(
      ( association = /bobf/if_conf_obj_c=>sc_association-action-conf  node = /bobf/if_conf_obj_c=>sc_node-action_conf )
      ( association = /bobf/if_conf_obj_c=>sc_association-action-read  node = /bobf/if_conf_obj_c=>sc_node-action_read )
      ( association = /bobf/if_conf_obj_c=>sc_association-action-write node = /bobf/if_conf_obj_c=>sc_node-action_write ) ).
    DATA(version_key) = get_version_key( bo_key ).
    DATA(service_manager) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /bobf/if_conf_obj_c=>sc_bo_key ).
    /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( )->cleanup( ).

    service_manager->retrieve_by_association(
      EXPORTING
        iv_node_key    = /bobf/if_conf_obj_c=>sc_node-version
        it_key         = VALUE #( ( key = version_key ) )
        iv_association = /bobf/if_conf_obj_c=>sc_association-version-action
        iv_fill_data   = abap_true
      IMPORTING
        et_data        = actions ).

    LOOP AT actions INTO action WHERE act_name = name AND origin_bo_key = bo_key.
      INSERT VALUE #( node        = /bobf/if_conf_obj_c=>sc_node-action
                      key         = action-key
                      change_mode = /bobf/if_frw_c=>sc_modify_delete ) INTO TABLE modifications.
      LOOP AT dependents INTO dependent.
        service_manager->retrieve_by_association(
          EXPORTING
            iv_node_key    = /bobf/if_conf_obj_c=>sc_node-action
            it_key         = VALUE #( ( key = action-key ) )
            iv_association = dependent-association
          IMPORTING
            et_target_key  = dependent_keys ).
        modifications = VALUE #( BASE modifications
                                 FOR dependent_key IN dependent_keys
                                 ( node        = dependent-node
                                   key         = dependent_key-key
                                   change_mode = /bobf/if_frw_c=>sc_modify_delete ) ).
      ENDLOOP.
    ENDLOOP.
    apply( version_key   = version_key
           modifications = modifications
           entity_type   = `action`
           name          = name ).
  ENDMETHOD.


  METHOD check.
    DATA check_group TYPE LINE OF /bobf/t_frw_key.
    DATA messages TYPE REF TO /bobf/if_frw_message.

    DATA(transaction_manager) = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).
    DATA(service_manager) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /bobf/if_conf_obj_c=>sc_bo_key ).
    transaction_manager->cleanup( ).

    " Checking the base business object as well takes minutes for large ones such as /SCMTMS/TOR; the
    " location of a message tells whether it is about the base or the enhancement
    DATA(locations) = get_locations( enhancement ).
    DATA(version_keys) = VALUE /bobf/t_frw_key( ( key = get_version_key( enhancement-bo_key ) ) ).
    DATA(check_groups) = VALUE /bobf/t_frw_key( ( key = /bobf/if_conf_obj_c=>sc_group-check_model )
                                                ( key = /bobf/if_conf_obj_c=>sc_group-check_model_elements ) ).
    LOOP AT check_groups INTO check_group.
      service_manager->check_consistency( EXPORTING iv_node_key    = /bobf/if_conf_obj_c=>sc_node-version
                                                    it_key         = version_keys
                                                    iv_check_scope = /bobf/if_frw_c=>sc_scope_substructure
                                                    iv_check_group = check_group-key
                                          IMPORTING eo_message     = messages ).
      IF messages IS BOUND.
        add_findings( EXPORTING messages     = messages
                                locations    = locations
                      CHANGING  check_result = result ).
      ENDIF.
    ENDLOOP.
    transaction_manager->cleanup( ).
  ENDMETHOD.


  METHOD apply.
    DATA(transaction_manager) = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).
    DATA(service_manager) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /bobf/if_conf_obj_c=>sc_bo_key ).

    service_manager->modify( EXPORTING it_modification = modifications
                             IMPORTING eo_change       = DATA(change)
                                       eo_message      = DATA(modify_messages) ).
    IF change->has_failed_changes( ) = abap_true.
      transaction_manager->cleanup( ).
      zcx_be_error=>raise_not_saved( entity_type = entity_type
                                     name        = name
                                     messages    = modify_messages ).
    ENDIF.
    service_manager->do_action( iv_act_key = /bobf/if_conf_obj_c=>sc_action-version-generate_const_if
                                it_key     = VALUE #( ( key = version_key ) ) ).
    transaction_manager->save( IMPORTING ev_rejected = DATA(rejected)
                                         eo_message  = DATA(save_messages) ).
    transaction_manager->cleanup( ).
    IF rejected = abap_true.
      zcx_be_error=>raise_not_saved( entity_type = entity_type
                                     name        = name
                                     messages    = save_messages ).
    ENDIF.
  ENDMETHOD.


  METHOD get_version_key.
    /bobf/cl_conf_model_api=>get_version( EXPORTING iv_bo_key      = bo_key
                                          IMPORTING ev_version_key = result ).
  ENDMETHOD.


  METHOD get_locations.
    DATA(bo_key) = enhancement-bo_key.
    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key   = bo_key
                                           IMPORTING et_node_tab = DATA(nodes) ).
    /bobf/cl_conf_model_api=>get_action_tab( EXPORTING iv_bo_key     = bo_key
                                             IMPORTING et_action_tab = DATA(actions) ).
    /bobf/cl_conf_model_api=>get_determination_tab( EXPORTING iv_bo_key        = bo_key
                                                    IMPORTING et_determination = DATA(determinations) ).
    /bobf/cl_conf_model_api=>get_validation_tab( EXPORTING iv_bo_key     = bo_key
                                                 IMPORTING et_validation = DATA(validations) ).
    /bobf/cl_conf_model_api=>get_query_tab( EXPORTING iv_bo_key = bo_key
                                            IMPORTING et_query  = DATA(queries) ).
    /bobf/cl_conf_model_api=>get_association_tab( EXPORTING iv_bo_key      = bo_key
                                                  IMPORTING et_association = DATA(associations) ).

    " The enhancement contains the entities of its base with their keys and origin
    result = VALUE #(
      ( key = get_version_key( enhancement-super_bo_key ) is_base = abap_true )
      ( LINES OF VALUE locations( FOR node IN nodes
                                  ( key         = node-node_key
                                    entity_type = `node`
                                    entity_name = node-node_name
                                    is_base     = xsdbool( node-origin_bo_key <> bo_key ) ) ) )
      ( LINES OF VALUE locations( FOR action IN actions
                                  ( key         = action-act_key
                                    entity_type = COND #( WHEN action-act_cat = /bobf/if_conf_c=>sc_action_enhancement_pre
                                                            OR action-act_cat = /bobf/if_conf_c=>sc_action_enhancement_post
                                                          THEN `actionEnhancement`
                                                          ELSE `action` )
                                    entity_name = action-act_name
                                    is_base     = xsdbool( action-origin_bo_key <> bo_key ) ) ) )
      ( LINES OF VALUE locations( FOR determination IN determinations
                                  ( key         = determination-det_key
                                    entity_type = `determination`
                                    entity_name = determination-det_name
                                    is_base     = xsdbool( determination-origin_bo_key <> bo_key ) ) ) )
      ( LINES OF VALUE locations( FOR validation IN validations
                                  ( key         = validation-val_key
                                    entity_type = `validation`
                                    entity_name = validation-val_name
                                    is_base     = xsdbool( validation-origin_bo_key <> bo_key ) ) ) )
      ( LINES OF VALUE locations( FOR query IN queries
                                  ( key         = query-query_key
                                    entity_type = `query`
                                    entity_name = query-query_name
                                    is_base     = xsdbool( query-origin_bo_key <> bo_key ) ) ) )
      ( LINES OF VALUE locations( FOR association IN associations
                                  ( key         = association-assoc_key
                                    entity_type = `association`
                                    entity_name = association-assoc_name
                                    is_base     = xsdbool( association-origin_bo_key <> bo_key ) ) ) ) ).
  ENDMETHOD.


  METHOD add_findings.
    DATA finding TYPE finding.
    DATA location TYPE location.

    messages->get( IMPORTING et_message = DATA(entries) ).
    LOOP AT entries ASSIGNING FIELD-SYMBOL(<entry>).
      " Messages without a known location, such as those about subentities, count as the enhancement's:
      " a finding too many is better than a hidden one
      location = VALUE #( locations[ key = <entry>->ms_origin_location-key ] OPTIONAL ).
      finding = VALUE #( severity    = <entry>->severity
                         text        = <entry>->get_text( )
                         entity_type = location-entity_type
                         entity_name = location-entity_name ).
      IF location-is_base = abap_true.
        IF NOT line_exists( check_result-base_findings[ severity = finding-severity text = finding-text ] ).
          INSERT finding INTO TABLE check_result-base_findings.
        ENDIF.
      ELSEIF NOT line_exists( check_result-findings[ severity = finding-severity text = finding-text ] ).
        INSERT finding INTO TABLE check_result-findings.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_uniqueness_check_deletion.
    IF alternative_key-unique_check_aie <> /bobf/if_conf_c=>sc_altkey_uniqcheck_after_mod.
      RETURN.
    ENDIF.
    LOOP AT alternative_keys TRANSPORTING NO FIELDS USING KEY altkey_name
         WHERE node_key = alternative_key-node_key AND key <> alternative_key-key
           AND unique_check_aie = /bobf/if_conf_c=>sc_altkey_uniqcheck_after_mod.
      RETURN.
    ENDLOOP.
    DATA(validation) = /bobf/cl_conf_model_api_reuse=>get_val_key_altkey_uniq_check( alternative_key-node_key ).
    IF validation IS INITIAL.
      RETURN.
    ENDIF.

    /bobf/cl_conf_model_api_reuse=>get_validation_subent_keys(
      EXPORTING
        iv_val_key                   = validation-key
      IMPORTING
        et_val_trigger_key_delete    = DATA(trigger_keys)
        et_val_conf_key_delete       = DATA(configuration_keys)
        et_val_group_conf_key_delete = DATA(group_keys) ).
    NEW /bobf/cl_conf_model_api_map( )->map_val_for_delete(
      EXPORTING
        iv_with_header               = abap_true
        iv_val_key                   = validation-key
        it_val_trigger_key_delete    = trigger_keys
        it_val_conf_key_delete       = configuration_keys
        it_val_group_conf_key_delete = group_keys
      CHANGING
        ct_modification              = result ).
  ENDMETHOD.

ENDCLASS.
