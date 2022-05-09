create or replace view V_MEDIA_RECOGNIZED_TEXT
as
with Q as
 (select M.ID,
         M.file_name,
         M.idx,
         M.content_type,
         M.timestamp,
         JT.Text,
         JT.confidence,
         JT.x,
         JT.y,
         JT.w,
         JT.h
  from   Media      M,
         JSON_TABLE
          (M.content, '$' COLUMNS
            (ID Varchar2(32) PATH '$.ID',
             nested path '$.recognizedText[*]' columns
              (Text         Varchar2(4000) PATH '$.text',
               Confidence   Varchar2(100) PATH '$.confidence',
               X            Varchar2(100) PATH '$.x',
               y            Varchar2(100) PATH '$.y',
               w            Varchar2(100) PATH '$.w',
               h            Varchar2(100) PATH '$.h'
              )
            )
          ) JT
 )
Select Q.ID,
       Q.file_name,
       Q.idx,
       Q.content_type,
       Q.timestamp,
       Q.Text,
     --Q.confidence,
     --Q.x,
     --Q.y,
     --Q.w,
     --Q.h
       to_number(Q.confidence , 'fm9999999D9999999999999999999999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''') confidence,
       to_number(Q.x          , 'fm9999999D9999999999999999999999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''') x,
       to_number(Q.y          , 'fm9999999D9999999999999999999999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''') y,
       to_number(Q.w          , 'fm9999999D9999999999999999999999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''') w,
       to_number(Q.h          , 'fm9999999D9999999999999999999999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''') h
from   Q
--where  rtrim(translate (x, '-0123456789.', '            ')) is null
--  and  rtrim(translate (y, '-0123456789.', '            ')) is null
--  and  rtrim(translate (w, '-0123456789.', '            ')) is null
--  and  rtrim(translate (h, '-0123456789.', '            ')) is null
;
