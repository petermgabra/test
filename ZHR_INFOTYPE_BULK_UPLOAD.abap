*&---------------------------------------------------------------------*
*& Report ZHR_INFOTYPE_BULK_UPLOAD
*&---------------------------------------------------------------------*
*& This program enables bulk upload of records for Infotypes 0008,
*& 0014, and 0015 using HR_INFOTYPE_OPERATION.
*&---------------------------------------------------------------------*
REPORT zhr_infotype_bulk_upload.

TABLES: pernr.

*--- Data Declarations ---*
TYPES: BEGIN OF ty_csv,
         line TYPE string,
       END OF ty_csv.

DATA: gt_csv_data TYPE TABLE OF string,
      gv_line     TYPE string.

DATA: gv_infty TYPE infty.
DATA: lt_file_table TYPE filetable,
      ls_file_table TYPE file_table,
      lv_rc         TYPE i.

DATA: gt_p0008 TYPE TABLE OF p0008,
      gs_p0008 TYPE p0008,
      gt_p0014 TYPE TABLE OF p0014,
      gs_p0014 TYPE p0014,
      gt_p0015 TYPE TABLE OF p0015,
      gs_p0015 TYPE p0015,
      gt_p2010 TYPE TABLE OF p2010,
      gs_p2010 TYPE p2010.

TYPES: BEGIN OF ty_results,
         pernr TYPE pernr_d,
         msgty TYPE bapi_mtype,
         message TYPE string,
       END OF ty_results.

DATA: gt_results TYPE TABLE OF ty_results,
      gs_results TYPE ty_results.

*--- Selection Screen ---*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_file TYPE string LOWER CASE.
  SELECTION-SCREEN SKIP.
  PARAMETERS: p_0008 RADIOBUTTON GROUP r1 DEFAULT 'X',
              p_0014 RADIOBUTTON GROUP r1,
              p_0015 RADIOBUTTON GROUP r1,
              p_2010 RADIOBUTTON GROUP r1.
SELECTION-SCREEN END OF BLOCK b1.

*--- F4 for File Path ---*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = 'Select File'
      default_filename        = ''
      file_filter             = 'CSV Files (*.csv)|*.csv'
    CHANGING
      file_table              = lt_file_table
      rc                      = lv_rc.

  IF lv_rc > 0.
    READ TABLE lt_file_table INTO ls_file_table INDEX 1.
    p_file = ls_file_table-filename.
  ENDIF.

START-OF-SELECTION.
  IF p_file IS INITIAL.
    MESSAGE 'Please select a file' TYPE 'E'.
  ENDIF.

  IF p_0008 = 'X'.
    gv_infty = '0008'.
  ELSEIF p_0014 = 'X'.
    gv_infty = '0014'.
  ELSEIF p_0015 = 'X'.
    gv_infty = '0015'.
  ELSEIF p_2010 = 'X'.
    gv_infty = '2010'.
  ENDIF.

  PERFORM upload_file.
  PERFORM parse_data.
  PERFORM process_records.

*--- Subroutines ---*
FORM upload_file.
  DATA: lv_filename TYPE string.
  lv_filename = p_file.

  CALL METHOD cl_gui_frontend_services=>gui_upload
    EXPORTING
      filename                = lv_filename
      filetype                = 'ASC'
    CHANGING
      data_tab                = gt_csv_data
    EXCEPTIONS
      file_open_error         = 1
      file_read_error          = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      not_supported_by_gui    = 17
      error_no_gui            = 18
      OTHERS                  = 19.

  IF sy-subrc <> 0.
    MESSAGE 'Error uploading file' TYPE 'E'.
  ENDIF.
ENDFORM.

