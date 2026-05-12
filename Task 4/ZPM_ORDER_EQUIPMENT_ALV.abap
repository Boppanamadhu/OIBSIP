*&---------------------------------------------------------------------*
*& Report  ZPM_ORDER_EQUIPMENT_ALV
*&---------------------------------------------------------------------*
*& Case Study : Create Interactive ALV for PM Order to Navigate Equipment
*& Skill      : SAP ABAP
*& Programme  : YP Mentorship Program
*&
*& Description: Displays Plant Maintenance (PM) Orders in an interactive
*&              ALV grid. From the primary list the user can:
*&                * Double-click / hotspot AUFNR -> launch IW33
*&                  (Display PM Order) for the selected order.
*&                * Double-click / hotspot EQUNR -> open a secondary
*&                  ALV showing equipment master details (EQUI/EQKT) and
*&                  drill further to IE03 (Display Equipment).
*&---------------------------------------------------------------------*
REPORT zpm_order_equipment_alv MESSAGE-ID zpm_msg.

*----------------------------------------------------------------------*
* Type pools
*----------------------------------------------------------------------*
TYPE-POOLS: slis.

*----------------------------------------------------------------------*
* Types
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_order,
         aufnr TYPE aufk-aufnr,   " Order number
         auart TYPE aufk-auart,   " Order type
         ktext TYPE aufk-ktext,   " Description
         werks TYPE aufk-werks,   " Plant
         erdat TYPE aufk-erdat,   " Created on
         ernam TYPE aufk-ernam,   " Created by
         equnr TYPE afih-equnr,   " Equipment number
         iloan TYPE afih-iloan,   " Functional location
         ingrp TYPE afih-ingrp,   " Planner group
         priok TYPE afih-priok,   " Priority
       END OF ty_order.

TYPES: BEGIN OF ty_equip,
         equnr TYPE equi-equnr,   " Equipment number
         eqktx TYPE eqkt-eqktx,   " Description
         eqtyp TYPE equi-eqtyp,   " Equipment category
         brgew TYPE equi-brgew,   " Gross weight
         gewei TYPE equi-gewei,   " Weight unit
         herst TYPE equi-herst,   " Manufacturer
         typbz TYPE equi-typbz,   " Model number
         baujj TYPE equi-baujj,   " Year of construction
         inbdt TYPE equi-inbdt,   " Start-up date
       END OF ty_equip.

*----------------------------------------------------------------------*
* Globals
*----------------------------------------------------------------------*
DATA: gt_orders     TYPE STANDARD TABLE OF ty_order,
      gs_order      TYPE ty_order,
      gt_equipment  TYPE STANDARD TABLE OF ty_equip,
      gs_equipment  TYPE ty_equip,
      gt_fcat       TYPE slis_t_fieldcat_alv,
      gs_layout     TYPE slis_layout_alv,
      gs_variant    TYPE disvariant,
      gv_repid      TYPE sy-repid.

gv_repid = sy-repid.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS: s_aufnr FOR gs_order-aufnr,
                s_auart FOR gs_order-auart,
                s_werks FOR gs_order-werks,
                s_erdat FOR gs_order-erdat.
PARAMETERS:     p_max   TYPE i DEFAULT 1000.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* Initialization
*----------------------------------------------------------------------*
INITIALIZATION.
  s_erdat-low  = sy-datum - 365.
  s_erdat-high = sy-datum.
  s_erdat-sign = 'I'.
  s_erdat-option = 'BT'.
  APPEND s_erdat.

*----------------------------------------------------------------------*
* Start-of-selection
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM fetch_orders.
  IF gt_orders IS INITIAL.
    MESSAGE 'No PM orders found for the given selection' TYPE 'S'
            DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

END-OF-SELECTION.
  PERFORM build_fieldcatalog.
  PERFORM build_layout.
  PERFORM display_alv.

*&---------------------------------------------------------------------*
*&      Form  FETCH_ORDERS
*&---------------------------------------------------------------------*
FORM fetch_orders.

  SELECT a~aufnr a~auart a~ktext a~werks a~erdat a~ernam
         b~equnr b~iloan b~ingrp b~priok
    FROM aufk AS a
    INNER JOIN afih AS b
      ON a~aufnr = b~aufnr
    INTO TABLE gt_orders
    UP TO p_max ROWS
    WHERE a~aufnr IN s_aufnr
      AND a~auart IN s_auart
      AND a~werks IN s_werks
      AND a~erdat IN s_erdat.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCATALOG
