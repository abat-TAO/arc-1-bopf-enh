"! Two-step deletion of enhancement entities. The preview lists what is deleted, in the order it
"! runs, and what stays; its token confirms exactly that state for the delete.
CLASS zcl_be_deleter DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF entry,
        type TYPE string,
        name TYPE string,
      END OF entry,
      entries TYPE STANDARD TABLE OF entry WITH EMPTY KEY.

    TYPES:
      BEGIN OF preview,
        enhancement TYPE string,
        entity_type TYPE string,
        name        TYPE string,
        package     TYPE string,
        transport   TYPE string,
        deletes     TYPE entries,
        remains     TYPE entries,
        token       TYPE string,
      END OF preview.

    TYPES:
      BEGIN OF result,
        operation   TYPE string,
        enhancement TYPE string,
        entity_type TYPE string,
        name        TYPE string,
        package     TYPE string,
        transport   TYPE string,
        deleted     TYPE entries,
        remains     TYPE entries,
      END OF result.

    CONSTANTS operation TYPE string VALUE `delete`.

    METHODS get_preview
      IMPORTING
        enhancement   TYPE string
        entity_type   TYPE string
        name          TYPE string
        transport     TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE preview
      RAISING
        zcx_be_error.

    METHODS delete
      IMPORTING
        request       TYPE zcl_be_writer=>request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF step,
        rank     TYPE i,
        depth    TYPE i,
        type     TYPE string,
        name     TYPE string,
        key      TYPE /bobf/conf_key,
        category TYPE string,
      END OF step,
      steps TYPE STANDARD TABLE OF step WITH EMPTY KEY.

    TYPES:
      BEGIN OF alternative_key,
        name       TYPE string,
        node_key   TYPE /bobf/obm_node_key,
        data_type  TYPE string,
        table_type TYPE string,
      END OF alternative_key,
      alternative_keys TYPE STANDARD TABLE OF alternative_key WITH EMPTY KEY.

    TYPES:
      BEGIN OF model_state,
        nodes            TYPE /bobf/t_conf_model_api_node,
        actions          TYPE /bobf/t_conf_model_api_action,
        determinations   TYPE /bobf/t_conf_model_api_det,
        validations      TYPE /bobf/t_conf_model_api_val,
        queries          TYPE /bobf/t_conf_model_api_query,
        associations     TYPE /bobf/t_conf_model_api_assoc,
        alternative_keys TYPE alternative_keys,
      END OF model_state.

    TYPES:
      BEGIN OF deletion_plan,
        steps     TYPE steps,
        generated TYPE entries,
        remains   TYPE entries,
      END OF deletion_plan.

    " Fixed order: alternative keys first, because deleting a node leaves its alternative keys behind
    CONSTANTS:
      BEGIN OF rank,
        alternative_key    TYPE i VALUE 1,
        association        TYPE i VALUE 2,
        query              TYPE i VALUE 3,
        validation         TYPE i VALUE 4,
        determination      TYPE i VALUE 5,
        action_enhancement TYPE i VALUE 6,
        action             TYPE i VALUE 7,
        node               TYPE i VALUE 8,
        enhancement        TYPE i VALUE 9,
      END OF rank.

    DATA context TYPE zcl_be_change_context=>context.
    DATA model TYPE model_state.
    DATA plan TYPE deletion_plan.

    METHODS plan_deletion
      IMPORTING
        entity_type TYPE string
        name        TYPE string
      RAISING
        zcx_be_error.

    METHODS read_model
      RETURNING
        VALUE(result) TYPE model_state.

    METHODS add_entity
      IMPORTING
        entity_type TYPE string
        name        TYPE string
      RAISING
        zcx_be_error.

    METHODS add_enhancement
      RAISING
        zcx_be_error.

    METHODS add_node
      IMPORTING
        node  TYPE /bobf/s_conf_model_api_node
        depth TYPE i
      RAISING
        zcx_be_error.

    METHODS add_action
      IMPORTING
        action TYPE /bobf/s_conf_model_api_action.

    METHODS add_determination
      IMPORTING
        determination TYPE /bobf/s_conf_model_api_det.

    METHODS add_validation
      IMPORTING
        validation TYPE /bobf/s_conf_model_api_val.

    METHODS add_query
      IMPORTING
        query TYPE /bobf/s_conf_model_api_query.

    METHODS add_association
      IMPORTING
        association TYPE /bobf/s_conf_model_api_assoc.

    METHODS add_alternative_key
      IMPORTING
        alternative_key TYPE alternative_key.

    METHODS add_step
      IMPORTING
        step TYPE step.

    METHODS add_entry
      IMPORTING
        type    TYPE string
        name    TYPE csequence
      CHANGING
        entries TYPE entries.

    METHODS is_modelled_association
      IMPORTING
        association   TYPE /bobf/s_conf_model_api_assoc
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! DDIC objects BOPF generated for the node; the data structures were created by the developer and stay
    METHODS add_generated_objects
      IMPORTING
        node TYPE /bobf/s_conf_model_api_node.

    METHODS check_table_is_empty
      IMPORTING
        table TYPE tabname
      RAISING
        zcx_be_error.

    METHODS get_deletes
      RETURNING
        VALUE(result) TYPE entries.

    "! Any change of the enhancement or another user makes the token invalid
    METHODS calculate_token
      IMPORTING
        entity_type   TYPE string
        name          TYPE string
      RETURNING
        VALUE(result) TYPE string
      RAISING
        zcx_be_error.

    METHODS execute
      RAISING
        zcx_be_error.

    METHODS execute_step
      IMPORTING
        step TYPE step
      RAISING
        zcx_be_error.

    METHODS is_deleted
      IMPORTING
        step          TYPE step
      RETURNING
        VALUE(result) TYPE abap_bool.
