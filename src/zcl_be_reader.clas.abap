"! Read access to classic BOPF enhancement objects and their base business objects
CLASS zcl_be_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF business_object,
        name                TYPE string,
        description         TYPE string,
        constants_interface TYPE string,
        enhancement_count   TYPE i,
      END OF business_object,
      business_objects TYPE STANDARD TABLE OF business_object WITH EMPTY KEY.

    TYPES:
      BEGIN OF enhancement_header,
        name                 TYPE string,
        base_business_object TYPE string,
        description          TYPE string,
        package              TYPE string,
        original_language    TYPE string,
        constants_interface  TYPE string,
        namespace            TYPE string,
        prefix               TYPE string,
        is_extensible        TYPE abap_bool,
        is_changeable        TYPE abap_bool,
      END OF enhancement_header,
      enhancement_headers TYPE STANDARD TABLE OF enhancement_header WITH EMPTY KEY.

    TYPES:
      BEGIN OF node,
        name                TYPE string,
        parent              TYPE string,
        type                TYPE string,
        is_own              TYPE abap_bool,
        is_extensible       TYPE abap_bool,
        is_transient        TYPE abap_bool,
        data_structure      TYPE string,
        transient_structure TYPE string,
        combined_structure  TYPE string,
        table_type          TYPE string,
        database_table      TYPE string,
        extension_include   TYPE string,
        description         TYPE string,
      END OF node,
      nodes TYPE STANDARD TABLE OF node WITH EMPTY KEY.

    TYPES:
      BEGIN OF action,
        name                TYPE string,
        node                TYPE string,
        category            TYPE string,
        base_action         TYPE string,
        class               TYPE string,
        parameter_structure TYPE string,
        cardinality         TYPE string,
        is_own              TYPE abap_bool,
        is_extensible       TYPE abap_bool,
        description         TYPE string,
      END OF action,
      actions TYPE STANDARD TABLE OF action WITH EMPTY KEY.

    TYPES:
      BEGIN OF determination,
        name        TYPE string,
        node        TYPE string,
        pattern     TYPE string,
        class       TYPE string,
        is_own      TYPE abap_bool,
        description TYPE string,
      END OF determination,
      determinations TYPE STANDARD TABLE OF determination WITH EMPTY KEY.

    TYPES:
      BEGIN OF validation,
        name        TYPE string,
        node        TYPE string,
        category    TYPE string,
        action      TYPE string,
        class       TYPE string,
        impact      TYPE string,
        is_own      TYPE abap_bool,
        description TYPE string,
      END OF validation,
      validations TYPE STANDARD TABLE OF validation WITH EMPTY KEY.

    TYPES:
      BEGIN OF query,
        name           TYPE string,
        node           TYPE string,
        class          TYPE string,
        data_structure TYPE string,
        is_own         TYPE abap_bool,
        description    TYPE string,
      END OF query,
      queries TYPE STANDARD TABLE OF query WITH EMPTY KEY.

    TYPES:
      BEGIN OF association,
        name                   TYPE string,
        source_node            TYPE string,
        target_business_object TYPE string,
        target_node            TYPE string,
        class                  TYPE string,
        cardinality            TYPE string,
        is_own                 TYPE abap_bool,
        description            TYPE string,
      END OF association,
      associations TYPE STANDARD TABLE OF association WITH EMPTY KEY.

    TYPES:
      BEGIN OF alternative_key,
        name       TYPE string,
        node       TYPE string,
        fields     TYPE string_table,
        data_type  TYPE string,
        table_type TYPE string,
        uniqueness TYPE string,
        is_own     TYPE abap_bool,
      END OF alternative_key,
      alternative_keys TYPE STANDARD TABLE OF alternative_key WITH EMPTY KEY.

    TYPES:
      BEGIN OF enhancement,
        header           TYPE enhancement_header,
        nodes            TYPE nodes,
        actions          TYPE actions,
        determinations   TYPE determinations,
        validations      TYPE validations,
        queries          TYPE queries,
        associations     TYPE associations,
        alternative_keys TYPE alternative_keys,
      END OF enhancement.

    CONSTANTS:
      BEGIN OF scope,
        own TYPE string VALUE `own`,
        all TYPE string VALUE `all`,
      END OF scope.

    "! Extensible classic standard business objects that can get enhancements
    METHODS get_business_objects
      RETURNING
        VALUE(result) TYPE business_objects.

    "! Enhancement objects of one business object
    METHODS get_enhancements
      IMPORTING
        base_business_object TYPE csequence
      RETURNING
        VALUE(result)        TYPE enhancement_headers
      RAISING
        zcx_be_error.

    "! One enhancement object; scope own: own entities and the base nodes in short form, all: also the base
    "! entities. A node limits the result to that node and adds its base actions and its full details.
    METHODS get_enhancement
      IMPORTING
        name          TYPE csequence
        scope         TYPE string DEFAULT `own`
        node          TYPE csequence OPTIONAL
      RETURNING
        VALUE(result) TYPE enhancement
      RAISING
        zcx_be_error.

    "! Customer namespace: Z*, Y* or a namespace this system is the producer of
    CLASS-METHODS is_customer_name
      IMPORTING
        name          TYPE csequence
      RETURNING
        VALUE(result) TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF known_node,
        bo_key   TYPE /bobf/obm_bo_key,
        node_key TYPE /bobf/obm_node_key,
        name     TYPE string,
      END OF known_node,
      known_nodes TYPE HASHED TABLE OF known_node WITH UNIQUE KEY bo_key node_key.

    TYPES:
      BEGIN OF directory_entry,
        obj_name   TYPE tadir-obj_name,
        devclass   TYPE tadir-devclass,
        masterlang TYPE tadir-masterlang,
      END OF directory_entry,
      directory_entries TYPE HASHED TABLE OF directory_entry WITH UNIQUE KEY obj_name.

    DATA business_object_list TYPE /bobf/t_conf_model_api_bo.
    DATA node_names TYPE known_nodes.

    METHODS get_business_object_list
      RETURNING
        VALUE(result) TYPE /bobf/t_conf_model_api_bo.

    METHODS find_business_object
      IMPORTING
        name          TYPE csequence
      RETURNING
        VALUE(result) TYPE /bobf/s_conf_model_api_bo
      RAISING
        zcx_be_error.

    METHODS get_directory_entries
      IMPORTING
        business_objects TYPE /bobf/t_conf_model_api_bo
      RETURNING
        VALUE(result)    TYPE directory_entries.

    METHODS to_header
      IMPORTING
        business_object   TYPE /bobf/s_conf_model_api_bo
        directory_entries TYPE directory_entries
      RETURNING
        VALUE(result)     TYPE enhancement_header.

    METHODS get_node_name
      IMPORTING
        bo_key        TYPE /bobf/obm_bo_key
        node_key      TYPE /bobf/obm_node_key
      RETURNING
        VALUE(result) TYPE string.

    METHODS read_nodes
      IMPORTING
        bo_key        TYPE /bobf/obm_bo_key
        node          TYPE string
      RETURNING
        VALUE(result) TYPE nodes.

    METHODS read_actions
      IMPORTING
        bo_key        TYPE /bobf/obm_bo_key
        scope         TYPE string
      RETURNING
        VALUE(result) TYPE actions.

    METHODS read_determinations
      IMPORTING
        bo_key        TYPE /bobf/obm_bo_key
        scope         TYPE string
      RETURNING
        VALUE(result) TYPE determinations.

    METHODS read_validations
      IMPORTING
        bo_key        TYPE /bobf/obm_bo_key
        scope         TYPE string
      RETURNING
        VALUE(result) TYPE validations.

    METHODS read_queries
      IMPORTING
        bo_key        TYPE /bobf/obm_bo_key
        scope         TYPE string
      RETURNING
        VALUE(result) TYPE queries.

    METHODS read_associations
      IMPORTING
        bo_key        TYPE /bobf/obm_bo_key
        scope         TYPE string
      RETURNING
        VALUE(result) TYPE associations.

    METHODS read_alternative_keys
      IMPORTING
        enhancement   TYPE /bobf/s_conf_model_api_bo
      RETURNING
        VALUE(result) TYPE alternative_keys.

    METHODS is_included
      IMPORTING
        origin_bo_key TYPE /bobf/obm_bo_key
        bo_key        TYPE /bobf/obm_bo_key
        scope         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.
