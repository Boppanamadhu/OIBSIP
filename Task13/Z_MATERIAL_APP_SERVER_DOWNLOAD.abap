*&---------------------------------------------------------------------*
*& Report  : Z_MATERIAL_APP_SERVER_DOWNLOAD
*& Task    : 13 - Application Server Download
*& Desc    : Downloads material data to a PC file using a selection
*&           screen with Material No and Download Path as mandatory
*&           inputs. Uses GUI_DOWNLOAD to transfer the file.
*&---------------------------------------------------------------------*
REPORT z_material_app_server_download.

*----------------------------------------------------------------------*
* TYPE DECLARATIONS
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_material,
         matnr TYPE mara-matnr,
         mtart TYPE mara-mtart,
         mbrsh TYPE mara-mbrsh,
         meins TYPE mara-meins,
         maktx TYPE makt-maktx,
       END OF ty_material.

*----------------------------------------------------------------------*
* DATA DECLARATIONS
*----------------------------------------------------------------------*
DATA: gt_material TYPE TABLE OF ty_material,
      gs_material TYPE ty_material,
      gt_output   TYPE TABLE OF string,
      gv_line     TYPE string.

*----------------------------------------------------------------------*
* SELECTION SCREEN
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    p_matnr TYPE mara-matnr  OBLIGATORY,
    p_path  TYPE string(255) OBLIGATORY DEFAULT 'C:\Downloads\material_data.txt'.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* INITIALIZATION
*----------------------------------------------------------------------*
INITIALIZATION.
  TEXT-001 = 'Selection Parameters'.

*----------------------------------------------------------------------*
* START OF SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM fetch_material_data.

  IF gt_material IS NOT INITIAL.
    PERFORM build_output.
    PERFORM download_to_pc.
  ENDIF.

*&---------------------------------------------------------------------*
*& Form FETCH_MATERIAL_DATA
*& Reads material master + description for the entered material number
*&---------------------------------------------------------------------*
FORM fetch_material_data.

  SELECT mara~matnr
         mara~mtart
         mara~mbrsh
         mara~meins
         makt~maktx
    INTO TABLE gt_material
    FROM mara
    INNER JOIN makt
      ON makt~matnr = mara~matnr
     AND makt~spras = sy-langu
    WHERE mara~matnr = p_matnr.

  IF sy-subrc <> 0.
    MESSAGE 'No data found for the entered Material Number.' TYPE 'E'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_OUTPUT
*& Builds the internal table of strings to be written to file
*&---------------------------------------------------------------------*
FORM build_output.

  DATA lv_header TYPE string.

  lv_header = 'Material No|Material Type|Industry Sector|Base UoM|Description'.
  APPEND lv_header TO gt_output.

  LOOP AT gt_material INTO gs_material.
    CONCATENATE gs_material-matnr
                gs_material-mtart
                gs_material-mbrsh
                gs_material-meins
                gs_material-maktx
           INTO gv_line
           SEPARATED BY '|'.
    APPEND gv_line TO gt_output.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form DOWNLOAD_TO_PC
*& Uses GUI_DOWNLOAD to transfer data from application server to PC
*&---------------------------------------------------------------------*
FORM download_to_pc.

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      filename                = p_path
      filetype                = 'ASC'
      write_field_separator   = 'X'
    TABLES
      data_tab                = gt_output
    EXCEPTIONS
      file_write_error        = 1
      no_batch                = 2
      gui_refuse_filetransfer = 3
      invalid_type            = 4
      no_authority            = 5
      unknown_error           = 6
      header_not_allowed      = 7
      separator_not_allowed   = 8
      filesize_not_allowed    = 9
      header_too_long         = 10
      dp_error_create         = 11
      dp_error_send           = 12
      dp_error_write          = 13
      unknown_dp_error        = 14
      access_denied           = 15
      dp_out_of_memory        = 16
      disk_full               = 17
      dp_timeout              = 18
      OTHERS                  = 19.

  IF sy-subrc = 0.
    MESSAGE 'Material data downloaded successfully to PC.' TYPE 'S'.
  ELSE.
    MESSAGE TEXT-E01 TYPE 'E'.
  ENDIF.

ENDFORM.
