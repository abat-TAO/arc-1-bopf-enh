"! Write access to classic BOPF enhancement objects through /BOBF/CL_CONF_MODEL_API.
"! One request is one change: checked first, then written, then read back.
CLASS zcl_be_writer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF trigger,
        node        TYPE string,
        association TYPE string,
        on_create   TYPE abap_bool,
        on_update   TYPE abap_bool,
        on_delete   TYPE abap_bool,
      END OF trigger,
      triggers TYPE STANDARD TABLE OF trigger WITH EMPTY KEY.

    TYPES:
      BEGIN OF write_node,
        node        TYPE string,
        association TYPE string,
      END OF write_node,
      write_nodes TYPE STANDARD TABLE OF write_node WITH EMPTY KEY.

    " Request of every POST operation; deletes and maintenance use the same structure
    TYPES:
      BEGIN OF request,
        operation              TYPE string,
        enhancement            TYPE string,
        entity_type            TYPE string,
        base_business_object   TYPE string,
        name                   TYPE string,
        description            TYPE string,
        node                   TYPE string,
        base_action            TYPE string,
        timing                 TYPE string,
        action                 TYPE string,
        class                  TYPE string,
        constants_interface    TYPE string,
        parameter_structure    TYPE string,
        cardinality            TYPE string,
        pattern                TYPE string,
        impact                 TYPE string,
        triggers               TYPE triggers,
        write_nodes            TYPE write_nodes,
        data_structure         TYPE string,
        transient_structure    TYPE string,
        database_table         TYPE string,
        combined_structure     TYPE string,
        combined_table_type    TYPE string,
        is_transient           TYPE abap_bool,
        is_extensible          TYPE abap_bool,
        target_business_object TYPE string,
        target_node            TYPE string,
        fields                 TYPE string_table,
        data_type              TYPE string,
        table_type             TYPE string,
        uniqueness             TYPE string,
        uniqueness_check       TYPE string,
        token                  TYPE string,
        package                TYPE string,
        transport              TYPE string,
        language               TYPE string,
        dry_run                TYPE abap_bool,
      END OF request.

    TYPES:
      "! Object that BOPF generates for a change: class, constantsInterface, combinedStructure,
      "! combinedTableType or databaseTable
      BEGIN OF generated_object,
        type TYPE string,
        name TYPE string,
      END OF generated_object,
      generated_objects TYPE STANDARD TABLE OF generated_object WITH EMPTY KEY.

    TYPES:
      BEGIN OF result,
        operation       TYPE string,
        enhancement     TYPE string,
        entity_type     TYPE string,
        entity          TYPE string,
        class           TYPE string,
        generated       TYPE generated_objects,
        package         TYPE string,
        transport       TYPE string,
        language        TYPE string,
        dry_run         TYPE abap_bool,
        already_existed TYPE abap_bool,
        unchanged       TYPE abap_bool,
      END OF result.

    CONSTANTS:
      BEGIN OF operation,
        create_enhancement        TYPE string VALUE `createEnhancement`,
        update_enhancement        TYPE string VALUE `updateEnhancement`,
        create_action             TYPE string VALUE `createAction`,
        create_action_enhancement TYPE string VALUE `createActionEnhancement`,
        create_determination      TYPE string VALUE `createDetermination`,
        create_validation         TYPE string VALUE `createValidation`,
        create_action_validation  TYPE string VALUE `createActionValidation`,
        create_node               TYPE string VALUE `createNode`,
        create_query              TYPE string VALUE `createQuery`,
        create_association        TYPE string VALUE `createAssociation`,
        create_alternative_key    TYPE string VALUE `createAlternativeKey`,
        update_action             TYPE string VALUE `updateAction`,
        update_determination      TYPE string VALUE `updateDetermination`,
        update_validation         TYPE string VALUE `updateValidation`,
        update_node               TYPE string VALUE `updateNode`,
        update_query              TYPE string VALUE `updateQuery`,
      END OF operation.

    TYPES:
      "! Names SAP proposes for a create operation, named like the request parameters: the objects BOPF
      "! generates and the DDIC objects the caller creates beforehand
      BEGIN OF names,
        operation           TYPE string,
        name                TYPE string,
        class               TYPE string,
        constants_interface TYPE string,
        parameter_structure TYPE string,
        data_structure      TYPE string,
        transient_structure TYPE string,
        combined_structure  TYPE string,
        combined_table_type TYPE string,
        database_table      TYPE string,
        hints               TYPE string_table,
      END OF names.

    "! Only reads; nothing is checked or created
    METHODS get_names
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE names
      RAISING
        zcx_be_error.

    METHODS write
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES change_context TYPE zcl_be_change_context=>context.
    TYPES object_types TYPE RANGE OF trobjtype.

    "! Parameters every operation needs, checked before any lookup so that a missing one is reported as such
    METHODS check_required_parameters
      IMPORTING
        request TYPE request
      RAISING
        zcx_be_error.

    "! Implementation class SAP proposes for a new entity of a create operation
    METHODS propose_class
      IMPORTING
        context          TYPE change_context
        create_operation TYPE string
        node_key         TYPE /bobf/obm_node_key
        name             TYPE string
      RETURNING
        VALUE(result)    TYPE seoclsname.

    "! Names SAP proposes for a new action: its class and the parameter structure the developer creates
    METHODS get_action_names
      IMPORTING
        bo_key        TYPE /bobf/obm_bo_key
        node_key      TYPE /bobf/obm_node_key
        name          TYPE string
      RETURNING
        VALUE(result) TYPE names.

    "! Names SAP proposes for a new node, with a hint when its database table name cannot be generated
    METHODS get_node_names
      IMPORTING
        bo_key        TYPE /bobf/obm_bo_key
        name          TYPE string
      RETURNING
        VALUE(result) TYPE names.

    "! The class as generated object, unless it exists already and is reused
    METHODS get_generated_class
      IMPORTING
        class         TYPE seoclsname
      RETURNING
        VALUE(result) TYPE generated_objects.

    "! Name the caller chose for an object BOPF generates. It must not exist yet, because the generation
    "! would overwrite it.
    METHODS check_new_name
      IMPORTING
        name         TYPE string
        object_types TYPE object_types
        property     TYPE string
      RAISING
        zcx_be_error.

    METHODS normalize
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE request.

    METHODS create_enhancement
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

    METHODS update_enhancement
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

    METHODS create_action
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

    METHODS create_action_enhancement
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

    METHODS create_determination
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

    METHODS create_validation
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

    METHODS create_action_validation
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

    METHODS create_node
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

    METHODS create_query
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

    METHODS create_association
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

    METHODS create_alternative_key
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

    METHODS update_entity
      IMPORTING
        request       TYPE request
        entity_type   TYPE string
      RETURNING
        VALUE(result) TYPE result
      RAISING
        zcx_be_error.

    METHODS update_action
      IMPORTING
        request TYPE request
        context TYPE change_context
      CHANGING
        result  TYPE result
      RAISING
        zcx_be_error.

    METHODS update_determination
      IMPORTING
        request TYPE request
        context TYPE change_context
      CHANGING
        result  TYPE result
      RAISING
        zcx_be_error.

    METHODS update_validation
      IMPORTING
        request TYPE request
        context TYPE change_context
      CHANGING
        result  TYPE result
      RAISING
        zcx_be_error.

    METHODS update_node
      IMPORTING
        request TYPE request
        context TYPE change_context
      CHANGING
        result  TYPE result
      RAISING
        zcx_be_error.

    METHODS update_query
      IMPORTING
        request TYPE request
        context TYPE change_context
      CHANGING
        result  TYPE result
      RAISING
        zcx_be_error.

    METHODS prepare_change
      IMPORTING
        request       TYPE request
      RETURNING
        VALUE(result) TYPE change_context
      RAISING
        zcx_be_error.

    METHODS start_result
      IMPORTING
        request       TYPE request
        context       TYPE change_context
        entity_type   TYPE string
      RETURNING
        VALUE(result) TYPE result.

    METHODS find_node
      IMPORTING
        context       TYPE change_context
        name          TYPE string
      RETURNING
        VALUE(result) TYPE /bobf/s_conf_model_api_node
      RAISING
        zcx_be_error.

    "! Node that the enhancement may add entities to: own nodes and extensible standard nodes
    METHODS find_usable_node
      IMPORTING
        context       TYPE change_context
        name          TYPE string
      RETURNING
        VALUE(result) TYPE /bobf/s_conf_model_api_node
      RAISING
        zcx_be_error.

    METHODS find_standard_action
      IMPORTING
        context       TYPE change_context
        name          TYPE string
      RETURNING
        VALUE(result) TYPE /bobf/s_conf_model_api_action
      RAISING
        zcx_be_error.

    "! Association from one node to another: the requested one, otherwise TO_PARENT, the composition
    "! or TO_ROOT, in this order
    METHODS find_association
      IMPORTING
        context       TYPE change_context
        source        TYPE /bobf/s_conf_model_api_node
        target        TYPE /bobf/s_conf_model_api_node
        requested     TYPE string
        is_required   TYPE abap_bool
        property      TYPE string
      RETURNING
        VALUE(result) TYPE /bobf/obm_assoc_key
      RAISING
        zcx_be_error.

    "! Only entities of the enhancement itself can be changed
    METHODS check_own_entity
      IMPORTING
        context     TYPE change_context
        entity_type TYPE string
        name        TYPE string
        exists      TYPE abap_bool
        origin      TYPE /bobf/obm_bo_key
      RAISING
        zcx_be_error.

    "! Checks a new implementation class; true if it does not exist yet and has to be generated
    METHODS check_class
      IMPORTING
        current       TYPE seoclsname
        target        TYPE seoclsname
      RETURNING
        VALUE(result) TYPE abap_bool
      RAISING
        zcx_be_error.

    "! The requested database table, otherwise SAP's proposal. SAP cuts its proposal to 16 characters,
    "! which can leave a name ending in an underscore; generating such a table fails and leaves DDIC behind.
    METHODS check_database_table
      IMPORTING
        requested     TYPE string
        proposed      TYPE csequence
      RETURNING
        VALUE(result) TYPE tabname16
      RAISING
        zcx_be_error.

    METHODS get_request_nodes
      IMPORTING
        request       TYPE request
        context       TYPE change_context
        node          TYPE /bobf/s_conf_model_api_node
      RETURNING
        VALUE(result) TYPE /bobf/t_conf_model_api_request
      RAISING
        zcx_be_error.

    METHODS get_write_nodes
      IMPORTING
        request       TYPE request
        context       TYPE change_context
        node          TYPE /bobf/s_conf_model_api_node
      RETURNING
        VALUE(result) TYPE /bobf/t_conf_model_api_write
      RAISING
        zcx_be_error.

    "! Triggers as the read methods return them, in the form the update methods expect
    METHODS to_request_nodes
      IMPORTING
        triggers      TYPE /bobf/t_conf_model_api_reque_c
      RETURNING
        VALUE(result) TYPE /bobf/t_conf_model_api_request.

    METHODS check_name
      IMPORTING
        name     TYPE string
        valid    TYPE boole_d
        messages TYPE REF TO /bobf/if_frw_message
      RAISING
        zcx_be_error.

    "! Package of an existing enhancement object
    METHODS get_package
      IMPORTING
        enhancement   TYPE csequence
      RETURNING
        VALUE(result) TYPE devclass.

    METHODS check_ddic_object
      IMPORTING
        name        TYPE string
        object_type TYPE tbatgobj
      RAISING
        zcx_be_error.

    METHODS raise_not_saved_if
      IMPORTING
        is_missing  TYPE abap_bool
        entity_type TYPE string
        name        TYPE string
      RAISING
        zcx_be_error.
