create or replace view V_MEDIA_DETECTED_BARCODES
as
with Q as
 (select M.ID,
         M.file_name,
         M.idx,
         M.content_type,
         M.timestamp,
         JT.Symbology,
         JT.Payload
  from   Media      M,
         JSON_TABLE
          (M.content, '$' COLUMNS
            (ID Varchar2(32) PATH '$.ID',
             nested path '$.detectedBarcodes[*]' columns
              (Payload      Varchar2(4000) PATH '$.payload',
               Symbology    Varchar2(100) PATH '$.symbology'
              )
            )
          ) JT
  UNION ALL
  select M.ID,
         M.file_name,
         M.idx,
         M.content_type,
         M.timestamp,
         JT.Symbology,
         JT.Payload
  from   Media      M,
         JSON_TABLE
          (M.content, '$' COLUMNS
            (ID Varchar2(32) PATH '$.ID',
             nested path '$.recognizedCodes[*]' columns
              (Payload      Varchar2(4000) PATH '$.payload',
               Symbology    Varchar2(100) PATH '$.symbology'
              )
            )
          ) JT
 )
Select Q.ID,
       Q.file_name,
       Q.idx,
       Q.content_type,
       Q.timestamp,
       Q.Symbology,
       Q.payload
from   Q
where  Payload is not null
/