ENDCLASS.



CLASS zcl_be_deleter IMPLEMENTATION.

  METHOD get_preview.
    context = NEW zcl_be_change_context( )->prepare( enhancement = to_upper( enhancement )
                                                     transport   = transport
                                                     activity    = zcl_be_change_context=>activity-delete ).
    DATA(entity_name) = to_upper( name ).
    plan_deletion( entity_type = entity_type
                   name        = entity_name ).
    result = VALUE #( enhancement = context-enhancement-bo_name
                      entity_type = entity_type
                      name        = entity_name
                      package     = context-package
                      transport   = context-transport
                      deletes     = get_deletes( )
                      remains     = plan-remains
                      token       = calculate_token( entity_type = entity_type
                                                     name        = entity_name ) ).
  ENDMETHOD.


  METHOD delete.
    IF request-token IS INITIAL.
      zcx_be_error=>raise_token_outdated( ).
    ENDIF.
    context = NEW zcl_be_change_context( )->prepare( enhancement = to_upper( request-enhancement )
                                                     transport   = request-transport
                                                     activity    = zcl_be_change_context=>activity-delete ).
    " The token is checked again under the lock, so nothing can change between check and delete
    /bobf/cl_conf_model_api=>lock_enhancement( EXPORTING iv_enhancement_key = context-enhancement-bo_key
                                               IMPORTING ev_success         = DATA(is_locked)
                                                         ev_user            = DATA(lock_owner) ).
    IF is_locked = abap_false.
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e030(zbe_bopf_enh) WITH context-enhancement-bo_name lock_owner
        EXPORTING status = 409.
    ENDIF.
    DATA(entity_name) = to_upper( request-name ).
    plan_deletion( entity_type = request-entity_type
                   name        = entity_name ).
    IF calculate_token( entity_type = request-entity_type
                        name        = entity_name ) <> request-token.
      zcx_be_error=>raise_token_outdated( ).
    ENDIF.

    execute( ).
    result = VALUE #( operation   = operation
                      enhancement = context-enhancement-bo_name
                      entity_type = request-entity_type
                      name        = entity_name
                      package     = context-package
                      transport   = context-transport
                      deleted     = get_deletes( )
                      remains     = plan-remains ).
  ENDMETHOD.


  METHOD plan_deletion.
    CLEAR plan.
    model = read_model( ).
    add_entity( entity_type = entity_type
                name        = name ).
    SORT plan-steps BY rank ASCENDING depth DESCENDING.
  ENDMETHOD.


  METHOD read_model.
    DATA(key) = context-enhancement-bo_key.
    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key   = key
                                           IMPORTING et_node_tab = result-nodes ).
    /bobf/cl_conf_model_api=>get_action_tab( EXPORTING iv_bo_key     = key
                                             IMPORTING et_action_tab = result-actions ).
    /bobf/cl_conf_model_api=>get_determination_tab( EXPORTING iv_bo_key        = key
                                                    IMPORTING et_determination = result-determinations ).
    /bobf/cl_conf_model_api=>get_validation_tab( EXPORTING iv_bo_key     = key
                                                 IMPORTING et_validation = result-validations ).
    /bobf/cl_conf_model_api=>get_query_tab( EXPORTING iv_bo_key = key
                                            IMPORTING et_query  = result-queries ).
    /bobf/cl_conf_model_api=>get_association_tab( EXPORTING iv_bo_key      = key
                                                  IMPORTING et_association = result-associations ).
    " The configuration API has no reader for alternative keys
    SELECT altkey_name_aie AS name, node_key, data_type, data_table_type AS table_type
      FROM /bobf/obm_altkey
      WHERE name = @context-enhancement-bo_name AND extension = @abap_true
        AND version = @/bobf/if_conf_c=>sc_version_active
      ORDER BY altkey_name_aie
      INTO CORRESPONDING FIELDS OF TABLE @result-alternative_keys ##SUBRC_OK.
  ENDMETHOD.


  METHOD add_entity.
    DATA origin TYPE /bobf/obm_bo_key.
    DATA alternative_key TYPE alternative_key.
    DATA association TYPE /bobf/s_conf_model_api_assoc.
    DATA query TYPE /bobf/s_conf_model_api_query.
    DATA validation TYPE /bobf/s_conf_model_api_val.
    DATA determination TYPE /bobf/s_conf_model_api_det.
    DATA action TYPE /bobf/s_conf_model_api_action.
    DATA node TYPE /bobf/s_conf_model_api_node.

    DATA(key) = context-enhancement-bo_key.
    CASE entity_type.
      WHEN `enhancement`.
        " The name has to confirm which enhancement goes, like for any other entity
        IF name = context-enhancement-bo_name.
          origin = key.
          add_enhancement( ).
        ENDIF.
      WHEN `alternativeKey`.
        alternative_key = VALUE #( model-alternative_keys[ name = name ] OPTIONAL ).
        IF alternative_key IS NOT INITIAL.
          origin = key.
          add_alternative_key( alternative_key ).
        ENDIF.
      WHEN `association`.
        association = VALUE #( model-associations[ assoc_name = name ] OPTIONAL ).
        origin = association-origin_bo_key.
        IF origin = key AND is_modelled_association( association ) = abap_true.
          add_association( association ).
        ENDIF.
      WHEN `query`.
        query = VALUE #( model-queries[ query_name = name ] OPTIONAL ).
        origin = query-origin_bo_key.
        IF origin = key.
          add_query( query ).
        ENDIF.
      WHEN `validation`.
        validation = VALUE #( model-validations[ val_name = name ] OPTIONAL ).
        origin = validation-origin_bo_key.
        IF origin = key.
          add_validation( validation ).
        ENDIF.
      WHEN `determination`.
        determination = VALUE #( model-determinations[ det_name = name ] OPTIONAL ).
        origin = determination-origin_bo_key.
        IF origin = key.
          add_determination( determination ).
        ENDIF.
      WHEN `action` OR `actionEnhancement`.
        action = VALUE #( model-actions[ act_name = name ] OPTIONAL ).
        origin = action-origin_bo_key.
        IF origin = key.
          add_action( action ).
        ENDIF.
      WHEN `node`.
        node = VALUE #( model-nodes[ node_name = name ] OPTIONAL ).
        origin = node-origin_bo_key.
        IF origin = key.
          add_node( node  = node
                    depth = 0 ).
        ENDIF.
      WHEN OTHERS.
        zcx_be_error=>raise_not_allowed( value    = entity_type
                                         property = `entityType` ).
    ENDCASE.

    IF origin IS INITIAL.
      zcx_be_error=>raise_unknown_entity( entity_type     = entity_type
                                          name            = name
                                          business_object = context-enhancement-bo_name ).
    ENDIF.
    IF origin <> key.
      zcx_be_error=>raise_base_entity( entity_type = entity_type
                                       name        = name ).
    ENDIF.
  ENDMETHOD.


  METHOD add_enhancement.
    DATA node TYPE /bobf/s_conf_model_api_node.
    DATA alternative_key TYPE alternative_key.
    DATA association TYPE /bobf/s_conf_model_api_assoc.
    DATA query TYPE /bobf/s_conf_model_api_query.
    DATA validation TYPE /bobf/s_conf_model_api_val.
    DATA determination TYPE /bobf/s_conf_model_api_det.
    DATA action TYPE /bobf/s_conf_model_api_action.

    DATA(key) = context-enhancement-bo_key.
    LOOP AT model-nodes INTO node WHERE origin_bo_key = key AND ( node_type = 'N' OR node_type = 'D' ).
      " Subnodes of own nodes come with their parent
      IF NOT line_exists( model-nodes[ node_key = node-parent_node_key origin_bo_key = key ] ).
        add_node( node  = node
                  depth = 0 ).
      ENDIF.
    ENDLOOP.
    LOOP AT model-alternative_keys INTO alternative_key.
      add_alternative_key( alternative_key ).
    ENDLOOP.
    LOOP AT model-associations INTO association WHERE origin_bo_key = key.
      IF is_modelled_association( association ) = abap_true.
        add_association( association ).
      ENDIF.
    ENDLOOP.
    LOOP AT model-queries INTO query WHERE origin_bo_key = key.
      add_query( query ).
    ENDLOOP.
    LOOP AT model-validations INTO validation WHERE origin_bo_key = key.
      add_validation( validation ).
    ENDLOOP.
    LOOP AT model-determinations INTO determination WHERE origin_bo_key = key.
      add_determination( determination ).
    ENDLOOP.
    LOOP AT model-actions INTO action WHERE origin_bo_key = key.
      add_action( action ).
    ENDLOOP.
    add_step( VALUE #( rank = rank-enhancement
                       type = `enhancement`
                       name = context-enhancement-bo_name
                       key  = key ) ).
    add_entry( EXPORTING type    = `constantsInterface`
                         name    = context-enhancement-const_interface
               CHANGING  entries = plan-generated ).
  ENDMETHOD.


  METHOD add_node.
    DATA child TYPE /bobf/s_conf_model_api_node.
    DATA alternative_key TYPE alternative_key.
    DATA association TYPE /bobf/s_conf_model_api_assoc.
    DATA query TYPE /bobf/s_conf_model_api_query.
    DATA validation TYPE /bobf/s_conf_model_api_val.
    DATA determination TYPE /bobf/s_conf_model_api_det.
    DATA action TYPE /bobf/s_conf_model_api_action.

    DATA(key) = context-enhancement-bo_key.
    " Property and message nodes, compositions and parent associations go with the node itself
    LOOP AT model-nodes INTO child
         WHERE parent_node_key = node-node_key AND origin_bo_key = key AND ( node_type = 'N' OR node_type = 'D' ).
      add_node( node  = child
                depth = depth + 1 ).
    ENDLOOP.
    LOOP AT model-alternative_keys INTO alternative_key WHERE node_key = node-node_key.
      add_alternative_key( alternative_key ).
    ENDLOOP.
    LOOP AT model-associations INTO association
         WHERE origin_bo_key = key AND ( source_node_key = node-node_key OR target_node_key = node-node_key ).
      IF is_modelled_association( association ) = abap_true.
        add_association( association ).
      ENDIF.
    ENDLOOP.
    LOOP AT model-queries INTO query WHERE node_key = node-node_key AND origin_bo_key = key.
      add_query( query ).
    ENDLOOP.
    LOOP AT model-validations INTO validation WHERE node_key = node-node_key AND origin_bo_key = key.
      add_validation( validation ).
    ENDLOOP.
    LOOP AT model-determinations INTO determination WHERE node_key = node-node_key AND origin_bo_key = key.
      add_determination( determination ).
    ENDLOOP.
    LOOP AT model-actions INTO action WHERE node_key = node-node_key AND origin_bo_key = key.
      add_action( action ).
    ENDLOOP.

    check_table_is_empty( CONV #( node-database_table ) ).
    add_step( VALUE #( rank  = rank-node
                       depth = depth
                       type  = `node`
                       name  = node-node_name
                       key   = node-node_key ) ).
    add_generated_objects( node ).
    add_entry( EXPORTING type    = `ddicObject`
                         name    = node-data_data_type
               CHANGING  entries = plan-remains ).
    add_entry( EXPORTING type    = `ddicObject`
                         name    = node-data_data_type_t
               CHANGING  entries = plan-remains ).
  ENDMETHOD.


  METHOD add_generated_objects.
    TYPES ddic_names TYPE RANGE OF ddobjname.

    DATA(generated_objects) = VALUE string_table( ( CONV #( node-data_type ) )
                                                  ( CONV #( node-data_table_type ) )
                                                  ( CONV #( node-database_table ) ) ).
    DELETE generated_objects WHERE table_line IS INITIAL.
    DATA(names) = VALUE ddic_names( FOR object IN generated_objects ( sign = 'I' option = 'EQ' low = object ) ).
    " An empty range would select every DDIC object
    IF names IS INITIAL.
      RETURN.
    ENDIF.
    SELECT tabname FROM dd02l WHERE tabname IN @names AND as4local = 'A'
      ORDER BY tabname
      INTO TABLE @DATA(tables) ##SUBRC_OK.
    SELECT typename FROM dd40l WHERE typename IN @names AND as4local = 'A'
      ORDER BY typename
      INTO TABLE @DATA(table_types) ##SUBRC_OK.
    LOOP AT generated_objects ASSIGNING FIELD-SYMBOL(<generated_object>).
      IF line_exists( tables[ tabname = <generated_object> ] ) OR line_exists( table_types[ typename = <generated_object> ] ).
        add_entry( EXPORTING type    = `ddicObject`
                             name    = <generated_object>
                   CHANGING  entries = plan-generated ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD add_action.
    DATA validation TYPE /bobf/s_conf_model_api_val.

    " Validations of the action go with it
    LOOP AT model-validations INTO validation
         WHERE action_key = action-act_key AND origin_bo_key = context-enhancement-bo_key.
      add_validation( validation ).
    ENDLOOP.
    DATA(is_standard) = xsdbool( action-act_cat = /bobf/if_conf_c=>sc_action_standard ).
    add_step( VALUE #( rank     = COND #( WHEN is_standard = abap_true THEN rank-action ELSE rank-action_enhancement )
                       type     = `action`
                       name     = action-act_name
                       key      = action-act_key
                       category = action-act_cat ) ).
    add_entry( EXPORTING type    = `class`
                         name    = action-act_class
               CHANGING  entries = plan-remains ).
    IF is_standard = abap_true.
      add_entry( EXPORTING type    = `ddicObject`
                           name    = action-param_data_type
                 CHANGING  entries = plan-remains ).
    ENDIF.
  ENDMETHOD.


  METHOD add_determination.
    add_step( VALUE #( rank = rank-determination
                       type = `determination`
                       name = determination-det_name
                       key  = determination-det_key ) ).
    add_entry( EXPORTING type    = `class`
                         name    = determination-det_class
               CHANGING  entries = plan-remains ).
  ENDMETHOD.


  METHOD add_validation.
    " The uniqueness check of alternative keys goes with the last key that needs it
    IF validation-val_class = /bobf/if_conf_def_classes_c=>gc_cl_alt_key
        OR validation-val_class = /bobf/if_conf_def_classes_c=>gc_cl_alt_key_draft.
      RETURN.
    ENDIF.
    add_step( VALUE #( rank     = rank-validation
                       type     = `validation`
                       name     = validation-val_name
                       key      = validation-val_key
                       category = validation-val_cat ) ).
    add_entry( EXPORTING type    = `class`
                         name    = validation-val_class
               CHANGING  entries = plan-remains ).
  ENDMETHOD.


  METHOD add_query.
    add_step( VALUE #( rank = rank-query
                       type = `query`
                       name = query-query_name
                       key  = query-query_key ) ).
    add_entry( EXPORTING type    = `class`
                         name    = query-query_class
               CHANGING  entries = plan-remains ).
  ENDMETHOD.


  METHOD add_association.
    add_step( VALUE #( rank = rank-association
                       type = `association`
                       name = association-assoc_name
                       key  = association-assoc_key ) ).
    add_entry( EXPORTING type    = `class`
                         name    = association-assoc_class
               CHANGING  entries = plan-remains ).
    add_entry( EXPORTING type    = `ddicObject`
                         name    = association-param_data_type
               CHANGING  entries = plan-remains ).
  ENDMETHOD.


  METHOD add_alternative_key.
    add_step( VALUE #( rank = rank-alternative_key
                       type = `alternativeKey`
                       name = alternative_key-name ) ).
    add_entry( EXPORTING type    = `ddicObject`
                         name    = alternative_key-data_type
               CHANGING  entries = plan-remains ).
    add_entry( EXPORTING type    = `ddicObject`
                         name    = alternative_key-table_type
               CHANGING  entries = plan-remains ).
  ENDMETHOD.


  METHOD add_step.
    IF NOT line_exists( plan-steps[ type = step-type name = step-name ] ).
      INSERT step INTO TABLE plan-steps.
    ENDIF.
  ENDMETHOD.


  METHOD add_entry.
    IF name IS NOT INITIAL AND NOT line_exists( entries[ type = type name = name ] ).
      INSERT VALUE #( type = type name = name ) INTO TABLE entries.
    ENDIF.
  ENDMETHOD.


  METHOD is_modelled_association.
    " Compositions and the generated parent and root associations belong to their nodes
    result = xsdbool( association-assoc_type = 'A' AND association-assoc_cat <> 'P' AND association-assoc_cat <> 'R' ).
  ENDMETHOD.


  METHOD check_table_is_empty.
    DATA data_check TYPE sy-subrc.

    IF table IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE @abap_true FROM dd02l
      WHERE tabname = @table AND as4local = 'A' AND tabclass = 'TRANSP'
      INTO @DATA(exists).
    IF exists = abap_false.
      RETURN.
    ENDIF.
    " Deleting the node drops the table with the data of all clients, so the DDIC check across clients decides
    CALL FUNCTION 'DD_EXISTS_DATA'
      EXPORTING
        tabclass  = 'TRANSP'
        tabname   = table
      IMPORTING
        subrc     = data_check
      EXCEPTIONS
        sql_error = 1
        OTHERS    = 2.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e033(zbe_bopf_enh) WITH table EXPORTING status = 409.
    ENDIF.
    " 0: the table contains data, 2: it is empty, 3: it does not exist on the database
    IF data_check = 0.
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e028(zbe_bopf_enh) WITH table EXPORTING status = 409.
    ENDIF.
  ENDMETHOD.


  METHOD get_deletes.
    result = VALUE #( FOR step IN plan-steps ( type = step-type name = step-name ) ).
    INSERT LINES OF plan-generated INTO TABLE result.
  ENDMETHOD.


  METHOD calculate_token.
    DATA(state) = zcl_be_json=>to_json( NEW zcl_be_reader( )->get_enhancement( context-enhancement-bo_name ) ).
    DATA(fingerprint) = |{ sy-uname }/{ entity_type }/{ name }/{ zcl_be_json=>to_json( plan ) }/{ state }|.
    TRY.
        cl_abap_message_digest=>calculate_hash_for_char( EXPORTING if_algorithm  = 'SHA256'
                                                                   if_data       = fingerprint
                                                         IMPORTING ef_hashstring = DATA(hash) ).
      CATCH cx_abap_message_digest INTO DATA(error).
        RAISE EXCEPTION NEW zcx_be_error( previous = error
                                          status   = 500 ).
    ENDTRY.
    result = to_lower( hash ).
  ENDMETHOD.


  METHOD execute.
    DATA(session) = NEW zcl_be_session( package = context-package
                                        request = context-transport ).
    TRY.
        LOOP AT plan-steps ASSIGNING FIELD-SYMBOL(<step>).
          execute_step( <step> ).
          IF is_deleted( <step> ) = abap_false.
            RAISE EXCEPTION TYPE zcx_be_error MESSAGE e029(zbe_bopf_enh) WITH <step>-type <step>-name EXPORTING status = 422.
          ENDIF.
        ENDLOOP.
      CLEANUP.
        session->close( ).
    ENDTRY.
    session->close( ).
  ENDMETHOD.


  METHOD execute_step.
    DATA(key) = context-enhancement-bo_key.
    CASE step-type.
      WHEN `alternativeKey`.
        NEW zcl_be_meta_model( )->delete_alternative_key( bo_key = key
                                                          name   = step-name ).
      WHEN `association`.
        /bobf/cl_conf_model_api=>delete_association( iv_bo_key           = key
                                                     iv_association_key  = step-key
                                                     iv_delete_class     = abap_false
                                                     iv_delete_parameter = abap_false ).
      WHEN `query`.
        /bobf/cl_conf_model_api=>delete_query( iv_bo_key    = key
                                               iv_query_key = step-key ).
      WHEN `validation`.
        IF step-category = /bobf/if_conf_c=>sc_val_cat_action.
          /bobf/cl_conf_model_api=>delete_action_validation( iv_bo_key                = key
                                                             iv_action_validation_key = step-key
                                                             iv_delete_class          = abap_false ).
        ELSE.
          /bobf/cl_conf_model_api=>delete_validation( iv_bo_key         = key
                                                      iv_validation_key = step-key ).
        ENDIF.
      WHEN `determination`.
        /bobf/cl_conf_model_api=>delete_determination( iv_bo_key            = key
                                                       iv_determination_key = step-key ).
      WHEN `action`.
        " Pre and post enhancements have no write nodes, so the API method works for them
        IF step-category = /bobf/if_conf_c=>sc_action_standard.
          NEW zcl_be_meta_model( )->delete_action( bo_key = key
                                                   name   = step-name ).
        ELSE.
          /bobf/cl_conf_model_api=>delete_action( iv_bo_key     = key
                                                  iv_action_key = step-key ).
        ENDIF.
      WHEN `node`.
        /bobf/cl_conf_model_api=>delete_node( iv_bo_key                     = key
                                              iv_node_key                   = step-key
                                              iv_delete_combined_structure  = abap_true
                                              iv_delete_combined_table_type = abap_true
                                              iv_delete_database_table      = abap_true ).
      WHEN `enhancement`.
        /bobf/cl_conf_model_api=>delete_enhancement( iv_enhancement_key            = key
                                                     iv_delete_constants_interface = abap_true ).
    ENDCASE.
  ENDMETHOD.


  METHOD is_deleted.
    DATA business_objects TYPE /bobf/t_conf_model_api_bo.

    IF step-type = `enhancement`.
      /bobf/cl_conf_model_api=>get_bo_tab( IMPORTING et_bo_tab = business_objects ).
      result = xsdbool( NOT line_exists( business_objects[ bo_key = step-key ] ) ).
      RETURN.
    ENDIF.
    DATA(current) = read_model( ).
    result = SWITCH #( step-type
                       WHEN `alternativeKey` THEN xsdbool( NOT line_exists( current-alternative_keys[ name = step-name ] ) )
                       WHEN `association`    THEN xsdbool( NOT line_exists( current-associations[ assoc_key = step-key ] ) )
                       WHEN `query`          THEN xsdbool( NOT line_exists( current-queries[ query_key = step-key ] ) )
                       WHEN `validation`     THEN xsdbool( NOT line_exists( current-validations[ val_key = step-key ] ) )
                       WHEN `determination`  THEN xsdbool( NOT line_exists( current-determinations[ det_key = step-key ] ) )
                       WHEN `action`         THEN xsdbool( NOT line_exists( current-actions[ act_key = step-key ] ) )
                       WHEN `node`           THEN xsdbool( NOT line_exists( current-nodes[ node_key = step-key ] ) ) ).
  ENDMETHOD.

ENDCLASS.