*&---------------------------------------------------------------------*
FORM build_fieldcatalog.

  DATA: ls_fcat TYPE slis_fieldcat_alv.

  DEFINE add_field.
    CLEAR ls_fcat.
    ls_fcat-fieldname = &1.
    ls_fcat-seltext_m = &2.
    ls_fcat-seltext_l = &2.
    ls_fcat-hotspot   = &3.
    ls_fcat-key       = &4.
    APPEND ls_fcat TO gt_fcat.
  END-OF-DEFINITION.

  add_field 'AUFNR' 'Order'          'X' 'X'.
  add_field 'AUART' 'Order Type'     ''  ''.
  add_field 'KTEXT' 'Description'    ''  ''.
  add_field 'WERKS' 'Plant'          ''  ''.
  add_field 'ERDAT' 'Created On'     ''  ''.
  add_field 'ERNAM' 'Created By'     ''  ''.
  add_field 'EQUNR' 'Equipment'      'X' ''.
  add_field 'ILOAN' 'Func. Location' ''  ''.
  add_field 'INGRP' 'Planner Group'  ''  ''.
  add_field 'PRIOK' 'Priority'       ''  ''.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  BUILD_LAYOUT
*&---------------------------------------------------------------------*
FORM build_layout.

  gs_layout-colwidth_optimize = 'X'.
  gs_layout-zebra             = 'X'.
  gs_layout-detail_popup      = 'X'.

  gs_variant-report = gv_repid.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV
*&---------------------------------------------------------------------*
FORM display_alv.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = gv_repid
      i_callback_user_command = 'HANDLE_USER_COMMAND'
      i_callback_pf_status_set = 'SET_PF_STATUS'
      is_layout               = gs_layout
      it_fieldcat             = gt_fcat
      i_save                  = 'A'
      is_variant              = gs_variant
    TABLES
      t_outtab                = gt_orders
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SET_PF_STATUS
*&---------------------------------------------------------------------*
FORM set_pf_status USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'STANDARD'.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  HANDLE_USER_COMMAND
*&---------------------------------------------------------------------*
FORM handle_user_command USING r_ucomm     TYPE sy-ucomm
                               rs_selfield TYPE slis_selfield.

  CASE r_ucomm.
    WHEN '&IC1'.                       " Standard hotspot / double-click
      CASE rs_selfield-fieldname.

        WHEN 'AUFNR'.
          IF rs_selfield-value IS NOT INITIAL.
            SET PARAMETER ID 'ANR' FIELD rs_selfield-value.
            CALL TRANSACTION 'IW33' AND SKIP FIRST SCREEN.
          ENDIF.

        WHEN 'EQUNR'.
          IF rs_selfield-value IS NOT INITIAL.
            PERFORM show_equipment_details USING rs_selfield-value.
          ENDIF.

      ENDCASE.
  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SHOW_EQUIPMENT_DETAILS
*&---------------------------------------------------------------------*
FORM show_equipment_details USING iv_equnr TYPE equi-equnr.

  DATA: lt_equip  TYPE STANDARD TABLE OF ty_equip,
        lt_fcat   TYPE slis_t_fieldcat_alv,
        ls_fcat   TYPE slis_fieldcat_alv,
        ls_layout TYPE slis_layout_alv.

  SELECT a~equnr b~eqktx a~eqtyp a~brgew a~gewei
         a~herst a~typbz a~baujj a~inbdt
    FROM equi AS a
    LEFT OUTER JOIN eqkt AS b
      ON  a~equnr = b~equnr
      AND b~spras = sy-langu
    INTO TABLE lt_equip
    WHERE a~equnr = iv_equnr.

  IF lt_equip IS INITIAL.
    MESSAGE 'No equipment master data found' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  DEFINE add_eq_field.
    CLEAR ls_fcat.
    ls_fcat-fieldname = &1.
    ls_fcat-seltext_m = &2.
    ls_fcat-seltext_l = &2.
    ls_fcat-hotspot   = &3.
    APPEND ls_fcat TO lt_fcat.
  END-OF-DEFINITION.

  add_eq_field 'EQUNR' 'Equipment'     'X'.
  add_eq_field 'EQKTX' 'Description'   ''.
  add_eq_field 'EQTYP' 'Category'      ''.
  add_eq_field 'HERST' 'Manufacturer'  ''.
  add_eq_field 'TYPBZ' 'Model'         ''.
  add_eq_field 'BAUJJ' 'Year of Const.' ''.
  add_eq_field 'INBDT' 'Start-up Date' ''.
  add_eq_field 'BRGEW' 'Gross Weight'  ''.
  add_eq_field 'GEWEI' 'Unit'          ''.

  ls_layout-colwidth_optimize = 'X'.
  ls_layout-zebra             = 'X'.
  ls_layout-window_titlebar   = 'Equipment Details'.

  CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
    EXPORTING
      i_title         = 'Equipment Details - drill into IE03'
      i_zebra         = 'X'
      i_tabname       = 'LT_EQUIP'
      it_fieldcat     = lt_fcat
    TABLES
      t_outtab        = lt_equip
    EXCEPTIONS
      program_error   = 1
      OTHERS          = 2.

  SET PARAMETER ID 'EQN' FIELD iv_equnr.
  CALL TRANSACTION 'IE03' AND SKIP FIRST SCREEN.

ENDFORM.
