create or replace view V_MEDIA_AUTOTAGGING as
(select MAT.type,
        MAT.ID as TAG_SOURCE_ID,
        MRC.ID,
        MRC.file_name,
        MRC.Symbology as matchcode1,
        MRC.payload   as matchcode2,
        ''            as matchcode3,
        MAT.tag_name,
        nvl(REGEXP_SUBSTR(MRC.Payload, MAT.re_result_substr), MAT.re_result_substr) as tag_value,
        MAT.re_pattern1,
        MAT.re_pattern2,
        MAT.re_pattern3
 from   Media_Autotagging MAT
 join   V_MEDIA_DETECTED_BARCODES MRC
   on   REGEXP_LIKE (MRC.Symbology, MAT.re_pattern1)
  and   REGEXP_LIKE (MRC.Payload,   MAT.re_pattern2)
 where  MAT.type = 'code'
 UNION ALL
 select MAT.type,
        MAT.ID, -- TAG_SOURCE_ID
        MRT.ID,
        MRT.file_name,
        MRT.Text, -- matchcode1
        '',       -- matchcode2
        '',       -- matchcode3
        MAT.tag_name,
        nvl(REGEXP_SUBSTR(MRT.Text, MAT.re_result_substr, 1, 1, 'i'), MAT.re_result_substr) as tag_value,
      --nvl(REGEXP_SUBSTR(MRT.Text, MAT.re_result_substr), MRT.Text) as tag_value,
        MAT.re_pattern1,
        MAT.re_pattern2,
        MAT.re_pattern3
 from   Media_Autotagging MAT
 join   V_MEDIA_RECOGNIZED_TEXT MRT
   on   REGEXP_LIKE (MRT.Text, MAT.re_pattern1, 'i')
 where  MAT.type = 'text'
UNION ALL
 select 'dict',
        'NAME_DICTIONARY_'||NAD.ID,
        MRT.ID,
        MRT.file_name,
        MRT.text, -- matchcode1
        '',       -- matchcode2
        '',       -- matchcode3
        'Person', -- tag_name,
        NAD.name, -- tag_value
        NAD.re_pattern1,
        '', --re_pattern2
        ''  --MAT.re_pattern3
 from   NAME_DICTIONARY NAD
 join   V_MEDIA_RECOGNIZED_TEXT MRT
   on   REGEXP_LIKE (MRT.Text, NAD.re_pattern1)
)
/

select * from V_MEDIA_AUTOTAGGING where id = 1442;

