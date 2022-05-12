create or replace view V_MEDIA as
select M.*,
       sys.dbms_lob.getlength(M."CONTENT") "CONTENT_SIZE",
       nvl(T.Code,          '')   as Code,
       nvl(T.Carrier,       '')   as Carrier,
       nvl(T.TrackingNr,    '')   as TrackingNr,
       nvl(T.Name,          '')   as Name,
       nvl(T.Person,        '')   as Person,
       nvl(T.Company,       '')   as Company,
       nvl(T.Location,      '')   as Location,
       nvl(F.Fulltext,      '')   as FullText,
       nvl(C.Codelist,      '')   as CodeList,
       nvl(T.TagList,       '')   as TagList,
      substr(''   || --'<strong style="font-size:125%;">'      || M.title || '</strong>' || '<br><br>' ||
      '🗓' || ' ' || to_char(M.TIMESTAMP, 'dd.mm.yyyy hh24:mi:ss') || ' - ' || M.idx || '<br>' ||
      '📷' || ' ' || M.device || '<br>' ||
      '📎' || ' <a href="' || 'dscan/media/files/'|| M.FILE_NAME || '">' || M.FILE_NAME || '</a>' || '<br>' ||
    --'📎' || ' <a href="' || 'dscan/media/files/'|| REGEXP_REPLACE(M.FILE_NAME, '.jpg$|.jpeg$', '.json') || '">' || REGEXP_REPLACE(M.FILE_NAME, '.jpg$|.jpeg$', '.json') || '</a>' || '<br>' ||
      '📃' || ' <a href="' || 'dscan/media/files/'|| REGEXP_REPLACE(M.FILE_NAME, '.json$', '.jpg') || '">' || REGEXP_REPLACE(M.FILE_NAME, '.json$', '.jpg') || '</a>' || '<br>' ||
--      nvl2(C.Codelist, '<hr>'  || C.Codelist
      --, '') ||
      C.Codelist ||
      '', 1, 4000)                           as HTML_Details,
       to_char(M.TIMESTAMP, 'yyyy-mm') month,
       to_char(M.TIMESTAMP, 'yyyy-mm-dd') day,
       to_char(M.TIMESTAMP, 'yyyymmdd-hh24:mi:ss')
--           || decode(count(*) OVER (PARTITION BY T.TIMESTAMP), 1, '', ' ['||count(*) OVER (PARTITION BY T.TIMESTAMP)||']')
         as SET_NAME,
       REGEXP_REPLACE(M.FILE_NAME, '.json$', '.jpg') as IMG
from   MEDIA M
left outer join  V_MEDIA_TAGS         T on T.ID = M.ID -- FILE_NAME = REGEXP_REPLACE(M.FILE_NAME, '.jpg$|.jpeg$', '.json')
left outer join  V_MEDIA_FULLTEXT     F on F.ID = M.ID -- FILE_NAME = REGEXP_REPLACE(M.FILE_NAME, '.jpg$|.jpeg$', '.json')
left outer join  V_MEDIA_BARCODELIST  C on C.ID = M.ID -- FILE_NAME = REGEXP_REPLACE(M.FILE_NAME, '.jpg$|.jpeg$', '.json')
where  M.content_type in ('text/json')
  and  M.type = 'scan'
;


select * from v_media where id = 1442;
select * from v_media where file_name = '2022-05-09 00:13:30.9780_1.json';