ENDCLASS.



CLASS zcl_be_writer IMPLEMENTATION.

  METHOD get_names.
    DATA context TYPE change_context.
    DATA node_key TYPE /bobf/obm_node_key.
    DATA constants_interface TYPE seoclsname.

    " Like every operation, start from a clean BOPF transaction, see write
    /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( )->cleanup( ).
    DATA(normalized) = normalize( request ).
    IF normalized-name IS INITIAL.
      zcx_be_error=>raise_missing_parameter( `name` ).
    ENDIF.
    " A new enhancement needs only its name; entities need the node the create operation puts them on
    CASE normalized-operation.
      WHEN operation-create_enhancement.
        /bobf/cl_conf_model_api=>propose_enhancement_names( EXPORTING iv_name               = CONV #( normalized-name )
                                                            IMPORTING ev_constant_interface = constants_interface ).
        result = VALUE #( operation           = normalized-operation
                          name                = normalized-name
                          constants_interface = constants_interface ).
        RETURN.
      WHEN operation-create_node OR operation-create_action OR operation-create_determination
          OR operation-create_validation OR operation-create_association.
        context-enhancement = NEW zcl_be_change_context( )->find_enhancement( normalized-enhancement ).
        node_key = find_usable_node( context = context
                                     name    = normalized-node )-node_key.
      WHEN operation-create_action_enhancement.
        context-enhancement = NEW zcl_be_change_context( )->find_enhancement( normalized-enhancement ).
        node_key = find_standard_action( context = context
                                         name    = normalized-base_action )-node_key.
      WHEN operation-create_action_validation.
        context-enhancement = NEW zcl_be_change_context( )->find_enhancement( normalized-enhancement ).
        node_key = find_standard_action( context = context
                                         name    = normalized-action )-node_key.
      WHEN OTHERS.
        zcx_be_error=>raise_not_allowed( value    = normalized-operation
                                         property = `operation` ).
    ENDCASE.

    CASE normalized-operation.
      WHEN operation-create_node.
        result = get_node_names( bo_key = context-enhancement-bo_key
                                 name   = normalized-name ).
      WHEN operation-create_action.
        result = get_action_names( bo_key   = context-enhancement-bo_key
                                   node_key = node_key
                                   name     = normalized-name ).
      WHEN OTHERS.
        result-class = propose_class( context          = context
                                      create_operation = normalized-operation
                                      node_key         = node_key
                                      name             = normalized-name ).
    ENDCASE.
    result-operation = normalized-operation.
    result-name = normalized-name.
  ENDMETHOD.


  METHOD write.
    " SAP's name checks roll back and leave the BOPF buffers of the session behind; a clean transaction
    " makes several operations in one ABAP session behave like separate HTTP requests
    /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( )->cleanup( ).
    DATA(normalized) = normalize( request ).
    check_required_parameters( normalized ).
    CASE normalized-operation.
      WHEN operation-create_enhancement.
        result = create_enhancement( normalized ).
      WHEN operation-update_enhancement.
        result = update_enhancement( normalized ).
      WHEN operation-create_action.
        result = create_action( normalized ).
      WHEN operation-create_action_enhancement.
        result = create_action_enhancement( normalized ).
      WHEN operation-create_determination.
        result = create_determination( normalized ).
      WHEN operation-create_validation.
        result = create_validation( normalized ).
      WHEN operation-create_action_validation.
        result = create_action_validation( normalized ).
      WHEN operation-create_node.
        result = create_node( normalized ).
      WHEN operation-create_query.
        result = create_query( normalized ).
      WHEN operation-create_association.
        result = create_association( normalized ).
      WHEN operation-create_alternative_key.
        result = create_alternative_key( normalized ).
      WHEN operation-update_action.
        result = update_entity( request     = normalized
                                entity_type = `action` ).
      WHEN operation-update_determination.
        result = update_entity( request     = normalized
                                entity_type = `determination` ).
      WHEN operation-update_validation.
        result = update_entity( request     = normalized
                                entity_type = `validation` ).
      WHEN operation-update_node.
        result = update_entity( request     = normalized
                                entity_type = `node` ).
      WHEN operation-update_query.
        result = update_entity( request     = normalized
                                entity_type = `query` ).
      WHEN OTHERS.
        RAISE EXCEPTION TYPE zcx_be_error MESSAGE e007(zbe_bopf_enh) WITH request-operation EXPORTING status = 400.
    ENDCASE.
  ENDMETHOD.


  METHOD normalize.
    " BOPF and DDIC names are upper case; the agent may send any case
    result = request.
    result-enhancement = to_upper( request-enhancement ).
    result-base_business_object = to_upper( request-base_business_object ).
    result-name = to_upper( request-name ).
    result-node = to_upper( request-node ).
    result-base_action = to_upper( request-base_action ).
    result-action = to_upper( request-action ).
    result-class = to_upper( request-class ).
    result-constants_interface = to_upper( request-constants_interface ).
    result-combined_structure = to_upper( request-combined_structure ).
    result-combined_table_type = to_upper( request-combined_table_type ).
    result-parameter_structure = to_upper( request-parameter_structure ).
    result-data_structure = to_upper( request-data_structure ).
    result-transient_structure = to_upper( request-transient_structure ).
    result-database_table = to_upper( request-database_table ).
    result-target_business_object = to_upper( request-target_business_object ).
    result-target_node = to_upper( request-target_node ).
    result-data_type = to_upper( request-data_type ).
    result-table_type = to_upper( request-table_type ).
    result-package = to_upper( request-package ).
    result-transport = to_upper( request-transport ).
    result-write_nodes = VALUE #( FOR write_node IN request-write_nodes
                                  ( node        = to_upper( write_node-node )
                                    association = to_upper( write_node-association ) ) ).
    result-fields = VALUE #( FOR field IN request-fields ( to_upper( field ) ) ).
    result-triggers = VALUE #( FOR trigger IN request-triggers
                               ( VALUE #( BASE trigger node        = to_upper( trigger-node )
                                                       association = to_upper( trigger-association ) ) ) ).
  ENDMETHOD.


  METHOD create_enhancement.
    DATA(rules) = NEW zcl_be_change_context( ).
    DATA(base) = rules->find_business_object( request-base_business_object ).
    IF base-extensible = abap_false OR base-object_model_generated IS NOT INITIAL OR base-is_rap_bo IS NOT INITIAL.
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e009(zbe_bopf_enh) WITH request-base_business_object EXPORTING status = 422.
    ENDIF.
    IF zcl_be_reader=>is_customer_name( request-name ) = abap_false.
      zcx_be_error=>raise_not_customer_name( request-name ).
    ENDIF.

    result = VALUE #( operation   = request-operation
                      enhancement = request-name
                      entity_type = `enhancement`
                      entity      = request-name
                      dry_run     = request-dry_run ).

    /bobf/cl_conf_model_api=>get_bo_tab( IMPORTING et_bo_tab = DATA(business_objects) ).
    DATA(existing) = VALUE #( business_objects[ bo_name = request-name ] OPTIONAL ).
    IF existing-bo_key IS NOT INITIAL.
      IF existing-extension = abap_true AND existing-super_bo_key = base-bo_key.
        result-already_existed = abap_true.
        result-class = existing-const_interface.
        " The enhancement stays in its package, which may differ from the requested one
        result-package = get_package( request-name ).
        RETURN.
      ENDIF.
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e015(zbe_bopf_enh) WITH request-name existing-super_bo_name
        EXPORTING status = 409.
    ENDIF.

    IF request-package IS INITIAL.
      zcx_be_error=>raise_missing_parameter( `package` ).
    ENDIF.
    DATA(package) = CONV devclass( request-package ).
    SELECT SINGLE @abap_true FROM tdevc WHERE devclass = @package INTO @DATA(package_exists).
    IF package_exists = abap_false.
      zcx_be_error=>raise_not_allowed( value    = request-package
                                       property = `package` ).
    ENDIF.
    rules->check_authority( package  = package
                            name     = request-name
                            activity = zcl_be_change_context=>activity-create ).
    result-package = package.
    result-transport = rules->resolve_transport( package     = package
                                                 object_name = request-name
                                                 requested   = request-transport ).
    result-language = rules->resolve_language( requested = request-language
                                               fallback  = sy-langu ).
    DATA(constants_interface) = CONV seoclsname( request-constants_interface ).
    IF constants_interface IS INITIAL.
      /bobf/cl_conf_model_api=>propose_enhancement_names( EXPORTING iv_name               = CONV #( request-name )
                                                          IMPORTING ev_constant_interface = constants_interface ).
    ELSE.
      check_new_name( name         = request-constants_interface
                      object_types = VALUE #( sign = 'I' option = 'EQ' ( low = 'CLAS' ) ( low = 'INTF' ) )
                      property     = `constantsInterface` ).
    ENDIF.
    result-class = constants_interface.
    result-generated = VALUE #( ( type = `constantsInterface` name = constants_interface ) ).
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    DATA(session) = NEW zcl_be_session( package  = package
                                        request  = CONV #( result-transport )
                                        language = CONV #( result-language ) ).
    /bobf/cl_conf_model_api=>create_enhancement( iv_enhancement_name   = CONV #( request-name )
                                                 iv_super_bo_key       = base-bo_key
                                                 iv_description        = CONV #( request-description )
                                                 iv_constant_interface = constants_interface
                                                 iv_extensible         = request-is_extensible ).
    session->close( ).

    " The API ignores rejected saves, so only the persisted model counts
    /bobf/cl_conf_model_api=>get_bo_tab( IMPORTING et_bo_tab = business_objects ).
    raise_not_saved_if( is_missing  = xsdbool( NOT line_exists( business_objects[ bo_name = request-name extension = abap_true ] ) )
                        entity_type = `enhancement`
                        name        = request-name ).
  ENDMETHOD.


  METHOD update_enhancement.
    DATA(context) = prepare_change( request ).
    result = start_result( request     = request
                           context     = context
                           entity_type = `enhancement` ).
    result-entity = request-enhancement.
    IF request-description IS INITIAL.
      zcx_be_error=>raise_missing_parameter( `description` ).
    ENDIF.
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    DATA(session) = NEW zcl_be_session( package  = context-package
                                        request  = context-transport
                                        language = context-language ).
    /bobf/cl_conf_model_api=>update_enhancement( EXPORTING iv_bo_key              = context-enhancement-bo_key
                                                           iv_description         = CONV #( request-description )
                                                           iv_constants_interface = context-enhancement-const_interface
                                                           iv_extensible          = context-enhancement-extensible
                                                 IMPORTING ev_success             = DATA(updated) ).
    session->close( ).

    SELECT SINGLE description FROM /bobf/obm_objt
      WHERE name = @context-enhancement-bo_name AND extension = @abap_true AND langu = @context-language
        AND version = @/bobf/if_conf_c=>sc_version_active
      INTO @DATA(stored_description).
    raise_not_saved_if( is_missing  = xsdbool( sy-subrc <> 0 OR updated = abap_false
                                               OR stored_description <> request-description )
                        entity_type = `enhancement`
                        name        = request-enhancement ).
  ENDMETHOD.


  METHOD create_action.
    DATA(context) = prepare_change( request ).
    DATA(node) = find_usable_node( context = context
                                   name    = request-node ).
    result = start_result( request     = request
                           context     = context
                           entity_type = `action` ).
    DATA(key) = context-enhancement-bo_key.

    /bobf/cl_conf_model_api=>get_action_tab( EXPORTING iv_bo_key     = key
                                             IMPORTING et_action_tab = DATA(actions) ).
    DATA(existing) = VALUE #( actions[ act_name = request-name ] OPTIONAL ).
    IF existing-act_key IS NOT INITIAL.
      result-already_existed = abap_true.
      result-class = existing-act_class.
      RETURN.
    ENDIF.

    /bobf/cl_conf_model_api=>check_action_name( EXPORTING iv_bo_key      = key
                                                          iv_node_key    = node-node_key
                                                          iv_action_name = CONV #( request-name )
                                                IMPORTING eo_message     = DATA(name_messages)
                                                          ev_valid       = DATA(is_valid) ).
    check_name( name     = request-name
                valid    = is_valid
                messages = name_messages ).
    DATA(cardinality) = SWITCH /bobf/conf_act_cardinality( request-cardinality
                                                            WHEN `` OR `many` THEN /bobf/if_conf_c=>sc_act_card_many
                                                            WHEN `one`        THEN /bobf/if_conf_c=>sc_act_card_one
                                                            WHEN `static`     THEN /bobf/if_conf_c=>sc_act_card_static
                                                            ELSE '?' ).
    IF cardinality = '?'.
      zcx_be_error=>raise_not_allowed( value    = request-cardinality
                                       property = `cardinality` ).
    ENDIF.
    IF request-parameter_structure IS NOT INITIAL.
      check_ddic_object( name        = request-parameter_structure
                         object_type = 'TABL' ).
    ENDIF.
    DATA(class) = COND seoclsname( WHEN request-class IS NOT INITIAL THEN request-class
                                   ELSE propose_class( context          = context
                                                       create_operation = request-operation
                                                       node_key         = node-node_key
                                                       name             = request-name ) ).
    result-class = class.
    result-generated = get_generated_class( class ).
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    DATA(session) = NEW zcl_be_session( package  = context-package
                                        request  = context-transport
                                        language = context-language ).
    /bobf/cl_conf_model_api=>create_action( iv_bo_key              = key
                                            iv_node_key            = node-node_key
                                            iv_name                = CONV #( request-name )
                                            iv_description         = CONV #( request-description )
                                            iv_class               = class
                                            iv_category            = /bobf/if_conf_c=>sc_action_standard
                                            iv_parameter_structure = CONV #( request-parameter_structure )
                                            iv_cardinality         = cardinality
                                            iv_create_class        = abap_true ).
    session->close( ).

    /bobf/cl_conf_model_api=>get_action_tab( EXPORTING iv_bo_key     = key
                                             IMPORTING et_action_tab = actions ).
    raise_not_saved_if( is_missing  = xsdbool( NOT line_exists( actions[ act_name = request-name ] ) )
                        entity_type = `action`
                        name        = request-name ).
  ENDMETHOD.


  METHOD create_action_enhancement.
    DATA existing TYPE REF TO /bobf/s_conf_model_api_action.

    DATA(context) = prepare_change( request ).
    DATA(base_action) = find_standard_action( context = context
                                              name    = request-base_action ).
    result = start_result( request     = request
                           context     = context
                           entity_type = `actionEnhancement` ).
    DATA(key) = context-enhancement-bo_key.

    DATA(category) = SWITCH /bobf/act_cat( request-timing
                                           WHEN `pre`  THEN /bobf/if_conf_c=>sc_action_enhancement_pre
                                           WHEN `post` THEN /bobf/if_conf_c=>sc_action_enhancement_post ).
    IF category IS INITIAL.
      zcx_be_error=>raise_not_allowed( value    = request-timing
                                       property = `timing` ).
    ENDIF.
    IF base_action-origin_bo_key = key OR base_action-extendible = abap_false.
      zcx_be_error=>raise_action_not_extensible( request-base_action ).
    ENDIF.

    " BOPF allows one pre and one post enhancement per base action and enhancement object
    /bobf/cl_conf_model_api=>get_action_tab( EXPORTING iv_bo_key     = key
                                             IMPORTING et_action_tab = DATA(actions) ).
    LOOP AT actions REFERENCE INTO existing
         WHERE base_action_key = base_action-act_key AND act_cat = category AND origin_bo_key = key.
      IF existing->act_name <> request-name.
        RAISE EXCEPTION TYPE zcx_be_error MESSAGE e022(zbe_bopf_enh) WITH request-timing request-base_action existing->act_name
          EXPORTING status = 409.
      ENDIF.
      result-already_existed = abap_true.
      result-class = existing->act_class.
      RETURN.
    ENDLOOP.

    /bobf/cl_conf_model_api=>check_action_name( EXPORTING iv_bo_key      = key
                                                          iv_node_key    = base_action-node_key
                                                          iv_action_name = CONV #( request-name )
                                                IMPORTING eo_message     = DATA(name_messages)
                                                          ev_valid       = DATA(is_valid) ).
    check_name( name     = request-name
                valid    = is_valid
                messages = name_messages ).
    DATA(class) = COND seoclsname( WHEN request-class IS NOT INITIAL THEN request-class
                                   ELSE propose_class( context          = context
                                                       create_operation = request-operation
                                                       node_key         = base_action-node_key
                                                       name             = request-name ) ).
    result-class = class.
    result-generated = get_generated_class( class ).
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    DATA(session) = NEW zcl_be_session( package  = context-package
                                        request  = context-transport
                                        language = context-language ).
    /bobf/cl_conf_model_api=>create_action( iv_bo_key          = key
                                            iv_node_key        = base_action-node_key
                                            iv_name            = CONV #( request-name )
                                            iv_description     = CONV #( request-description )
                                            iv_class           = class
                                            iv_base_action_key = base_action-act_key
                                            iv_category        = category
                                            iv_create_class    = abap_true ).
    session->close( ).

    /bobf/cl_conf_model_api=>get_action_tab( EXPORTING iv_bo_key     = key
                                             IMPORTING et_action_tab = actions ).
    raise_not_saved_if( is_missing  = xsdbool( NOT line_exists( actions[ act_name = request-name ] ) )
                        entity_type = `actionEnhancement`
                        name        = request-name ).
  ENDMETHOD.


  METHOD create_determination.
    DATA(context) = prepare_change( request ).
    DATA(node) = find_usable_node( context = context
                                   name    = request-node ).
    result = start_result( request     = request
                           context     = context
                           entity_type = `determination` ).
    DATA(key) = context-enhancement-bo_key.

    /bobf/cl_conf_model_api=>get_determination_tab( EXPORTING iv_bo_key        = key
                                                    IMPORTING et_determination = DATA(determinations) ).
    DATA(existing) = VALUE #( determinations[ det_name = request-name ] OPTIONAL ).
    IF existing-det_key IS NOT INITIAL.
      result-already_existed = abap_true.
      result-class = existing-det_class.
      RETURN.
    ENDIF.

    IF request-pattern <> `` AND request-pattern <> `afterModify` AND request-pattern <> `beforeSave`.
      zcx_be_error=>raise_not_allowed( value    = request-pattern
                                       property = `pattern` ).
    ENDIF.
    DATA(request_nodes) = get_request_nodes( request = request
                                             context = context
                                             node    = node ).
    DATA(write_nodes) = get_write_nodes( request = request
                                         context = context
                                         node    = node ).

    /bobf/cl_conf_model_api=>check_determination_name( EXPORTING iv_bo_key             = key
                                                                 iv_node_key           = node-node_key
                                                                 iv_determination_name = CONV #( request-name )
                                                       IMPORTING eo_message            = DATA(name_messages)
                                                                 ev_valid              = DATA(is_valid) ).
    check_name( name     = request-name
                valid    = is_valid
                messages = name_messages ).
    DATA(class) = COND seoclsname( WHEN request-class IS NOT INITIAL THEN request-class
                                   ELSE propose_class( context          = context
                                                       create_operation = request-operation
                                                       node_key         = node-node_key
                                                       name             = request-name ) ).
    result-class = class.
    result-generated = get_generated_class( class ).
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    DATA(session) = NEW zcl_be_session( package  = context-package
                                        request  = context-transport
                                        language = context-language ).
    IF request-pattern = `beforeSave`.
      /bobf/cl_conf_model_api=>create_det_before_save( iv_bo_key        = key
                                                       iv_node_key      = node-node_key
                                                       iv_name          = CONV #( request-name )
                                                       iv_description   = CONV #( request-description )
                                                       iv_class         = class
                                                       iv_create_class  = abap_true
                                                       it_request_nodes = request_nodes
                                                       it_write_nodes   = write_nodes ).
    ELSE.
      /bobf/cl_conf_model_api=>create_det_after_modify( iv_bo_key        = key
                                                        iv_node_key      = node-node_key
                                                        iv_name          = CONV #( request-name )
                                                        iv_description   = CONV #( request-description )
                                                        iv_class         = class
                                                        iv_create_class  = abap_true
                                                        it_request_nodes = request_nodes
                                                        it_write_nodes   = write_nodes ).
    ENDIF.
    session->close( ).

    /bobf/cl_conf_model_api=>get_determination_tab( EXPORTING iv_bo_key        = key
                                                    IMPORTING et_determination = determinations ).
    raise_not_saved_if( is_missing  = xsdbool( NOT line_exists( determinations[ det_name = request-name ] ) )
                        entity_type = `determination`
                        name        = request-name ).
  ENDMETHOD.


  METHOD create_validation.
    DATA(context) = prepare_change( request ).
    DATA(node) = find_usable_node( context = context
                                   name    = request-node ).
    result = start_result( request     = request
                           context     = context
                           entity_type = `validation` ).
    DATA(key) = context-enhancement-bo_key.

    /bobf/cl_conf_model_api=>get_validation_tab( EXPORTING iv_bo_key     = key
                                                 IMPORTING et_validation = DATA(validations) ).
    DATA(existing) = VALUE #( validations[ val_name = request-name ] OPTIONAL ).
    IF existing-val_key IS NOT INITIAL.
      result-already_existed = abap_true.
      result-class = existing-val_class.
      RETURN.
    ENDIF.

    DATA(impact) = SWITCH /bobf/conf_validation_impact( request-impact
                                                         WHEN `` OR `messages` THEN /bobf/if_conf_c=>sc_val_impact_messages
                                                         WHEN `preventSave`    THEN /bobf/if_conf_c=>sc_val_impact_prevent_save
                                                         ELSE '?' ).
    IF impact = '?'.
      zcx_be_error=>raise_not_allowed( value    = request-impact
                                       property = `impact` ).
    ENDIF.
    DATA(request_nodes) = get_request_nodes( request = request
                                             context = context
                                             node    = node ).

    /bobf/cl_conf_model_api=>check_validation_name( EXPORTING iv_bo_key          = key
                                                              iv_node_key        = node-node_key
                                                              iv_validation_name = CONV #( request-name )
                                                    IMPORTING eo_message         = DATA(name_messages)
                                                              ev_valid           = DATA(is_valid) ).
    check_name( name     = request-name
                valid    = is_valid
                messages = name_messages ).
    DATA(class) = COND seoclsname( WHEN request-class IS NOT INITIAL THEN request-class
                                   ELSE propose_class( context          = context
                                                       create_operation = request-operation
                                                       node_key         = node-node_key
                                                       name             = request-name ) ).
    result-class = class.
    result-generated = get_generated_class( class ).
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    DATA(session) = NEW zcl_be_session( package  = context-package
                                        request  = context-transport
                                        language = context-language ).
    /bobf/cl_conf_model_api=>create_validation( iv_bo_key       = key
                                                iv_node_key     = node-node_key
                                                iv_name         = CONV #( request-name )
                                                iv_class        = class
                                                iv_description  = CONV #( request-description )
                                                iv_create_class = abap_true
                                                it_request_node = request_nodes
                                                iv_impact       = impact ).
    session->close( ).

    /bobf/cl_conf_model_api=>get_validation_tab( EXPORTING iv_bo_key     = key
                                                 IMPORTING et_validation = validations ).
    raise_not_saved_if( is_missing  = xsdbool( NOT line_exists( validations[ val_name = request-name ] ) )
                        entity_type = `validation`
                        name        = request-name ).
  ENDMETHOD.


  METHOD create_action_validation.
    DATA(context) = prepare_change( request ).
    DATA(action) = find_standard_action( context = context
                                         name    = request-action ).
    result = start_result( request     = request
                           context     = context
                           entity_type = `actionValidation` ).
    DATA(key) = context-enhancement-bo_key.
    IF action-origin_bo_key <> key AND action-extendible = abap_false.
      zcx_be_error=>raise_action_not_extensible( request-action ).
    ENDIF.

    /bobf/cl_conf_model_api=>get_validation_tab( EXPORTING iv_bo_key     = key
                                                 IMPORTING et_validation = DATA(validations) ).
    DATA(existing) = VALUE #( validations[ val_name = request-name ] OPTIONAL ).
    IF existing-val_key IS NOT INITIAL.
      result-already_existed = abap_true.
      result-class = existing-val_class.
      RETURN.
    ENDIF.

    /bobf/cl_conf_model_api=>check_validation_name( EXPORTING iv_bo_key          = key
                                                              iv_node_key        = action-node_key
                                                              iv_validation_name = CONV #( request-name )
                                                    IMPORTING eo_message         = DATA(name_messages)
                                                              ev_valid           = DATA(is_valid) ).
    check_name( name     = request-name
                valid    = is_valid
                messages = name_messages ).
    DATA(class) = COND seoclsname( WHEN request-class IS NOT INITIAL THEN request-class
                                   ELSE propose_class( context          = context
                                                       create_operation = request-operation
                                                       node_key         = action-node_key
                                                       name             = request-name ) ).
    result-class = class.
    result-generated = get_generated_class( class ).
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    DATA(session) = NEW zcl_be_session( package  = context-package
                                        request  = context-transport
                                        language = context-language ).
    /bobf/cl_conf_model_api=>create_action_validation( iv_bo_key       = key
                                                       iv_action_key   = action-act_key
                                                       iv_name         = CONV #( request-name )
                                                       iv_class        = class
                                                       iv_description  = CONV #( request-description )
                                                       iv_create_class = abap_true ).
    session->close( ).

    /bobf/cl_conf_model_api=>get_validation_tab( EXPORTING iv_bo_key     = key
                                                 IMPORTING et_validation = validations ).
    raise_not_saved_if( is_missing  = xsdbool( NOT line_exists( validations[ val_name = request-name ] ) )
                        entity_type = `actionValidation`
                        name        = request-name ).
  ENDMETHOD.


  METHOD create_node.
    DATA(context) = prepare_change( request ).
    DATA(parent) = find_usable_node( context = context
                                     name    = request-node ).
    result = start_result( request     = request
                           context     = context
                           entity_type = `node` ).
    DATA(key) = context-enhancement-bo_key.

    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key   = key
                                           IMPORTING et_node_tab = DATA(nodes) ).
    IF line_exists( nodes[ node_name = request-name ] ).
      result-already_existed = abap_true.
      RETURN.
    ENDIF.

    " Extensible subnodes need extension includes, which this API does not create yet
    IF request-is_extensible = abap_true.
      zcx_be_error=>raise_not_allowed( value    = `true`
                                       property = `isExtensible` ).
    ENDIF.
    IF request-is_transient = abap_false.
      IF request-data_structure IS INITIAL.
        zcx_be_error=>raise_missing_parameter( `dataStructure` ).
      ENDIF.
      check_ddic_object( name        = request-data_structure
                         object_type = 'TABL' ).
    ENDIF.
    IF request-transient_structure IS NOT INITIAL.
      check_ddic_object( name        = request-transient_structure
                         object_type = 'TABL' ).
    ENDIF.

    /bobf/cl_conf_model_api=>check_node_name( EXPORTING iv_bo_key    = key
                                                        iv_node_name = CONV #( request-name )
                                              IMPORTING eo_message   = DATA(name_messages)
                                                        ev_valid     = DATA(is_valid) ).
    check_name( name     = request-name
                valid    = is_valid
                messages = name_messages ).

    " Checked before the dry run returns, so that nothing is generated with a name that cannot work
    DATA(names) = get_node_names( bo_key = key
                                  name   = request-name ).
    DATA(ddic_types) = VALUE object_types( sign = 'I' option = 'EQ' ( low = 'TABL' ) ( low = 'TTYP' ) ( low = 'DTEL' ) ).
    IF request-combined_structure IS NOT INITIAL.
      check_new_name( name         = request-combined_structure
                      object_types = ddic_types
                      property     = `combinedStructure` ).
      names-combined_structure = request-combined_structure.
    ENDIF.
    IF request-combined_table_type IS NOT INITIAL.
      check_new_name( name         = request-combined_table_type
                      object_types = ddic_types
                      property     = `combinedTableType` ).
      names-combined_table_type = request-combined_table_type.
    ENDIF.
    DATA(database_table) = COND tabname16( WHEN request-is_transient = abap_false
                                           THEN check_database_table( requested = request-database_table
                                                                      proposed  = names-database_table ) ).
    " Structure, table type and database table share one DDIC namespace, so their names must differ
    DATA(duplicate) = COND string(
      WHEN names-combined_structure = names-combined_table_type
        THEN names-combined_structure
      WHEN database_table IS NOT INITIAL AND database_table = names-combined_structure
        THEN names-combined_structure
      WHEN database_table IS NOT INITIAL AND database_table = names-combined_table_type
        THEN names-combined_table_type ).
    IF duplicate IS NOT INITIAL.
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e035(zbe_bopf_enh) WITH duplicate EXPORTING status = 422.
    ENDIF.
    result-class = names-combined_structure.
    result-generated = VALUE #( ( type = `combinedStructure` name = names-combined_structure )
                                ( type = `combinedTableType` name = names-combined_table_type ) ).
    IF database_table IS NOT INITIAL.
      INSERT VALUE #( type = `databaseTable` name = database_table ) INTO TABLE result-generated.
    ENDIF.
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    DATA(session) = NEW zcl_be_session( package  = context-package
                                        request  = context-transport
                                        language = context-language ).
    /bobf/cl_conf_model_api=>create_node( iv_bo_key           = key
                                          iv_parent_node_key  = parent-node_key
                                          iv_node_name        = CONV #( request-name )
                                          iv_description      = CONV #( request-description )
                                          iv_transient        = request-is_transient
                                          iv_data_type        = CONV #( names-combined_structure )
                                          iv_data_data_type   = CONV #( request-data_structure )
                                          iv_data_data_type_t = CONV #( request-transient_structure )
                                          iv_data_table_type  = CONV #( names-combined_table_type )
                                          iv_database_table   = database_table
                                          iv_gen_database     = xsdbool( request-is_transient = abap_false ) ).
    session->close( ).

    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key   = key
                                           IMPORTING et_node_tab = nodes ).
    raise_not_saved_if( is_missing  = xsdbool( NOT line_exists( nodes[ node_name = request-name ] ) )
                        entity_type = `node`
                        name        = request-name ).
  ENDMETHOD.


  METHOD create_query.
    DATA(context) = prepare_change( request ).
    DATA(node) = find_usable_node( context = context
                                   name    = request-node ).
    result = start_result( request     = request
                           context     = context
                           entity_type = `query` ).
    DATA(key) = context-enhancement-bo_key.

    /bobf/cl_conf_model_api=>get_query_tab( EXPORTING iv_bo_key = key
                                            IMPORTING et_query  = DATA(queries) ).
    IF line_exists( queries[ query_name = request-name ] ).
      result-already_existed = abap_true.
      RETURN.
    ENDIF.

    /bobf/cl_conf_model_api=>check_query_name( EXPORTING iv_bo_key     = key
                                                         iv_node_key   = node-node_key
                                                         iv_query_name = CONV #( request-name )
                                               IMPORTING eo_message    = DATA(name_messages)
                                                         ev_valid      = DATA(is_valid) ).
    check_name( name     = request-name
                valid    = is_valid
                messages = name_messages ).
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    " Select-by-elements query, created the way the BOPF wizard /BOBF/CONF_WZD_QRY_C does it
    DATA(session) = NEW zcl_be_session( package  = context-package
                                        request  = context-transport
                                        language = context-language ).
    /bobf/cl_conf_model_api=>create_query( iv_bo_key        = key
                                           iv_name          = CONV #( request-name )
                                           iv_node_key      = node-node_key
                                           iv_class         = ''
                                           iv_description   = CONV #( request-description )
                                           iv_data_type     = node-data_type
                                           iv_result_type   = ''
                                           iv_result_type_t = ''
                                           iv_create_class  = abap_false ).
    session->close( ).

    /bobf/cl_conf_model_api=>get_query_tab( EXPORTING iv_bo_key = key
                                            IMPORTING et_query  = queries ).
    raise_not_saved_if( is_missing  = xsdbool( NOT line_exists( queries[ query_name = request-name ] ) )
                        entity_type = `query`
                        name        = request-name ).
  ENDMETHOD.


  METHOD create_association.
    DATA(context) = prepare_change( request ).
    DATA(source) = find_usable_node( context = context
                                     name    = request-node ).
    result = start_result( request     = request
                           context     = context
                           entity_type = `association` ).
    DATA(key) = context-enhancement-bo_key.

    /bobf/cl_conf_model_api=>get_association_tab( EXPORTING iv_bo_key      = key
                                                  IMPORTING et_association = DATA(associations) ).
    DATA(existing) = VALUE #( associations[ assoc_name = request-name ] OPTIONAL ).
    IF existing-assoc_key IS NOT INITIAL.
      result-already_existed = abap_true.
      result-class = existing-assoc_class.
      RETURN.
    ENDIF.

    IF request-target_business_object IS INITIAL.
      zcx_be_error=>raise_missing_parameter( `targetBusinessObject` ).
    ENDIF.
    /bobf/cl_conf_model_api=>get_target_bos_for_assoc( EXPORTING iv_bo_key    = key
                                                       IMPORTING et_target_bo = DATA(target_business_objects) ).
    DATA(target) = VALUE #( target_business_objects[ bo_name = request-target_business_object ] OPTIONAL ).
    IF target-bo_key IS INITIAL.
      zcx_be_error=>raise_not_allowed( value    = request-target_business_object
                                       property = `targetBusinessObject` ).
    ENDIF.
    " The target nodes have to be read before the SAP name check below: it rolls back, and afterwards
    " the nodes of other business objects can no longer be read in this session.
    " The base business object as target references other instances of it, like ASSIGNED_FUS of
    " /SCMTMS/TOR. Its nodes are part of the enhancement model with the same keys; read directly, the
    " base returns no nodes once the enhancement model is loaded.
    DATA(is_base_target) = xsdbool( target-bo_key = context-enhancement-super_bo_key ).
    DATA(target_node_name) = COND string( WHEN request-target_node IS INITIAL THEN `ROOT` ELSE request-target_node ).
    /bobf/cl_conf_model_api=>get_node_tab(
      EXPORTING iv_bo_key   = COND #( WHEN is_base_target = abap_true THEN key ELSE target-bo_key )
      IMPORTING et_node_tab = DATA(target_nodes) ).
    IF is_base_target = abap_true.
      DELETE target_nodes WHERE origin_bo_key = key.
    ENDIF.
    DATA(target_node) = VALUE #( target_nodes[ node_name = target_node_name ] OPTIONAL ).
    IF target_node-node_key IS INITIAL.
      zcx_be_error=>raise_unknown_node( node            = target_node_name
                                        business_object = request-target_business_object ).
    ENDIF.
    DATA(cardinality) = SWITCH /bobf/obm_cardinality( request-cardinality
                                                       WHEN `` OR `many` THEN /bobf/if_conf_c=>sc_card_many
                                                       WHEN `zeroToOne`  THEN /bobf/if_conf_c=>sc_card_zero_to_one
                                                       WHEN `one`        THEN /bobf/if_conf_c=>sc_card_one
                                                       WHEN `oneToMany`  THEN /bobf/if_conf_c=>sc_card_one_to_many ).
    IF cardinality IS INITIAL.
      zcx_be_error=>raise_not_allowed( value    = request-cardinality
                                       property = `cardinality` ).
    ENDIF.

    /bobf/cl_conf_model_api=>check_association_name( EXPORTING iv_bo_key           = key
                                                               iv_node_key         = source-node_key
                                                               iv_association_name = CONV #( request-name )
                                                     IMPORTING eo_message          = DATA(name_messages)
                                                               ev_valid            = DATA(is_valid) ).
    check_name( name     = request-name
                valid    = is_valid
                messages = name_messages ).
    DATA(class) = COND seoclsname( WHEN request-class IS NOT INITIAL THEN request-class
                                   ELSE propose_class( context          = context
                                                       create_operation = request-operation
                                                       node_key         = source-node_key
                                                       name             = request-name ) ).
    result-class = class.
    result-generated = get_generated_class( class ).
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    DATA(session) = NEW zcl_be_session( package  = context-package
                                        request  = context-transport
                                        language = context-language ).
    /bobf/cl_conf_model_api=>create_association( iv_bo_key              = key
                                                 iv_node_key            = source-node_key
                                                 iv_association_name    = CONV #( request-name )
                                                 iv_description         = CONV #( request-description )
                                                 iv_class_name          = class
                                                 iv_target_bo_key       = target-bo_key
                                                 iv_target_node_key     = target_node-node_key
                                                 iv_parameter_structure = CONV #( request-parameter_structure )
                                                 iv_cardinality         = cardinality
                                                 iv_create_class        = abap_true ).
    session->close( ).

    /bobf/cl_conf_model_api=>get_association_tab( EXPORTING iv_bo_key      = key
                                                  IMPORTING et_association = associations ).
    raise_not_saved_if( is_missing  = xsdbool( NOT line_exists( associations[ assoc_name = request-name ] ) )
                        entity_type = `association`
                        name        = request-name ).
  ENDMETHOD.


  METHOD create_alternative_key.
    DATA(context) = prepare_change( request ).
    DATA(node) = find_usable_node( context = context
                                   name    = request-node ).
    result = start_result( request     = request
                           context     = context
                           entity_type = `alternativeKey` ).

    SELECT SINGLE @abap_true FROM /bobf/obm_altkey
      WHERE name = @context-enhancement-bo_name AND extension = @abap_true AND altkey_name_aie = @request-name
      INTO @DATA(exists).
    IF exists = abap_true.
      result-already_existed = abap_true.
      RETURN.
    ENDIF.

    DATA(uniqueness) = SWITCH /bobf/obm_altkey_not_unique( request-uniqueness
                                                           WHEN `` OR `notUnique`    THEN /bobf/if_conf_c=>sc_altkey_non_unique
                                                           WHEN `unique`             THEN /bobf/if_conf_c=>sc_altkey_unique
                                                           WHEN `uniqueIfNotInitial` THEN /bobf/if_conf_c=>sc_altkey_unique_if_not_init
                                                           ELSE '?' ).
    IF uniqueness = '?'.
      zcx_be_error=>raise_not_allowed( value    = request-uniqueness
                                       property = `uniqueness` ).
    ENDIF.
    " Unique keys are checked before save unless requested otherwise; non-unique keys need no check
    DATA(uniqueness_check) = COND /bobf/obm_altkey_uniq_check(
      WHEN uniqueness = /bobf/if_conf_c=>sc_altkey_non_unique AND ( request-uniqueness_check = `` OR request-uniqueness_check = `none` )
        THEN /bobf/if_conf_c=>sc_altkey_uniqcheck_no_check
      WHEN uniqueness = /bobf/if_conf_c=>sc_altkey_non_unique
        THEN '?'
      WHEN request-uniqueness_check = `` OR request-uniqueness_check = `beforeSave`
        THEN /bobf/if_conf_c=>sc_altkey_uniqcheck_before_sav
      WHEN request-uniqueness_check = `afterModify`
        THEN /bobf/if_conf_c=>sc_altkey_uniqcheck_after_mod
      WHEN request-uniqueness_check = `none`
        THEN /bobf/if_conf_c=>sc_altkey_uniqcheck_no_check
      ELSE '?' ).
    IF uniqueness_check = '?'.
      zcx_be_error=>raise_not_allowed( value    = request-uniqueness_check
                                       property = `uniquenessCheck` ).
    ENDIF.
    IF request-fields IS INITIAL.
      zcx_be_error=>raise_missing_parameter( `fields` ).
    ENDIF.
    IF request-data_type IS INITIAL OR request-table_type IS INITIAL.
      zcx_be_error=>raise_missing_parameter( `dataType, tableType` ).
    ENDIF.
    check_ddic_object( name        = request-data_type
                       object_type = COND #( WHEN lines( request-fields ) = 1 THEN 'DTEL' ELSE 'TABL' ) ).
    check_ddic_object( name        = request-table_type
                       object_type = 'TTYP' ).
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    DATA(session) = NEW zcl_be_session( package  = context-package
                                        request  = context-transport
                                        language = context-language ).
    TRY.
        NEW zcl_be_meta_model( )->create_alternative_key(
          bo_key            = context-enhancement-bo_key
          node              = node
          alternative_key   = VALUE #( altkey_name      = request-name
                                       data_type        = request-data_type
                                       data_table_type  = request-table_type
                                       uniqueness       = uniqueness
                                       uniqueness_check = uniqueness_check
                                       field_names      = request-fields
                                       description      = request-description )
          smart_validations = context-enhancement-smart_validations ).
      CLEANUP.
        session->close( ).
    ENDTRY.
    session->close( ).
  ENDMETHOD.


  METHOD prepare_change.
    result = NEW zcl_be_change_context( )->prepare( enhancement = request-enhancement
                                                    transport   = request-transport
                                                    language    = request-language
                                                    activity    = zcl_be_change_context=>activity-change ).
  ENDMETHOD.


  METHOD start_result.
    result = VALUE #( operation   = request-operation
                      enhancement = request-enhancement
                      entity_type = entity_type
                      entity      = request-name
                      package     = context-package
                      transport   = context-transport
                      language    = context-language
                      dry_run     = request-dry_run ).
  ENDMETHOD.


  METHOD find_usable_node.
    result = find_node( context = context
                        name    = name ).
    " The configuration API itself does not check extensibility; only the BOPF UIs do
    IF result-origin_bo_key <> context-enhancement-bo_key AND result-extensible = abap_false.
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e011(zbe_bopf_enh) WITH name EXPORTING status = 422.
    ENDIF.
  ENDMETHOD.


  METHOD find_standard_action.
    IF name IS INITIAL.
      zcx_be_error=>raise_missing_parameter( `action` ).
    ENDIF.
    /bobf/cl_conf_model_api=>get_action_tab( EXPORTING iv_bo_key     = context-enhancement-bo_key
                                             IMPORTING et_action_tab = DATA(actions) ).
    result = VALUE #( actions[ act_name = name act_cat = /bobf/if_conf_c=>sc_action_standard ] OPTIONAL ).
    IF result-act_key IS INITIAL.
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e012(zbe_bopf_enh) WITH name context-enhancement-bo_name
        EXPORTING status = 404.
    ENDIF.
  ENDMETHOD.


  METHOD get_request_nodes.
    DATA trigger_node TYPE /bobf/s_conf_model_api_node.

    IF request-triggers IS INITIAL.
      result = VALUE #( ( request_node_key = node-node_key trigger_create = abap_true trigger_update = abap_true ) ).
      RETURN.
    ENDIF.
    " A trigger on another node needs the association from that node to the node of the entity
    LOOP AT request-triggers ASSIGNING FIELD-SYMBOL(<trigger>).
      trigger_node = COND #( WHEN <trigger>-node IS INITIAL OR <trigger>-node = node-node_name THEN node
                             ELSE find_node( context = context
                                             name    = <trigger>-node ) ).
      INSERT VALUE #( request_node_key = trigger_node-node_key
                      assoc_key        = find_association( context     = context
                                                           source      = trigger_node
                                                           target      = node
                                                           requested   = <trigger>-association
                                                           is_required = abap_true
                                                           property    = `triggers` )
                      trigger_create   = <trigger>-on_create
                      trigger_update   = <trigger>-on_update
                      trigger_delete   = <trigger>-on_delete ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD check_name.
    IF valid = abap_true.
      RETURN.
    ENDIF.
    " The T100 placeholder cuts SAP's reason at 50 characters; the full text follows as previous
    DATA(first_error) = zcx_be_error=>get_first_error( messages ).
    DATA(reason) = COND string( WHEN first_error IS BOUND THEN first_error->get_text( ) ).
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e014(zbe_bopf_enh) WITH name reason
      EXPORTING status   = 422
                previous = first_error.
  ENDMETHOD.


  METHOD check_ddic_object.
    DATA is_valid TYPE abap_bool.

    " The BOPF check only knows structures, tables and table types
    IF object_type = 'DTEL'.
      SELECT SINGLE @abap_true FROM dd04l
        WHERE rollname = @( CONV rollname( name ) ) AND as4local = 'A'
        INTO @is_valid.
    ELSE.
      /bobf/cl_conf_model_api=>check_ddic_name( EXPORTING iv_ddic_name        = CONV #( name )
                                                          iv_object_type      = object_type
                                                          iv_check_existence  = abap_true
                                                          iv_check_activation = abap_true
                                                IMPORTING ev_valid            = is_valid ).
    ENDIF.
    IF is_valid = abap_false.
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e023(zbe_bopf_enh) WITH name EXPORTING status = 422.
    ENDIF.
  ENDMETHOD.


  METHOD raise_not_saved_if.
    IF is_missing = abap_true.
      zcx_be_error=>raise_not_saved( entity_type = entity_type
                                     name        = name ).
    ENDIF.
  ENDMETHOD.


  METHOD update_entity.
    DATA(context) = prepare_change( request ).
    result = start_result( request     = request
                           context     = context
                           entity_type = entity_type ).
    " Current values are read in the text language, so texts that are not changed are written back unchanged
    DATA(session) = NEW zcl_be_session( package  = context-package
                                        request  = context-transport
                                        language = context-language ).
    TRY.
        CASE request-operation.
          WHEN operation-update_action.
            update_action( EXPORTING request = request
                                     context = context
                           CHANGING  result  = result ).
          WHEN operation-update_determination.
            update_determination( EXPORTING request = request
                                            context = context
                                  CHANGING  result  = result ).
          WHEN operation-update_validation.
            update_validation( EXPORTING request = request
                                         context = context
                               CHANGING  result  = result ).
          WHEN operation-update_node.
            update_node( EXPORTING request = request
                                   context = context
                         CHANGING  result  = result ).
          WHEN operation-update_query.
            update_query( EXPORTING request = request
                                    context = context
                          CHANGING  result  = result ).
        ENDCASE.
      CLEANUP.
        session->close( ).
    ENDTRY.
    session->close( ).
  ENDMETHOD.


  METHOD update_action.
    DATA(key) = context-enhancement-bo_key.
    /bobf/cl_conf_model_api=>get_action_tab( EXPORTING iv_bo_key     = key
                                             IMPORTING et_action_tab = DATA(actions) ).
    DATA(current) = VALUE #( actions[ act_name = request-name ] OPTIONAL ).
    check_own_entity( context     = context
                      entity_type = `action`
                      name        = request-name
                      exists      = xsdbool( current-act_key IS NOT INITIAL )
                      origin      = current-origin_bo_key ).

    DATA(target) = current.
    IF request-description IS NOT INITIAL.
      target-description = request-description.
    ENDIF.
    IF request-class IS NOT INITIAL.
      target-act_class = request-class.
    ENDIF.
    IF current-act_cat = /bobf/if_conf_c=>sc_action_standard.
      IF request-parameter_structure IS NOT INITIAL.
        check_ddic_object( name        = request-parameter_structure
                           object_type = 'TABL' ).
        target-param_data_type = request-parameter_structure.
      ENDIF.
      IF request-cardinality IS NOT INITIAL.
        target-act_cardinality = SWITCH #( request-cardinality
                                           WHEN `many`   THEN /bobf/if_conf_c=>sc_act_card_many
                                           WHEN `one`    THEN /bobf/if_conf_c=>sc_act_card_one
                                           WHEN `static` THEN /bobf/if_conf_c=>sc_act_card_static
                                           ELSE '?' ).
        IF target-act_cardinality = '?'.
          zcx_be_error=>raise_not_allowed( value    = request-cardinality
                                           property = `cardinality` ).
        ENDIF.
      ENDIF.
    ELSEIF request-parameter_structure IS NOT INITIAL OR request-cardinality IS NOT INITIAL.
      " Pre and post enhancements always take both from their base action
      zcx_be_error=>raise_not_allowed( value    = request-name
                                       property = `parameterStructure, cardinality` ).
    ENDIF.
    DATA(create_class) = check_class( current = current-act_class
                                      target  = target-act_class ).
    result-class = target-act_class.
    IF create_class = abap_true.
      result-generated = VALUE #( ( type = `class` name = target-act_class ) ).
    ENDIF.
    IF target-description = current-description AND target-act_class = current-act_class
        AND target-param_data_type = current-param_data_type AND target-act_cardinality = current-act_cardinality.
      result-unchanged = abap_true.
      RETURN.
    ENDIF.
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    /bobf/cl_conf_model_api=>update_action( iv_bo_key              = key
                                            iv_action_key          = current-act_key
                                            iv_name                = current-act_name
                                            iv_description         = target-description
                                            iv_class               = target-act_class
                                            iv_parameter_structure = target-param_data_type
                                            iv_cardinality         = target-act_cardinality
                                            iv_create_class        = create_class
                                            iv_is_extendible       = current-extendible ).
    /bobf/cl_conf_model_api=>get_action( EXPORTING iv_bo_key     = key
                                                   iv_action_key = current-act_key
                                         IMPORTING es_action     = DATA(stored) ).
    raise_not_saved_if( is_missing  = xsdbool( stored-description <> target-description
                                               OR stored-act_class <> target-act_class
                                               OR stored-param_data_type <> target-param_data_type
                                               OR stored-act_cardinality <> target-act_cardinality )
                        entity_type = `action`
                        name        = request-name ).
  ENDMETHOD.


  METHOD update_determination.
    DATA(key) = context-enhancement-bo_key.
    /bobf/cl_conf_model_api=>get_determination_tab( EXPORTING iv_bo_key        = key
                                                    IMPORTING et_determination = DATA(determinations) ).
    DATA(current) = VALUE #( determinations[ det_name = request-name ] OPTIONAL ).
    check_own_entity( context     = context
                      entity_type = `determination`
                      name        = request-name
                      exists      = xsdbool( current-det_key IS NOT INITIAL )
                      origin      = current-origin_bo_key ).

    " Other patterns have their own API methods; switching the pattern needs delete and create
    DATA(current_pattern) = SWITCH string( current-det_pattern
                                           WHEN /bobf/if_conf_c=>sc_detpattern_after_modify THEN `afterModify`
                                           WHEN /bobf/if_conf_c=>sc_detpattern_before_save  THEN `beforeSave` ).
    IF current_pattern IS INITIAL OR ( request-pattern IS NOT INITIAL AND request-pattern <> current_pattern ).
      zcx_be_error=>raise_not_allowed( value    = request-pattern
                                       property = `pattern` ).
    ENDIF.

    DATA(target) = current.
    IF request-description IS NOT INITIAL.
      target-description = request-description.
    ENDIF.
    IF request-class IS NOT INITIAL.
      target-det_class = request-class.
    ENDIF.
    DATA(node) = VALUE /bobf/s_conf_model_api_node( node_key = current-node_key node_name = current-node_name ).
    DATA(current_triggers) = to_request_nodes( current-request_node ).
    DATA(triggers) = current_triggers.
    IF request-triggers IS NOT INITIAL.
      triggers = get_request_nodes( request = request
                                    context = context
                                    node    = node ).
    ENDIF.
    DATA(current_write_nodes) = VALUE /bobf/t_conf_model_api_write( FOR write_node IN current-write_node
                                                                    ( write_node_key = write_node-node_key
                                                                      assoc_key      = write_node-assoc_key ) ).
    DATA(write_nodes) = current_write_nodes.
    IF request-write_nodes IS NOT INITIAL.
      write_nodes = get_write_nodes( request = request
                                     context = context
                                     node    = node ).
    ENDIF.
    DATA(create_class) = check_class( current = current-det_class
                                      target  = target-det_class ).
    result-class = target-det_class.
    IF target-description = current-description AND target-det_class = current-det_class
        AND triggers = current_triggers AND write_nodes = current_write_nodes.
      result-unchanged = abap_true.
      RETURN.
    ENDIF.
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    IF current_pattern = `beforeSave`.
      /bobf/cl_conf_model_api=>update_det_before_save( iv_bo_key            = key
                                                       iv_determination_key = current-det_key
                                                       iv_name              = current-det_name
                                                       iv_description       = target-description
                                                       iv_class             = target-det_class
                                                       iv_create_class      = create_class
                                                       it_request_nodes     = triggers
                                                       it_write_nodes       = write_nodes
                                                       it_predecessor       = current-predecessor
                                                       it_successor         = current-successor ).
    ELSE.
      /bobf/cl_conf_model_api=>update_det_after_modify( iv_bo_key            = key
                                                        iv_determination_key = current-det_key
                                                        iv_name              = current-det_name
                                                        iv_description       = target-description
                                                        iv_class             = target-det_class
                                                        iv_create_class      = create_class
                                                        it_request_nodes     = triggers
                                                        it_write_nodes       = write_nodes
                                                        it_predecessor       = current-predecessor
                                                        it_successor         = current-successor ).
    ENDIF.
    /bobf/cl_conf_model_api=>get_determination( EXPORTING iv_bo_key            = key
                                                          iv_determination_key = current-det_key
                                                IMPORTING es_determination     = DATA(stored) ).
    raise_not_saved_if( is_missing  = xsdbool( stored-description <> target-description
                                               OR stored-det_class <> target-det_class
                                               OR lines( stored-request_node ) <> lines( triggers )
                                               OR lines( stored-write_node ) <> lines( write_nodes ) )
                        entity_type = `determination`
                        name        = request-name ).
  ENDMETHOD.


  METHOD update_validation.
    DATA(key) = context-enhancement-bo_key.
    /bobf/cl_conf_model_api=>get_validation_tab( EXPORTING iv_bo_key     = key
                                                 IMPORTING et_validation = DATA(validations) ).
    DATA(current) = VALUE #( validations[ val_name = request-name ] OPTIONAL ).
    check_own_entity( context     = context
                      entity_type = `validation`
                      name        = request-name
                      exists      = xsdbool( current-val_key IS NOT INITIAL )
                      origin      = current-origin_bo_key ).
    DATA(is_action_validation) = xsdbool( current-val_cat = /bobf/if_conf_c=>sc_val_cat_action ).
    IF is_action_validation = abap_true AND ( request-impact IS NOT INITIAL OR request-triggers IS NOT INITIAL ).
      " Action validations run with their action and have neither impact nor triggers
      zcx_be_error=>raise_not_allowed( value    = request-name
                                       property = `impact, triggers` ).
    ENDIF.

    DATA(target) = current.
    IF request-description IS NOT INITIAL.
      target-description = request-description.
    ENDIF.
    IF request-class IS NOT INITIAL.
      target-val_class = request-class.
    ENDIF.
    IF request-impact IS NOT INITIAL.
      target-val_impact = SWITCH #( request-impact
                                    WHEN `messages`    THEN /bobf/if_conf_c=>sc_val_impact_messages
                                    WHEN `preventSave` THEN /bobf/if_conf_c=>sc_val_impact_prevent_save
                                    ELSE '?' ).
      IF target-val_impact = '?'.
        zcx_be_error=>raise_not_allowed( value    = request-impact
                                         property = `impact` ).
      ENDIF.
    ENDIF.
    DATA(current_triggers) = to_request_nodes( current-request_node ).
    DATA(triggers) = current_triggers.
    IF request-triggers IS NOT INITIAL.
      triggers = get_request_nodes( request = request
                                    context = context
                                    node    = VALUE #( node_key = current-node_key node_name = current-node_name ) ).
    ENDIF.
    DATA(create_class) = check_class( current = current-val_class
                                      target  = target-val_class ).
    result-class = target-val_class.
    IF target-description = current-description AND target-val_class = current-val_class
        AND target-val_impact = current-val_impact AND triggers = current_triggers.
      result-unchanged = abap_true.
      RETURN.
    ENDIF.
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    IF is_action_validation = abap_true.
      /bobf/cl_conf_model_api=>update_action_validation( iv_bo_key         = key
                                                         iv_validation_key = current-val_key
                                                         iv_name           = current-val_name
                                                         iv_class          = target-val_class
                                                         iv_description    = target-description
                                                         iv_create_class   = create_class ).
    ELSE.
      /bobf/cl_conf_model_api=>update_validation( iv_bo_key         = key
                                                  iv_validation_key = current-val_key
                                                  iv_name           = current-val_name
                                                  iv_class          = target-val_class
                                                  iv_description    = target-description
                                                  iv_create_class   = create_class
                                                  it_request_node   = triggers
                                                  iv_impact         = target-val_impact ).
    ENDIF.
    /bobf/cl_conf_model_api=>get_validation( EXPORTING iv_bo_key         = key
                                                       iv_validation_key = current-val_key
                                             IMPORTING es_validation     = DATA(stored) ).
    raise_not_saved_if( is_missing  = xsdbool( stored-description <> target-description
                                               OR stored-val_class <> target-val_class
                                               OR stored-val_impact <> target-val_impact
                                               OR lines( stored-request_node ) <> lines( triggers ) )
                        entity_type = `validation`
                        name        = request-name ).
  ENDMETHOD.


  METHOD update_node.
    DATA(key) = context-enhancement-bo_key.
    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key   = key
                                           IMPORTING et_node_tab = DATA(nodes) ).
    DATA(current) = VALUE #( nodes[ node_name = request-name ] OPTIONAL ).
    check_own_entity( context     = context
                      entity_type = `node`
                      name        = request-name
                      exists      = xsdbool( current-node_key IS NOT INITIAL )
                      origin      = current-origin_bo_key ).
    " Data structures and generated DDIC objects stay as created
    IF request-class IS NOT INITIAL OR request-data_structure IS NOT INITIAL OR request-transient_structure IS NOT INITIAL.
      zcx_be_error=>raise_not_allowed( value    = request-name
                                       property = `class, dataStructure, transientStructure` ).
    ENDIF.
    IF request-description IS INITIAL.
      zcx_be_error=>raise_missing_parameter( `description` ).
    ENDIF.
    DATA(description) = CONV /bobf/conf_mapi_description( request-description ).
    IF description = current-description.
      result-unchanged = abap_true.
      RETURN.
    ENDIF.
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    /bobf/cl_conf_model_api=>update_node( iv_bo_key              = key
                                          iv_node_key            = current-node_key
                                          iv_node_name           = CONV #( current-node_name )
                                          iv_description         = description
                                          iv_transient           = current-transient
                                          iv_is_extendible       = current-extensible
                                          iv_data_type           = current-data_type
                                          iv_data_data_type      = current-data_data_type
                                          iv_data_table_type     = current-data_table_type
                                          iv_data_data_type_t    = current-data_data_type_t
                                          iv_database_table      = current-database_table
                                          iv_ext_incl_name       = current-ext_incl_name
                                          iv_ext_incl_name_t     = current-ext_incl_name_t
                                          iv_gen_data_type       = abap_false
                                          iv_gen_data_table_type = abap_false
                                          iv_gen_database        = abap_false ).
    /bobf/cl_conf_model_api=>get_node( EXPORTING iv_bo_key   = key
                                                 iv_node_key = current-node_key
                                       IMPORTING es_node     = DATA(stored) ).
    raise_not_saved_if( is_missing  = xsdbool( stored-description <> description )
                        entity_type = `node`
                        name        = request-name ).
  ENDMETHOD.


  METHOD update_query.
    DATA(key) = context-enhancement-bo_key.
    /bobf/cl_conf_model_api=>get_query_tab( EXPORTING iv_bo_key = key
                                            IMPORTING et_query  = DATA(queries) ).
    DATA(current) = VALUE #( queries[ query_name = request-name ] OPTIONAL ).
    check_own_entity( context     = context
                      entity_type = `query`
                      name        = request-name
                      exists      = xsdbool( current-query_key IS NOT INITIAL )
                      origin      = current-origin_bo_key ).

    DATA(target) = current.
    IF request-description IS NOT INITIAL.
      target-description = request-description.
    ENDIF.
    IF request-data_structure IS NOT INITIAL.
      check_ddic_object( name        = request-data_structure
                         object_type = 'TABL' ).
      target-data_type = request-data_structure.
    ENDIF.
    IF request-class IS NOT INITIAL.
      " A select-by-elements query has no class; giving it one would change its kind
      IF current-query_class IS INITIAL.
        zcx_be_error=>raise_not_allowed( value    = request-class
                                         property = `class` ).
      ENDIF.
      target-query_class = request-class.
    ENDIF.
    DATA(create_class) = check_class( current = current-query_class
                                      target  = target-query_class ).
    result-class = target-query_class.
    IF target-description = current-description AND target-data_type = current-data_type
        AND target-query_class = current-query_class.
      result-unchanged = abap_true.
      RETURN.
    ENDIF.
    IF request-dry_run = abap_true.
      RETURN.
    ENDIF.

    /bobf/cl_conf_model_api=>update_query( iv_bo_key        = key
                                           iv_query_key     = current-query_key
                                           iv_name          = current-query_name
                                           iv_description   = target-description
                                           iv_class         = target-query_class
                                           iv_create_class  = create_class
                                           iv_data_type     = target-data_type
                                           iv_result_type   = current-result_type
                                           iv_result_type_t = current-result_type_t
                                           iv_hana_view     = current-hana_view ).
    /bobf/cl_conf_model_api=>get_query( EXPORTING iv_bo_key    = key
                                                  iv_query_key = current-query_key
                                        IMPORTING es_query     = DATA(stored) ).
    raise_not_saved_if( is_missing  = xsdbool( stored-description <> target-description
                                               OR stored-data_type <> target-data_type
                                               OR stored-query_class <> target-query_class )
                        entity_type = `query`
                        name        = request-name ).
  ENDMETHOD.


  METHOD check_own_entity.
    IF exists = abap_false.
      zcx_be_error=>raise_unknown_entity( entity_type     = entity_type
                                          name            = name
                                          business_object = context-enhancement-bo_name ).
    ENDIF.
    IF origin <> context-enhancement-bo_key.
      zcx_be_error=>raise_base_entity( entity_type = entity_type
                                       name        = name ).
    ENDIF.
  ENDMETHOD.


  METHOD check_class.
    IF target = current OR target IS INITIAL.
      RETURN.
    ENDIF.
    IF zcl_be_reader=>is_customer_name( target ) = abap_false.
      zcx_be_error=>raise_not_customer_name( target ).
    ENDIF.
    SELECT SINGLE @abap_true FROM seoclass WHERE clsname = @target INTO @DATA(exists).
    result = xsdbool( exists = abap_false ).
  ENDMETHOD.


  METHOD to_request_nodes.
    result = VALUE #( FOR trigger IN triggers
                      ( request_node_key = trigger-node_key
                        assoc_key        = trigger-assoc_key
                        trigger_create   = trigger-trigger_create
                        trigger_update   = trigger-trigger_update
                        trigger_delete   = trigger-trigger_delete ) ).
  ENDMETHOD.


  METHOD find_node.
    IF name IS INITIAL.
      zcx_be_error=>raise_missing_parameter( `node` ).
    ENDIF.
    /bobf/cl_conf_model_api=>get_node_tab( EXPORTING iv_bo_key   = context-enhancement-bo_key
                                           IMPORTING et_node_tab = DATA(nodes) ).
    result = VALUE #( nodes[ node_name = name ] OPTIONAL ).
    IF result-node_key IS INITIAL.
      zcx_be_error=>raise_unknown_node( node            = name
                                        business_object = context-enhancement-bo_name ).
    ENDIF.
  ENDMETHOD.


  METHOD find_association.
    IF source-node_key = target-node_key.
      RETURN.
    ENDIF.
    /bobf/cl_conf_model_api=>get_association_tab( EXPORTING iv_bo_key      = context-enhancement-bo_key
                                                  IMPORTING et_association = DATA(associations) ).
    DELETE associations WHERE source_node_key <> source-node_key OR target_node_key <> target-node_key.
    DATA(to_parent) = VALUE #( associations[ assoc_type = 'A' assoc_cat = 'P' ]-assoc_key OPTIONAL ).
    DATA(composition) = VALUE #( associations[ assoc_type = 'C' assoc_cat = 'N' ]-assoc_key OPTIONAL ).
    DATA(to_root) = VALUE #( associations[ assoc_type = 'A' assoc_cat = 'R' ]-assoc_key OPTIONAL ).
    result = COND #( WHEN requested IS NOT INITIAL THEN VALUE #( associations[ assoc_name = requested ]-assoc_key OPTIONAL )
                     WHEN to_parent IS NOT INITIAL THEN to_parent
                     WHEN composition IS NOT INITIAL THEN composition
                     ELSE to_root ).
    IF result IS INITIAL AND ( is_required = abap_true OR requested IS NOT INITIAL ).
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e031(zbe_bopf_enh) WITH source-node_name target-node_name property
        EXPORTING status = 422.
    ENDIF.
  ENDMETHOD.


  METHOD get_write_nodes.
    DATA target TYPE /bobf/s_conf_model_api_node.

    " A determination always writes its own node
    result = VALUE #( ( write_node_key = node-node_key ) ).
    LOOP AT request-write_nodes ASSIGNING FIELD-SYMBOL(<write_node>) WHERE node <> node-node_name.
      target = find_usable_node( context = context
                                 name    = <write_node>-node ).
      INSERT VALUE #( write_node_key = target-node_key
                      assoc_key      = find_association( context     = context
                                                         source      = target
                                                         target      = node
                                                         requested   = <write_node>-association
                                                         is_required = abap_false
                                                         property    = `writeNodes` ) ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD check_database_table.
    DATA(name) = COND string( WHEN requested IS NOT INITIAL THEN requested ELSE proposed ).
    DATA(table) = CONV tabname( name ).
    SELECT SINGLE @abap_true FROM dd02l WHERE tabname = @table INTO @DATA(exists).
    IF name IS INITIAL OR strlen( name ) > 16 OR name CP '*_' OR exists = abap_true
        OR ( requested IS NOT INITIAL AND zcl_be_reader=>is_customer_name( requested ) = abap_false ).
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e032(zbe_bopf_enh) WITH name EXPORTING status = 422.
    ENDIF.
    result = name.
  ENDMETHOD.


  METHOD check_required_parameters.
    IF request-operation = operation-update_enhancement.
      RETURN.
    ENDIF.
    IF request-name IS INITIAL.
      zcx_be_error=>raise_missing_parameter( `name` ).
    ENDIF.
    IF request-operation = operation-create_enhancement AND request-base_business_object IS INITIAL.
      zcx_be_error=>raise_missing_parameter( `baseBusinessObject` ).
    ENDIF.
  ENDMETHOD.


  METHOD propose_class.
    DATA proposed_name TYPE string.

    DATA(key) = context-enhancement-bo_key.
    DATA(entity_name) = CONV /bobf/obm_name( name ).
    CASE create_operation.
      WHEN operation-create_action OR operation-create_action_enhancement.
        /bobf/cl_conf_model_api=>propose_action_names( EXPORTING iv_bo_key       = key
                                                                 iv_node_key     = node_key
                                                                 iv_action_name  = entity_name
                                                       IMPORTING ev_action_class = result ).
      WHEN operation-create_determination.
        /bobf/cl_conf_model_api=>propose_determination_names(
          EXPORTING
            iv_bo_key              = key
            iv_node_key            = node_key
            iv_determination_name  = entity_name
          IMPORTING
            ev_determination_class = result ).
      WHEN operation-create_validation.
        /bobf/cl_conf_model_api=>propose_validation_names( EXPORTING iv_bo_key           = key
                                                                     iv_node_key         = node_key
                                                                     iv_validation_name  = entity_name
                                                           IMPORTING ev_validation_class = result ).
      WHEN operation-create_action_validation.
        /bobf/cl_conf_model_api=>propose_act_validation_names( EXPORTING iv_bo_key           = key
                                                                         iv_node_key         = node_key
                                                                         iv_validation_name  = entity_name
                                                               IMPORTING ev_validation_class = result ).
      WHEN operation-create_association.
        " The configuration API has no proposal for association classes; the BOPF designer uses the toolbox
        /bobf/cl_conf_toolbox=>propose_name( EXPORTING iv_namespace     = context-enhancement-namespace
                                                       iv_prefix        = context-enhancement-prefix
                                                       iv_object_type   = /bobf/cl_conf_toolbox=>sc_association_class
                                                       iv_original_name = name
                                             IMPORTING ev_proposed_name = proposed_name ).
        result = proposed_name.
    ENDCASE.
  ENDMETHOD.


  METHOD get_action_names.
    " One proposal for both names: SAP adds a counter to a name it has already proposed in this session
    /bobf/cl_conf_model_api=>propose_action_names( EXPORTING iv_bo_key           = bo_key
                                                             iv_node_key         = node_key
                                                             iv_action_name      = CONV #( name )
                                                   IMPORTING ev_action_class     = DATA(class)
                                                             ev_action_parameter = DATA(parameter_structure) ).
    result = VALUE #( class               = class
                      parameter_structure = parameter_structure ).
  ENDMETHOD.


  METHOD get_node_names.
    /bobf/cl_conf_model_api=>propose_node_names(
      EXPORTING
        iv_bo_key                   = bo_key
        iv_node_name                = CONV #( name )
      IMPORTING
        ev_data_type                = DATA(combined_structure)
        ev_data_data_type           = DATA(data_structure)
        ev_data_data_type_transient = DATA(transient_structure)
        ev_data_table_type          = DATA(table_type)
        ev_database_table           = DATA(database_table) ).
    result = VALUE #( data_structure      = data_structure
                      transient_structure = transient_structure
                      combined_structure  = combined_structure
                      combined_table_type = table_type
                      database_table      = database_table ).
    " Long node names give a database table name that cannot be generated, see check_database_table
    TRY.
        check_database_table( requested = ``
                              proposed  = database_table ).
      CATCH zcx_be_error INTO DATA(error).
        INSERT error->get_text( ) INTO TABLE result-hints.
    ENDTRY.
  ENDMETHOD.


  METHOD get_generated_class.
    IF class IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE @abap_true FROM seoclass WHERE clsname = @class INTO @DATA(exists).
    IF exists = abap_false.
      result = VALUE #( ( type = `class` name = class ) ).
    ENDIF.
  ENDMETHOD.


  METHOD check_new_name.
    DATA(object_name) = CONV tadir-obj_name( name ).
    SELECT SINGLE @abap_true FROM tadir
      WHERE pgmid = 'R3TR' AND object IN @object_types AND obj_name = @object_name
      INTO @DATA(exists).
    IF exists = abap_true OR strlen( name ) > 30 OR name CN 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_/'
        OR zcl_be_reader=>is_customer_name( name ) = abap_false.
      RAISE EXCEPTION TYPE zcx_be_error MESSAGE e034(zbe_bopf_enh) WITH name property EXPORTING status = 422.
    ENDIF.
  ENDMETHOD.


  METHOD get_package.
    DATA(object_name) = CONV tadir-obj_name( enhancement ).
    " Without directory entry the package stays empty, and the caller refuses the change
    SELECT SINGLE devclass FROM tadir
      WHERE pgmid = 'R3TR' AND object = 'BOBX' AND obj_name = @object_name
      INTO @result ##SUBRC_OK.
  ENDMETHOD.
ENDCLASS.