FORM parse_data.
  DATA: lt_fields TYPE TABLE OF string,
        lv_line   TYPE string.

  LOOP AT gt_csv_data INTO lv_line.
    " Skip header if needed (assuming first line is data for simplicity)
    REFRESH lt_fields.
    SPLIT lv_line AT ',' INTO TABLE lt_fields.

    CASE gv_infty.
      WHEN '0008'.
        CLEAR gs_p0008.
        READ TABLE lt_fields INTO gs_p0008-pernr INDEX 1.
        READ TABLE lt_fields INTO gs_p0008-begda INDEX 2.
        READ TABLE lt_fields INTO gs_p0008-endda INDEX 3.
        READ TABLE lt_fields INTO gs_p0008-subty INDEX 4.
        READ TABLE lt_fields INTO gs_p0008-trfgr INDEX 5.
        READ TABLE lt_fields INTO gs_p0008-trfst INDEX 6.
        " For IT0008, you usually need more fields like Wage Types, but this is a base.
        APPEND gs_p0008 TO gt_p0008.

      WHEN '0014'.
        CLEAR gs_p0014.
        READ TABLE lt_fields INTO gs_p0014-pernr INDEX 1.
        READ TABLE lt_fields INTO gs_p0014-begda INDEX 2.
        READ TABLE lt_fields INTO gs_p0014-endda INDEX 3.
        READ TABLE lt_fields INTO gs_p0014-lgart INDEX 4.
        READ TABLE lt_fields INTO gs_p0014-betrg INDEX 5.
        gs_p0014-subty = gs_p0014-lgart. " Subtype is Wage Type
        APPEND gs_p0014 TO gt_p0014.

      WHEN '0015'.
        CLEAR gs_p0015.
        READ TABLE lt_fields INTO gs_p0015-pernr INDEX 1.
        READ TABLE lt_fields INTO gs_p0015-begda INDEX 2.
        " For IT0015, ENDDA is often same as BEGDA
        READ TABLE lt_fields INTO gs_p0015-endda INDEX 3.
        READ TABLE lt_fields INTO gs_p0015-lgart INDEX 4.
        READ TABLE lt_fields INTO gs_p0015-betrg INDEX 5.
        gs_p0015-subty = gs_p0015-lgart. " Subtype is Wage Type
        APPEND gs_p0015 TO gt_p0015.

      WHEN '2010'.
        CLEAR gs_p2010.
        READ TABLE lt_fields INTO gs_p2010-pernr INDEX 1.
        READ TABLE lt_fields INTO gs_p2010-begda INDEX 2.
        READ TABLE lt_fields INTO gs_p2010-endda INDEX 3.
        READ TABLE lt_fields INTO gs_p2010-lgart INDEX 4.
        READ TABLE lt_fields INTO gs_p2010-betrg INDEX 5.
        READ TABLE lt_fields INTO gs_p2010-anzhl INDEX 6.
        gs_p2010-subty = gs_p2010-lgart. " Subtype is Wage Type
        APPEND gs_p2010 TO gt_p2010.
    ENDCASE.
  ENDLOOP.
ENDFORM.

FORM process_records.
  DATA: ls_return TYPE bapireturn1.

  CASE gv_infty.
    WHEN '0008'.
      LOOP AT gt_p0008 INTO gs_p0008.
        PERFORM call_infotype_operation USING gs_p0008-pernr gv_infty gs_p0008-subty gs_p0008.
      ENDLOOP.

    WHEN '0014'.
      LOOP AT gt_p0014 INTO gs_p0014.
        PERFORM call_infotype_operation USING gs_p0014-pernr gv_infty gs_p0014-subty gs_p0014.
      ENDLOOP.

    WHEN '0015'.
      LOOP AT gt_p0015 INTO gs_p0015.
        PERFORM call_infotype_operation USING gs_p0015-pernr gv_infty gs_p0015-subty gs_p0015.
      ENDLOOP.

    WHEN '2010'.
      LOOP AT gt_p2010 INTO gs_p2010.
        PERFORM call_infotype_operation USING gs_p2010-pernr gv_infty gs_p2010-subty gs_p2010.
      ENDLOOP.
  ENDCASE.

  PERFORM display_results.
ENDFORM.

FORM call_infotype_operation USING pv_pernr TYPE pernr_d
                                   pv_infty TYPE infty
                                   pv_subty TYPE subty
                                   pv_record TYPE any.

  DATA: ls_return TYPE bapireturn1.

  " Lock Personnel Number
  CALL FUNCTION 'BAPI_EMPLOYEE_ENQUEUE'
    EXPORTING
      number = pv_pernr
    IMPORTING
      return = ls_return.

  IF ls_return-type <> 'E' AND ls_return-type <> 'A'.
    " Call HR_INFOTYPE_OPERATION
    CALL FUNCTION 'HR_INFOTYPE_OPERATION'
      EXPORTING
        infty         = pv_infty
        number        = pv_pernr
        subtype       = pv_subty
        operation     = 'INS'
        record        = pv_record
        dialog_mode   = '0'
        nocommit      = ' '
      IMPORTING
        return        = ls_return.

    IF ls_return-type <> 'E' AND ls_return-type <> 'A'.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
      gs_results-msgty = 'S'.
      gs_results-message = 'Successfully Created'.
    ELSE.
      gs_results-msgty = 'E'.
      gs_results-message = ls_return-message.
    ENDIF.

    " Unlock Personnel Number
    CALL FUNCTION 'BAPI_EMPLOYEE_DEQUEUE'
      EXPORTING
        number = pv_pernr.
  ELSE.
    gs_results-msgty = 'E'.
    gs_results-message = ls_return-message.
  ENDIF.

  gs_results-pernr = pv_pernr.
  APPEND gs_results TO gt_results.
ENDFORM.

FORM display_results.
  DATA: lo_alv TYPE REF TO cl_salv_table.

  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = gt_results ).

      lo_alv->display( ).
    CATCH cx_salv_msg.
      WRITE: / 'Error displaying ALV'.
  ENDTRY.
ENDFORM.
