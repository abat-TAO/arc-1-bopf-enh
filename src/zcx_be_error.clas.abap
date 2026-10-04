CLASS zcx_be_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.

    "! HTTP status code the request handler answers with
    DATA status TYPE i READ-ONLY.

    METHODS constructor
      IMPORTING
        textid   LIKE if_t100_message=>t100key OPTIONAL
        previous LIKE previous OPTIONAL
        status   TYPE i DEFAULT 400.

    "! First error of a BOPF message container, to be passed on as previous exception
    CLASS-METHODS get_first_error
      IMPORTING
        messages      TYPE REF TO /bobf/if_frw_message
      RETURNING
        VALUE(result) TYPE REF TO /bobf/cm_frw.

    "! BOPF rejected or silently dropped a change; the first BOPF error becomes the previous exception
    CLASS-METHODS raise_not_saved
      IMPORTING
        entity_type TYPE csequence
        name        TYPE csequence
        messages    TYPE REF TO /bobf/if_frw_message OPTIONAL
      RAISING
        zcx_be_error.

    CLASS-METHODS raise_unknown_business_object
      IMPORTING
        name TYPE csequence
      RAISING
        zcx_be_error.

    CLASS-METHODS raise_unknown_enhancement
      IMPORTING
        name TYPE csequence
      RAISING
        zcx_be_error.

    "! A parameter the operation needs is missing in the request
    CLASS-METHODS raise_missing_parameter
      IMPORTING
        name TYPE csequence
      RAISING
        zcx_be_error.

    "! Only objects in the customer namespace are changed
    CLASS-METHODS raise_not_customer_name
      IMPORTING
        name TYPE csequence
      RAISING
        zcx_be_error.

    CLASS-METHODS raise_unknown_node
      IMPORTING
        node            TYPE csequence
        business_object TYPE csequence
      RAISING
        zcx_be_error.

    CLASS-METHODS raise_action_not_extensible
      IMPORTING
        action TYPE csequence
      RAISING
        zcx_be_error.

    CLASS-METHODS raise_not_allowed
      IMPORTING
        value    TYPE csequence
        property TYPE csequence
      RAISING
        zcx_be_error.

    CLASS-METHODS raise_unknown_entity
      IMPORTING
        entity_type     TYPE csequence
        name            TYPE csequence
        business_object TYPE csequence
      RAISING
        zcx_be_error.

    "! Entities of the base business object are not changed or deleted through an enhancement
    CLASS-METHODS raise_base_entity
      IMPORTING
        entity_type TYPE csequence
        name        TYPE csequence
      RAISING
        zcx_be_error.

    "! The delete token does not match the current delete preview
    CLASS-METHODS raise_token_outdated
      RAISING
        zcx_be_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcx_be_error IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->status = status.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.


  METHOD get_first_error.
    IF messages IS NOT BOUND.
      RETURN.
    ENDIF.
    messages->get( IMPORTING et_message = DATA(entries) ).
    LOOP AT entries ASSIGNING FIELD-SYMBOL(<entry>).
      IF <entry>->severity CA 'EAX'.
        result = <entry>.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD raise_not_saved.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e018(zbe_bopf_enh) WITH entity_type name
      EXPORTING status   = 422
                previous = get_first_error( messages ).
  ENDMETHOD.


  METHOD raise_unknown_business_object.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e001(zbe_bopf_enh) WITH name EXPORTING status = 404.
  ENDMETHOD.


  METHOD raise_unknown_enhancement.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e002(zbe_bopf_enh) WITH name EXPORTING status = 404.
  ENDMETHOD.


  METHOD raise_missing_parameter.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e004(zbe_bopf_enh) WITH name EXPORTING status = 400.
  ENDMETHOD.


  METHOD raise_not_customer_name.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e008(zbe_bopf_enh) WITH name EXPORTING status = 422.
  ENDMETHOD.


  METHOD raise_unknown_node.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e010(zbe_bopf_enh) WITH node business_object EXPORTING status = 404.
  ENDMETHOD.


  METHOD raise_action_not_extensible.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e013(zbe_bopf_enh) WITH action EXPORTING status = 422.
  ENDMETHOD.


  METHOD raise_not_allowed.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e020(zbe_bopf_enh) WITH value property EXPORTING status = 400.
  ENDMETHOD.


  METHOD raise_unknown_entity.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e025(zbe_bopf_enh) WITH entity_type name business_object
      EXPORTING status = 404.
  ENDMETHOD.


  METHOD raise_base_entity.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e026(zbe_bopf_enh) WITH entity_type name EXPORTING status = 422.
  ENDMETHOD.


  METHOD raise_token_outdated.
    RAISE EXCEPTION TYPE zcx_be_error MESSAGE e027(zbe_bopf_enh) EXPORTING status = 409.
  ENDMETHOD.
ENDCLASS.
