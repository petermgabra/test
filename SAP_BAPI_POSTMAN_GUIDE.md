# Calling SAP BAPI_ACC_DOCUMENT_POST from Postman

This guide provides step-by-step instructions on how to call the SAP BAPI `BAPI_ACC_DOCUMENT_POST` using Postman to create General Ledger (G/L) entries.

## Prerequisites

1.  **SAP Access**: You need access to an SAP system with permissions to use `SE37`, `SOAMANAGER`, and `SICF`.
2.  **Postman**: Installed on your machine.

---

## Step 1: Expose the BAPI as a SOAP Web Service

Since Postman cannot call BAPIs directly via RFC, you must expose it as a Web Service.

1.  **Go to Transaction `SOAMANAGER`** in your SAP GUI.
2.  Navigate to **Service Administration** > **Web Service Configuration**.
3.  Search for Object Name `BAPI_ACC_DOCUMENT_POST`.
4.  Select the service and click **Apply Selection**.
5.  Go to the **Configurations** tab and click **Create Service**.
6.  Provide a Service Name and Binding Name (e.g., `BAPI_ACC_DOC_POST_BINDING`).
7.  In the **Security** tab, choose your authentication method (usually User ID/Password over Transport Security).
8.  Finish the configuration and click on the **Open WSDL document for selected binding** icon to get the WSDL URL.

---

## Step 2: Configure Postman Request

1.  **Method**: `POST`
2.  **URL**: Enter the endpoint URL obtained from the WSDL in SOAMANAGER (it usually ends in something like `/sap/bc/srt/rfc/sap/bapi_acc_document_post/...`).
3.  **Headers**:
    *   `Content-Type`: `text/xml; charset=utf-8`
    *   `Authorization`: Basic Auth (Enter your SAP Username and Password)
    *   `SOAPAction`: (Optional, depending on SAP version, can be found in WSDL)

4.  **Body**: Select `raw` and choose `XML`.

---

## Step 3: Sample XML Payload (G/L Posting)

The following is a sample SOAP request to post a G/L entry with two line items (Debit and Credit).

```xml
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:sap-com:document:sap:rfc:functions">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:BAPI_ACC_DOCUMENT_POST>
         <DOCUMENTHEADER>
            <OBJ_TYPE>IDOC</OBJ_TYPE>
            <USERNAME>SAP_USER</USERNAME>
            <HEADER_TXT>POSTMAN TEST</HEADER_TXT>
            <COMP_CODE>1000</COMP_CODE>
            <DOC_DATE>2023-10-27</DOC_DATE>
            <PSTNG_DATE>2023-10-27</PSTNG_DATE>
            <DOC_TYPE>SA</DOC_TYPE>
            <REF_DOC_NO>POSTMAN001</REF_DOC_NO>
         </DOCUMENTHEADER>
         <ACCOUNTGL>
            <!-- Debit Line Item -->
            <item>
               <ITEMNO_ACC>0000000001</ITEMNO_ACC>
               <GL_ACCOUNT>0000400000</GL_ACCOUNT>
               <ITEM_TEXT>Debit Entry</ITEM_TEXT>
               <COMP_CODE>1000</COMP_CODE>
            </item>
            <!-- Credit Line Item -->
            <item>
               <ITEMNO_ACC>0000000002</ITEMNO_ACC>
               <GL_ACCOUNT>0000100000</GL_ACCOUNT>
               <ITEM_TEXT>Credit Entry</ITEM_TEXT>
               <COMP_CODE>1000</COMP_CODE>
            </item>
         </ACCOUNTGL>
         <CURRENCYAMOUNT>
            <!-- Debit Amount -->
            <item>
               <ITEMNO_ACC>0000000001</ITEMNO_ACC>
               <CURRENCY>USD</CURRENCY>
               <AMT_DOCCUR>100.00</AMT_DOCCUR>
            </item>
            <!-- Credit Amount (Note the negative sign) -->
            <item>
               <ITEMNO_ACC>0000000002</ITEMNO_ACC>
               <CURRENCY>USD</CURRENCY>
               <AMT_DOCCUR>-100.00</AMT_DOCCUR>
            </item>
         </CURRENCYAMOUNT>
      </urn:BAPI_ACC_DOCUMENT_POST>
   </soapenv:Body>
</soapenv:Envelope>
```

### Key Field Descriptions:
- **DOCUMENTHEADER**:
    - `COMP_CODE`: Your Company Code.
    - `DOC_TYPE`: Document Type (e.g., 'SA' for G/L Account Document).
- **ACCOUNTGL**:
    - `ITEMNO_ACC`: Sequence number (must match in `CURRENCYAMOUNT`).
    - `GL_ACCOUNT`: G/L Account Number (pad with leading zeros if necessary).
- **CURRENCYAMOUNT**:
    - `AMT_DOCCUR`: Amount. **Credit entries must have a negative sign.**

---

## Step 4: Important - Commit Transaction

`BAPI_ACC_DOCUMENT_POST` does **not** issue a database commit. In a standard RFC call, you would call `BAPI_TRANSACTION_COMMIT` immediately after.

**Options for Postman:**
1.  **Wrapper Function**: Create a custom Z-function module in SAP that calls `BAPI_ACC_DOCUMENT_POST` and then `BAPI_TRANSACTION_COMMIT`. Expose this Z-function as a Web Service instead.
2.  **Postman Test Script (Experimental)**: SAP SOAP services usually maintain session state via cookies if enabled. However, the most reliable way for external calls is the Wrapper Function.

---

## Troubleshooting

- **Error RW 33 - Balance in Transaction Currency**: This is a common error (e.g., `Balance in Transaction Currency 0.01 (AED)`).
    - **Cause**: SAP requires that the sum of all `AMT_DOCCUR` values in the `CURRENCYAMOUNT` table must be exactly zero.
    - **Fix**: Check all line items. Even a 0.01 difference will cause this error. Ensure that your debit amounts (positive) and credit amounts (negative) balance perfectly.
- **Account Determination**: Ensure the G/L accounts are valid for the company code and document type.
- **Leading Zeros**: SAP often expects G/L accounts and Customer/Vendor numbers to be 10 digits long, padded with leading zeros (e.g., `0000123456`).
