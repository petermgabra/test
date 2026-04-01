# SAP HCM ABAP Bulk Upload Guide

This guide describes how to use the `ZHR_INFOTYPE_BULK_UPLOAD` program to perform bulk uploads for Infotypes 0008, 0014, and 0015.

## Program Overview

The program `ZHR_INFOTYPE_BULK_UPLOAD` reads a CSV file and creates new records in the selected SAP HCM infotype using the `HR_INFOTYPE_OPERATION` function module.

## Prerequisites

1.  **SAP Access**: Permission to execute transaction `SE38` or `SA38`.
2.  **Authorizations**: Standard HR master data maintenance authorizations for the selected infotypes and personnel numbers.

## CSV File Formats

The file should be a comma-separated values (CSV) file without a header row.

### Infotype 0008 (Basic Pay)
Columns:
1.  `PERNR` (Personnel Number - 8 digits)
2.  `BEGDA` (Start Date - YYYYMMDD)
3.  `ENDDA` (End Date - YYYYMMDD)
4.  `SUBTY` (Subtype - typically '0')
5.  `TRFGR` (Pay Scale Group)
6.  `TRFST` (Pay Scale Level)

### Infotype 0014 (Recurring Payments/Deductions)
Columns:
1.  `PERNR` (Personnel Number - 8 digits)
2.  `BEGDA` (Start Date - YYYYMMDD)
3.  `ENDDA` (End Date - YYYYMMDD)
4.  `LGART` (Wage Type)
5.  `BETRG` (Amount)

### Infotype 0015 (Additional Payments)
Columns:
1.  `PERNR` (Personnel Number - 8 digits)
2.  `BEGDA` (Payment Date - YYYYMMDD)
3.  `ENDDA` (Payment Date - YYYYMMDD)
4.  `LGART` (Wage Type)
5.  `BETRG` (Amount)

## How to Run

1.  Go to transaction `SE38`.
2.  Enter program name `ZHR_INFOTYPE_BULK_UPLOAD` and click **Execute (F8)**.
3.  Click the F4 help on the **File Path** field to select your CSV file from your local machine.
4.  Select the **Infotype** radio button corresponding to your data.
5.  Click **Execute (F8)**.
6.  The program will display a result list (ALV) showing the status (Success/Error) for each personnel number.

## Important Notes

- **Locking**: The program automatically locks each personnel number before processing and unlocks it after.
- **Commit**: A database commit is issued after each successful record creation.
- **Error Handling**: Any errors returned by the SAP standard validation logic will be displayed in the result list.