ENDCLASS.



CLASS zcl_be_reader IMPLEMENTATION.

  METHOD get_business_objects.
    DATA business_object TYPE REF TO /bobf/s_conf_model_api_bo.
    DATA base_key TYPE /bobf/s_conf_model_api_bo-bo_key.

    DATA(business_objects) = get_business_object_list( ).
    LOOP AT business_objects REFERENCE INTO business_object
         WHERE extension = abap_false AND extensible = abap_true
           AND object_model_generated IS INITIAL AND is_rap_bo IS INITIAL.
      base_key = business_object->bo_key.
      INSERT VALUE #( name                = business_object->bo_name
                      description         = business_object->description
                      constants_interface = business_object->const_interface
                      enhancement_count   = REDUCE i( INIT count = 0
                                                      FOR candidate IN business_objects
                                                      WHERE ( super_bo_key = base_key AND extension = abap_true )
                                                      NEXT count = count + 1 ) )
             INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_enhancements.
    DATA(base) = find_business_object( base_business_object ).
    DATA(enhancements) = VALUE /bobf/t_conf_model_api_bo(
      FOR candidate IN get_business_object_list( )
      WHERE ( super_bo_key = base-bo_key AND extension = abap_true ) ( candidate ) ).
    DATA(directory_entries) = get_directory_entries( enhancements ).
    result = VALUE #( FOR enhancement IN enhancements
                      ( to_header( business_object   = enhancement
                                   directory_entries = directory_entries ) ) ).
  ENDMETHOD.


  METHOD get_enhancement.
    DATA(enhancement) = find_business_object( name ).
    IF enhancement-extension = abap_false.
      zcx_be_error=>raise_unknown_enhancement( name ).
    ENDIF.

    DATA(node_name) = to_upper( node ).
    result-header = to_header( business_object   = enhancement
                               directory_entries = get_directory_entries( VALUE #( ( enhancement ) ) ) ).
    result-nodes = read_nodes( bo_key = enhancement-bo_key
                               node   = node_name ).
    IF node_name IS NOT INITIAL AND result-nodes IS INITIAL.
      zcx_be_error=>raise_unknown_node( node            = node_name
                                        business_object = enhancement-bo_name ).
    ENDIF.
    " Large standard business objects have hundreds of actions; the base actions that action enhancements
    " and action validations refer to come with scope all or with their node
    result-actions = read_actions( bo_key = enhancement-bo_key
                                   scope  = COND #( WHEN node_name IS INITIAL THEN scope ELSE zcl_be_reader=>scope-all ) ).
    result-determinations = read_determinations( bo_key = enhancement-bo_key
                                                 scope  = scope ).
    result-validations = read_validations( bo_key = enhancement-bo_key
                                           scope  = scope ).
    result-queries = read_queries( bo_key = enhancement-bo_key
                                   scope  = scope ).
    result-associations = read_associations( bo_key = enhancement-bo_key
                                             scope  = scope ).
    result-alternative_keys = read_alternative_keys( enhancement ).
    IF node_name IS INITIAL.
      RETURN.
    ENDIF.
    DELETE result-actions WHERE node <> node_name.
    DELETE result-determinations WHERE node <> node_name.
    DELETE result-validations WHERE node <> node_name.
    DELETE result-queries WHERE node <> node_name.
    DELETE result-associations WHERE source_node <> node_name.
    DELETE result-alternative_keys WHERE node <> node_name.
  ENDMETHOD.


  METHOD is_customer_name.
    IF name CP 'Z*' OR name CP 'Y*'.
      result = abap_true.
      RETURN.
    ENDIF.
    IF name NP '/*/*'.
      RETURN.
    ENDIF.
    SPLIT name AT '/' INTO DATA(leading_text) DATA(namespace_name) DATA(remainder) ##NEEDED.
    DATA(namespace) = CONV namespace( |/{ namespace_name }/| ).
    SELECT SINGLE @abap_true FROM trnspace
      WHERE namespace = @namespace AND role = 'P'
      INTO @result.
  ENDMETHOD.


  METHOD get_business_object_list.
    IF business_object_list IS INITIAL.
      /bobf/cl_conf_model_api=>get_bo_tab( IMPORTING et_bo_tab = business_object_list ).
    ENDIF.
    result = business_object_list.
  ENDMETHOD.


  METHOD find_business_object.
    DATA(upper_name) = to_upper( name ).
    DATA(business_objects) = get_business_object_list( ).
    result = VALUE #( business_objects[ bo_name = upper_name ] OPTIONAL ).
    IF result-bo_key IS INITIAL.
      zcx_be_error=>raise_unknown_business_object( name ).
    ENDIF.
  ENDMETHOD.


  METHOD get_directory_entries.
    TYPES object_names TYPE RANGE OF tadir-obj_name.

    DATA(names) = VALUE object_names( FOR business_object IN business_objects
                                      ( sign = 'I' option = 'EQ' low = business_object-bo_name ) ).
    " An empty range would select every directory entry
    IF names IS INITIAL.
      RETURN.
    ENDIF.
    SELECT obj_name, devclass, masterlang FROM tadir
      WHERE pgmid = 'R3TR' AND object = 'BOBX' AND obj_name IN @names
      INTO CORRESPONDING FIELDS OF TABLE @result ##SUBRC_OK.
  ENDMETHOD.


  METHOD to_header.
    DATA(directory_entry) = VALUE #( directory_entries[ obj_name = business_object-bo_name ] OPTIONAL ).
    result = VALUE #( name                 = business_object-bo_name
                      base_business_object = business_object-super_bo_name
                      description          = business_object-description
                      package              = directory_entry-devclass
                      original_language    = directory_entry-masterlang
                      constants_interface  = business_object-const_interface
                      namespace            = business_object-namespace
                      prefix               = business_object-prefix
                      is_extensible        = business_object-extensible
                      is_changeable        = is_customer_name( business_object-bo_name ) ).
  ENDMETHOD.


  METHOD get_node_name.
    DATA nodes TYPE /bobf/t_conf_model_api_node.
    DATA node TYPE REF TO /bobf/s_conf_model_api_node.

    IF NOT line_exists( node_names[ bo_key = bo_key node_key = node_key ] ).
      /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key   = bo_key
                                             IMPORTING et_node_tab = nodes ).
      LOOP AT nodes REFERENCE INTO node.
        INSERT VALUE #( bo_key   = bo_key
                        node_key = node->node_key
                        name     = node->node_name ) INTO TABLE node_names.
        " An enhancement model contains the nodes of its base business object with the same keys; read
        " directly, the base returns no nodes once the enhancement model is loaded
        INSERT VALUE #( bo_key   = node->origin_bo_key
                        node_key = node->node_key
                        name     = node->node_name ) INTO TABLE node_names.
      ENDLOOP.
    ENDIF.
    result = VALUE #( node_names[ bo_key = bo_key node_key = node_key ]-name OPTIONAL ).
  ENDMETHOD.


  METHOD read_nodes.
    DATA model_node TYPE REF TO /bobf/s_conf_model_api_node.
    DATA type TYPE string.
    DATA entry TYPE zcl_be_reader=>node.

    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key   = bo_key
                                           IMPORTING et_node_tab = DATA(nodes) ).
    LOOP AT nodes REFERENCE INTO model_node.
      " Property, message, lock and other framework nodes are not modelled by the user
      type = SWITCH #( model_node->node_type
                       WHEN 'N' THEN `standard`
                       WHEN 'D' THEN `delegated`
                       WHEN 'B' THEN `representation` ).
      IF type IS INITIAL OR ( node IS NOT INITIAL AND model_node->node_name <> node ).
        CONTINUE.
      ENDIF.
      entry = VALUE #( name                = model_node->node_name
                       parent              = get_node_name( bo_key   = bo_key
                                                            node_key = model_node->parent_node_key )
                       type                = type
                       is_own              = xsdbool( model_node->origin_bo_key = bo_key )
                       is_extensible       = model_node->extensible
                       is_transient        = model_node->transient
                       data_structure      = model_node->data_data_type
                       transient_structure = model_node->data_data_type_t
                       combined_structure  = model_node->data_type
                       table_type          = model_node->data_table_type
                       database_table      = model_node->database_table
                       extension_include   = model_node->ext_incl_name
                       description         = model_node->description ).
      " Large standard business objects have hundreds of nodes: the overview keeps base nodes to what new
      " nodes and appends need, a requested node comes in full
      IF entry-is_own = abap_false AND node IS INITIAL.
        CLEAR: entry-is_transient, entry-transient_structure, entry-combined_structure, entry-table_type,
               entry-database_table, entry-description.
      ENDIF.
      INSERT entry INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_actions.
    DATA action TYPE REF TO /bobf/s_conf_model_api_action.
    DATA category TYPE string.

    /bobf/cl_conf_model_api=>get_action_tab( EXPORTING iv_bo_key     = bo_key
                                             IMPORTING et_action_tab = DATA(actions) ).
    LOOP AT actions REFERENCE INTO action.
      " Framework actions (create, update, lock, save ...) are generated by BOPF
      category = SWITCH #( action->act_cat
                           WHEN /bobf/if_conf_c=>sc_action_standard         THEN `standard`
                           WHEN /bobf/if_conf_c=>sc_action_enhancement_pre  THEN `pre`
                           WHEN /bobf/if_conf_c=>sc_action_enhancement_post THEN `post` ).
      IF category IS INITIAL
          OR is_included( origin_bo_key = action->origin_bo_key
                          bo_key        = bo_key
                          scope         = scope ) = abap_false.
        CONTINUE.
      ENDIF.
      INSERT VALUE #( name                = action->act_name
                      node                = action->node_name
                      category            = category
                      base_action         = action->base_action_name
                      class               = action->act_class
                      parameter_structure = action->param_data_type
                      cardinality         = SWITCH #( action->act_cardinality
                                                      WHEN /bobf/if_conf_c=>sc_act_card_many   THEN `many`
                                                      WHEN /bobf/if_conf_c=>sc_act_card_one    THEN `one`
                                                      WHEN /bobf/if_conf_c=>sc_act_card_static THEN `static` )
                      is_own              = xsdbool( action->origin_bo_key = bo_key )
                      is_extensible       = action->extendible
                      description         = action->description ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_determinations.
    DATA determination TYPE REF TO /bobf/s_conf_model_api_det.

    /bobf/cl_conf_model_api=>get_determination_tab( EXPORTING iv_bo_key        = bo_key
                                                    IMPORTING et_determination = DATA(determinations) ).
    LOOP AT determinations REFERENCE INTO determination.
      IF is_included( origin_bo_key = determination->origin_bo_key
                      bo_key        = bo_key
                      scope         = scope ) = abap_false.
        CONTINUE.
      ENDIF.
      INSERT VALUE #( name        = determination->det_name
                      node        = determination->node_name
                      pattern     = SWITCH #( determination->det_pattern
                                              WHEN /bobf/if_conf_c=>sc_detpattern_after_modify    THEN `afterModify`
                                              WHEN /bobf/if_conf_c=>sc_detpattern_before_save     THEN `beforeSave`
                                              WHEN /bobf/if_conf_c=>sc_detpattern_fill_trans_attr THEN `fillTransient`
                                              WHEN /bobf/if_conf_c=>sc_detpattern_create_property THEN `properties`
                                              WHEN /bobf/if_conf_c=>sc_detpattern_set_trans_node  THEN `transientNode`
                                              ELSE determination->det_pattern )
                      class       = determination->det_class
                      is_own      = xsdbool( determination->origin_bo_key = bo_key )
                      description = determination->description ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_validations.
    DATA validation TYPE REF TO /bobf/s_conf_model_api_val.

    /bobf/cl_conf_model_api=>get_validation_tab( EXPORTING iv_bo_key     = bo_key
                                                 IMPORTING et_validation = DATA(validations) ).
    LOOP AT validations REFERENCE INTO validation.
      IF is_included( origin_bo_key = validation->origin_bo_key
                      bo_key        = bo_key
                      scope         = scope ) = abap_false.
        CONTINUE.
      ENDIF.
      INSERT VALUE #( name        = validation->val_name
                      node        = validation->node_name
                      category    = SWITCH #( validation->val_cat
                                              WHEN /bobf/if_conf_c=>sc_val_cat_action THEN `action`
                                              WHEN /bobf/if_conf_c=>sc_val_cat_object THEN `consistency` )
                      action      = validation->action_name
                      class       = validation->val_class
                      impact      = SWITCH #( validation->val_impact
                                              WHEN /bobf/if_conf_c=>sc_val_impact_messages     THEN `messages`
                                              WHEN /bobf/if_conf_c=>sc_val_impact_prevent_save THEN `preventSave`
                                              WHEN /bobf/if_conf_c=>sc_val_impact_set_status   THEN `setStatus` )
                      is_own      = xsdbool( validation->origin_bo_key = bo_key )
                      description = validation->description ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_queries.
    DATA query TYPE REF TO /bobf/s_conf_model_api_query.

    /bobf/cl_conf_model_api=>get_query_tab( EXPORTING iv_bo_key = bo_key
                                            IMPORTING et_query  = DATA(queries) ).
    LOOP AT queries REFERENCE INTO query.
      IF is_included( origin_bo_key = query->origin_bo_key
                      bo_key        = bo_key
                      scope         = scope ) = abap_false.
        CONTINUE.
      ENDIF.
      INSERT VALUE #( name           = query->query_name
                      node           = query->node_name
                      class          = query->query_class
                      data_structure = query->data_type
                      is_own         = xsdbool( query->origin_bo_key = bo_key )
                      description    = query->description ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_associations.
    DATA association TYPE REF TO /bobf/s_conf_model_api_assoc.
    DATA target TYPE /bobf/s_conf_model_api_node.
    DATA target_bo_key TYPE /bobf/s_conf_model_api_node-ref_bo_key.
    DATA target_node_key TYPE /bobf/s_conf_model_api_node-ref_node_key.

    /bobf/cl_conf_model_api=>get_association_tab( EXPORTING iv_bo_key      = bo_key
                                                  IMPORTING et_association = DATA(associations) ).
    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key   = bo_key
                                           IMPORTING et_node_tab = DATA(nodes) ).
    LOOP AT associations REFERENCE INTO association
         WHERE assoc_type = 'A' AND assoc_cat <> 'P' AND assoc_cat <> 'R'.
      IF is_included( origin_bo_key = association->origin_bo_key
                      bo_key        = bo_key
                      scope         = scope ) = abap_false.
        CONTINUE.
      ENDIF.
      " Cross business object associations end in a representation node that refers to the foreign node
      target = VALUE #( nodes[ node_key = association->target_node_key ] OPTIONAL ).
      target_bo_key = COND #( WHEN target-node_type = 'B' THEN target-ref_bo_key
                              WHEN target-node_key IS NOT INITIAL THEN bo_key
                              ELSE association->target_bo_key ).
      target_node_key = COND #( WHEN target-node_type = 'B' THEN target-ref_node_key
                                ELSE association->target_node_key ).
      INSERT VALUE #( name                   = association->assoc_name
                      source_node            = get_node_name( bo_key   = bo_key
                                                              node_key = association->source_node_key )
                      target_business_object = VALUE #( business_object_list[ bo_key = target_bo_key ]-bo_name OPTIONAL )
                      target_node            = get_node_name( bo_key   = target_bo_key
                                                              node_key = target_node_key )
                      class                  = association->assoc_class
                      cardinality            = SWITCH #( association->cardinality
                                                         WHEN /bobf/if_conf_c=>sc_card_zero_to_one THEN `zeroToOne`
                                                         WHEN /bobf/if_conf_c=>sc_card_one         THEN `one`
                                                         WHEN /bobf/if_conf_c=>sc_card_many        THEN `many`
                                                         WHEN /bobf/if_conf_c=>sc_card_one_to_many THEN `oneToMany` )
                      is_own                 = xsdbool( association->origin_bo_key = bo_key )
                      description            = association->description ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_alternative_keys.
    " The configuration API has no reader for alternative keys; they live in the model tables
    SELECT altkey_key, altkey_name_aie, node_key, data_type, data_table_type, not_unique
      FROM /bobf/obm_altkey
      WHERE name = @enhancement-bo_name AND extension = @abap_true
        AND version = @/bobf/if_conf_c=>sc_version_active
      ORDER BY altkey_key
      INTO TABLE @DATA(stored_keys).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    SELECT altkey_key, field_no, field_name
      FROM /bobf/obm_ak_fld
      WHERE name = @enhancement-bo_name AND extension = @abap_true
        AND version = @/bobf/if_conf_c=>sc_version_active
      ORDER BY altkey_key, field_no
      INTO TABLE @DATA(stored_fields) ##SUBRC_OK.

    result = VALUE #( FOR stored_key IN stored_keys
                      ( name       = stored_key-altkey_name_aie
                        node       = get_node_name( bo_key   = enhancement-bo_key
                                                    node_key = stored_key-node_key )
                        fields     = VALUE #( FOR field IN stored_fields
                                              WHERE ( altkey_key = stored_key-altkey_key ) ( CONV #( field-field_name ) ) )
                        data_type  = stored_key-data_type
                        table_type = stored_key-data_table_type
                        uniqueness = SWITCH #( stored_key-not_unique
                                               WHEN /bobf/if_conf_c=>sc_altkey_unique             THEN `unique`
                                               WHEN /bobf/if_conf_c=>sc_altkey_non_unique         THEN `notUnique`
                                               WHEN /bobf/if_conf_c=>sc_altkey_unique_if_not_init THEN `uniqueIfNotInitial`
                                               WHEN /bobf/if_conf_c=>sc_altkey_unique_internal    THEN `uniqueInternal`
                                               ELSE stored_key-not_unique )
                        is_own     = abap_true ) ).
  ENDMETHOD.


  METHOD is_included.
    result = xsdbool( origin_bo_key = bo_key OR scope = zcl_be_reader=>scope-all ).
  ENDMETHOD.

ENDCLASS.

