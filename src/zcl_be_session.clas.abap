"! Dialog-free session for the classic BOPF configuration API.
"! The only place that sets the unreleased switches of /BOBF/CL_CONF_TOOLBOX. They are the
"! switches SAP's ADT backend sets in /BOBF/CL_CONF_MODEL_API_ADT->PREPARE_MODIFICATION, except
"! activation handling: the inactive-version path dumps for enhancement objects.
CLASS zcl_be_session DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! @parameter language | Texts are stored in this language; initial keeps the logon language
    METHODS constructor
      IMPORTING
        package  TYPE devclass
        request  TYPE trkorr OPTIONAL
        language TYPE sy-langu OPTIONAL.

    METHODS close.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA previous_language TYPE sy-langu.
ENDCLASS.



CLASS zcl_be_session IMPLEMENTATION.

  METHOD constructor.
    " Transport recording and class or DDIC generation then run without popups
    /bobf/cl_conf_toolbox=>sv_genflag = abap_true.
    /bobf/cl_conf_toolbox=>sv_suppress_dialog = abap_true.
    /bobf/cl_conf_toolbox=>sv_devclass = package.
    /bobf/cl_conf_toolbox=>sv_corr_num = request.
    /bobf/cl_conf_toolbox=>sv_activation_handling = abap_false.

    previous_language = sy-langu.
    IF language IS NOT INITIAL AND language <> sy-langu.
      SET LOCALE LANGUAGE language.
      " The meta model buffer still holds the texts of the previous language
      /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( )->cleanup( ).
    ENDIF.
  ENDMETHOD.


  METHOD close.
    CLEAR: /bobf/cl_conf_toolbox=>sv_genflag,
           /bobf/cl_conf_toolbox=>sv_suppress_dialog,
           /bobf/cl_conf_toolbox=>sv_devclass,
           /bobf/cl_conf_toolbox=>sv_corr_num.
    IF sy-langu <> previous_language.
      SET LOCALE LANGUAGE previous_language.
      /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( )->cleanup( ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

