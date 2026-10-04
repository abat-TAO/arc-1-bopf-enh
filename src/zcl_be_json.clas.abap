"! JSON conversion of the HTTP contract: camelCase names, initial values left out
CLASS zcl_be_json DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS to_json
      IMPORTING
        data          TYPE data
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS from_json
      IMPORTING
        json TYPE string
      CHANGING
        data TYPE data.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_be_json IMPLEMENTATION.

  METHOD to_json.
    result = /ui2/cl_json=>serialize( data        = data
                                      compress    = abap_true
                                      pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
  ENDMETHOD.


  METHOD from_json.
    /ui2/cl_json=>deserialize( EXPORTING json        = json
                                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                               CHANGING  data        = data ).
  ENDMETHOD.

ENDCLASS.

