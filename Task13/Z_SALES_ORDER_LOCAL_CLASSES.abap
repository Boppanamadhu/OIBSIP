*&---------------------------------------------------------------------*
*& Report  : Z_SALES_ORDER_LOCAL_CLASSES
*& Task    : 13 - Implement local classes in report to read Sales
*&           Order Details with modularized code.
*&---------------------------------------------------------------------*
REPORT z_sales_order_local_classes.

*----------------------------------------------------------------------*
* TYPE DECLARATIONS
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_header,
         vbeln TYPE vbak-vbeln,
         erdat TYPE vbak-erdat,
         auart TYPE vbak-auart,
         kunnr TYPE vbak-kunnr,
         netwr TYPE vbak-netwr,
         waerk TYPE vbak-waerk,
       END OF ty_header.

TYPES: BEGIN OF ty_item,
         vbeln TYPE vbap-vbeln,
         posnr TYPE vbap-posnr,
         matnr TYPE vbap-matnr,
         arktx TYPE vbap-arktx,
         kwmeng TYPE vbap-kwmeng,
         vrkme  TYPE vbap-vrkme,
         netpr  TYPE vbap-netpr,
       END OF ty_item.

*----------------------------------------------------------------------*
* LOCAL CLASS: DATA FETCHER
* Reads Sales Order header and item data from the database.
*----------------------------------------------------------------------*
CLASS lcl_so_fetcher DEFINITION.
  PUBLIC SECTION.
    METHODS:
      fetch_header
        IMPORTING iv_vbeln         TYPE vbak-vbeln
        EXPORTING et_header        TYPE TABLE,
      fetch_items
        IMPORTING iv_vbeln         TYPE vbap-vbeln
        EXPORTING et_items         TYPE TABLE.
ENDCLASS.

CLASS lcl_so_fetcher IMPLEMENTATION.

  METHOD fetch_header.
    SELECT vbeln erdat auart kunnr netwr waerk
      INTO TABLE et_header
      FROM vbak
      WHERE vbeln = iv_vbeln.

    IF sy-subrc <> 0.
      MESSAGE 'No Sales Order found for the entered number.' TYPE 'E'.
    ENDIF.
  ENDMETHOD.

  METHOD fetch_items.
    SELECT vbeln posnr matnr arktx kwmeng vrkme netpr
      INTO TABLE et_items
      FROM vbap
      WHERE vbeln = iv_vbeln.

    IF sy-subrc <> 0.
      MESSAGE 'No line items found for the entered Sales Order.' TYPE 'W'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* LOCAL CLASS: DISPLAY
* Formats and displays Sales Order data using WRITE statements.
*----------------------------------------------------------------------*
CLASS lcl_so_display DEFINITION.
  PUBLIC SECTION.
    METHODS:
      display_header
        IMPORTING it_header TYPE TABLE,
      display_items
        IMPORTING it_items  TYPE TABLE.
ENDCLASS.

CLASS lcl_so_display IMPLEMENTATION.

  METHOD display_header.
    DATA ls_header TYPE ty_header.

    WRITE: /1  'Sales Order Header Details'.
    WRITE: /1  '==========================='.
    WRITE: /1  'Sales Order', 20 'Created On', 35 'Order Type',
               50 'Customer',  65 'Net Value',  80 'Currency'.
    WRITE: /1  '----------', 20 '----------', 35 '----------',
               50 '--------',  65 '---------',  80 '--------'.

    LOOP AT it_header INTO ls_header.
      WRITE: /1  ls_header-vbeln,
             20  ls_header-erdat,
             35  ls_header-auart,
             50  ls_header-kunnr,
             65  ls_header-netwr,
             80  ls_header-waerk.
    ENDLOOP.
  ENDMETHOD.

  METHOD display_items.
    DATA ls_item TYPE ty_item.

    SKIP 2.
    WRITE: /1  'Sales Order Line Item Details'.
    WRITE: /1  '=============================='.
    WRITE: /1  'Sales Order', 15 'Item', 22 'Material',
               38 'Description', 60 'Qty', 70 'UoM', 78 'Net Price'.
    WRITE: /1  '-----------', 15 '----', 22 '--------',
               38 '-----------', 60 '---', 70 '---', 78 '---------'.

    LOOP AT it_items INTO ls_item.
      WRITE: /1  ls_item-vbeln,
             15  ls_item-posnr,
             22  ls_item-matnr,
             38  ls_item-arktx,
             60  ls_item-kwmeng,
             70  ls_item-vrkme,
             78  ls_item-netpr.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* LOCAL CLASS: CONTROLLER
* Orchestrates fetching and displaying; entry point of the report.
*----------------------------------------------------------------------*
CLASS lcl_so_controller DEFINITION.
  PUBLIC SECTION.
    METHODS:
      run
        IMPORTING iv_vbeln TYPE vbak-vbeln.
  PRIVATE SECTION.
    DATA: mo_fetcher TYPE REF TO lcl_so_fetcher,
          mo_display TYPE REF TO lcl_so_display.
ENDCLASS.

CLASS lcl_so_controller IMPLEMENTATION.

  METHOD run.
    DATA: lt_header TYPE TABLE OF ty_header,
          lt_items  TYPE TABLE OF ty_item.

    CREATE OBJECT mo_fetcher.
    CREATE OBJECT mo_display.

    mo_fetcher->fetch_header( EXPORTING iv_vbeln = iv_vbeln
                              IMPORTING et_header = lt_header ).

    mo_fetcher->fetch_items(  EXPORTING iv_vbeln = iv_vbeln
                              IMPORTING et_items  = lt_items ).

    mo_display->display_header( lt_header ).
    mo_display->display_items(  lt_items ).
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* SELECTION SCREEN
*----------------------------------------------------------------------*
PARAMETERS: p_vbeln TYPE vbak-vbeln OBLIGATORY.

*----------------------------------------------------------------------*
* START OF SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.
  DATA lo_controller TYPE REF TO lcl_so_controller.
  CREATE OBJECT lo_controller.
  lo_controller->run( iv_vbeln = p_vbeln ).
