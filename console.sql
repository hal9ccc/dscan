select * from media;

select * from TRACE where ts > systimestamp - numtodsinterval(5, 'minute') order by ts, nr;

/*
** from https://oracle-base.com/articles/misc/oracle-rest-data-services-ords-restful-web-services-handling-media
*/

drop table media;

CREATE TABLE media (
  id             NUMBER(10)     NOT NULL,
  content_type   VARCHAR2(100)  NOT NULL,
  file_name      VARCHAR2(100)  NOT NULL,
  content        BLOB           ,
  type           VARCHAR2(100)  NOT NULL,
  title          VARCHAR2(100)  NOT NULL,
  timestamp      timestamp      NOT NULL,
  idx            int            NOT NULL,
  device         VARCHAR2(100)
);

alter table media modify content null;


ALTER TABLE media ADD (
  CONSTRAINT media_pk PRIMARY KEY (id)
);

ALTER TABLE media ADD (
  CONSTRAINT media_uk UNIQUE (file_name)
);

CREATE SEQUENCE media_seq;

CREATE OR REPLACE PACKAGE media_api AS

  PROCEDURE upload (
    p_timestamp     IN  varchar2,
    p_idx           IN  media.idx             %TYPE,
    p_file_name     IN  media.file_name      %TYPE,
    p_content_type  IN  media.content_type   %TYPE,
    p_content       IN  media.content        %TYPE,
    p_type          IN  media.type           %TYPE,
    p_title         IN  media.title          %TYPE,
    p_device        IN  media.device         %TYPE
   );

  PROCEDURE download (p_file_name  IN  media.file_name%TYPE);

END;
/


CREATE OR REPLACE PACKAGE BODY media_api AS

  PROCEDURE upload (
    p_timestamp     IN  varchar2,
    p_idx           IN  media.idx             %TYPE,
    p_file_name     IN  media.file_name       %TYPE,
    p_content_type  IN  media.content_type    %TYPE,
    p_content       IN  media.content         %TYPE,
    p_type          IN  media.type            %TYPE,
    p_title         IN  media.title           %TYPE,
    p_device        IN  media.device          %TYPE
   )
   is
    v_id                media.ID              %TYPE;
    v_file_name         media.file_name       %TYPE;
    v_title             media.title           %TYPE;
    v_timestamp         media.timestamp       %TYPE;

  BEGIN
    trc.ENTER('upload', 'p_file_name', p_file_name, 'ts', p_timestamp);

    begin
        v_timestamp := nvl(to_timestamp(p_timestamp, 'yyyy-mm-dd hh24:mi:ss,ff4'), SYSTIMESTAMP);
    exception
      when others then
        trc.err('Failed to convert timestamp: '||p_timestamp);
        v_timestamp := SYSTIMESTAMP;
    end;

    v_file_name := p_file_name; --to_char(v_timestamp, 'YYYYMMDD-HH24:MI:SS,FF4')||'_'||ltrim(to_char(p_idx, '0000'))||'.jpg';
    v_title     := nvl(p_title, to_char(v_timestamp, 'YYYYMMDD-HH24:MI:SS')||'-'||ltrim(to_char(p_idx, '0000')));

    v_id := media_seq.NEXTVAL;

    INSERT INTO media (id, content, content_type, file_name, "TYPE", title, timestamp, idx, device)
    VALUES (v_id, p_content, p_content_type, v_file_name, p_type, v_title, v_timestamp, p_idx, p_device);

    COMMIT;
    trc.EXIT('upload complete ('||DBMS_LOB.GETLENGTH(p_content)||' byte)');

  EXCEPTION
    when others then
      trc.err('error saving media content');
      raise;
  END;


  PROCEDURE download (p_file_name  IN  media.file_name%TYPE) IS
    l_rec  media%ROWTYPE;
  BEGIN
    trc.ENTER('download', 'p_file_name', p_file_name);
    SELECT *
    INTO   l_rec
    FROM   media
    WHERE  file_name = p_file_name;

    OWA_UTIL.mime_header(l_rec.content_type, FALSE);
    HTP.p('Content-Length: ' || DBMS_LOB.getlength(l_rec.content));
    HTP.p('Content-Disposition: filename="' || l_rec.file_name || '"');
    OWA_UTIL.http_header_close;

    WPG_DOCLOAD.download_file(l_rec.content);
    trc.EXIT('download');
  END;

END;
/



CONN dscan/dscan@dm1/xepdb2

BEGIN
  ORDS.enable_schema(
    p_enabled             => TRUE,
    p_schema              => 'DSCAN',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'dscan',
    p_auto_rest_auth      => FALSE
  );

  COMMIT;
END;
/


BEGIN
  ORDS.delete_module(p_module_name => 'media');

  ORDS.define_module(
    p_module_name    => 'media',
    p_base_path      => 'media/',
    p_items_per_page => 0);

  COMMIT;
END;
/




BEGIN
  ORDS.define_template(
    p_module_name    => 'media',
    p_pattern        => 'files/');

  ORDS.define_handler(
    p_module_name    => 'media',
    p_pattern        => 'files/',
    p_method         => 'POST',
    p_source_type    => ORDS.source_type_plsql,
    p_source         => q'[
    BEGIN
      media_api.upload(
        p_file_name    => :filename,
        p_content_type => :content_type,
        p_content      => :body,
        p_type         => :type,
        p_title        => :title,
        p_timestamp    => :timestamp,
        p_idx          => :idx,
        p_device       => :device
      );

      :status_code := 201;
      :message := 'Created ' || :filename;
    EXCEPTION
      WHEN OTHERS THEN
        :status_code := 400;
        :message := SQLERRM;
        :errorstack := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    END;]',
    p_items_per_page => 0);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'media',
      p_pattern            => 'files/',
      p_method             => 'POST',
      p_name               => 'device',
      p_bind_variable_name => 'device',
      p_source_type        => 'HEADER',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'media',
      p_pattern            => 'files/',
      p_method             => 'POST',
      p_name               => 'filename',
      p_bind_variable_name => 'filename',
      p_source_type        => 'HEADER',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'media',
      p_pattern            => 'files/',
      p_method             => 'POST',
      p_name               => 'idx',
      p_bind_variable_name => 'idx',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'media',
      p_pattern            => 'files/',
      p_method             => 'POST',
      p_name               => 'message',
      p_bind_variable_name => 'message',
      p_source_type        => 'RESPONSE',
      p_param_type         => 'STRING',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'media',
      p_pattern            => 'files/',
      p_method             => 'POST',
      p_name               => 'errorstack',
      p_bind_variable_name => 'errorstack',
      p_source_type        => 'RESPONSE',
      p_param_type         => 'STRING',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'media',
      p_pattern            => 'files/',
      p_method             => 'POST',
      p_name               => 'timestamp',
      p_bind_variable_name => 'timestamp',
      p_source_type        => 'HEADER',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'media',
      p_pattern            => 'files/',
      p_method             => 'POST',
      p_name               => 'title',
      p_bind_variable_name => 'title',
      p_source_type        => 'HEADER',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'media',
      p_pattern            => 'files/',
      p_method             => 'POST',
      p_name               => 'type',
      p_bind_variable_name => 'type',
      p_source_type        => 'HEADER',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);


  COMMIT;
END;
/

BEGIN
  ORDS.define_template(
    p_module_name    => 'media',
    p_pattern        => 'files/:filename');

  ORDS.define_handler(
    p_module_name    => 'media',
    p_pattern        => 'files/:filename',
    p_method         => 'GET',
    p_source_type    => ORDS.source_type_plsql,
    p_source         => q'[    BEGIN
      media_api.download (p_file_name  => :filename);
    EXCEPTION
      WHEN OTHERS THEN
        :status_code := 404;
        :message := SQLERRM;
    END;]',
    p_items_per_page => 0);

  ORDS.define_parameter(
    p_module_name        => 'media',
    p_pattern            => 'files/:filename',
    p_method             => 'GET',
    p_name               => 'message',
    p_bind_variable_name => 'message',
    p_source_type        => 'RESPONSE',
    p_access_method      => 'OUT'
  );

  COMMIT;
END;

CREATE OR REPLACE FUNCTION listagg_clob (
column_name IN VARCHAR2,
table_name  IN VARCHAR2,
where_cond  IN VARCHAR2 DEFAULT NULL,
order_by    IN VARCHAR2 DEFAULT NULL,
delimiter   IN VARCHAR2 DEFAULT ',')
RETURN CLOB
IS
ret_clob CLOB;
BEGIN
EXECUTE IMMEDIATE q'!select replace(replace(XmlAgg(
                  XmlElement("a", !' || column_name ||')
                  order by ' ||nvl(order_by,'1') ||
                  q'!)
                  .getClobVal(),
              '<a>', ''),
            '</a>','!'|| delimiter ||q'!') as aggname
   from !' || table_name || q'!
  where  !' || nvl(where_cond,' 1=1') INTO ret_clob;
RETURN ret_clob;
END;
/



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
      substr(''    || '<strong style="font-size:125%;">'      || M.title || '</strong>' || '<br><br>' ||
      '🗓' || ' ' || to_char(M.TIMESTAMP, 'dd.mm.yyyy hh24:mi:ss') || ' - ' || M.idx || '<br>' ||
      '📷' || ' ' || M.device || '<br>' ||
      '📃' || ' <a href="' || 'http://localhost/ords/dscan/media/files/'|| M.FILE_NAME || '">' || M.FILE_NAME || '</a>' || '<br>' ||
      '📎' || ' <a href="' || 'http://localhost/ords/dscan/media/files/'|| REGEXP_REPLACE(M.FILE_NAME, '.jpg$|.jpeg$', '.json') || '">' || REGEXP_REPLACE(M.FILE_NAME, '.jpg$|.jpeg$', '.json') || '</a>' || '<br>' ||
      nvl2(C.Codelist, '<hr>'  || C.Codelist
      , '') ||
      '', 1, 4000)                           as HTML_Details,
       to_char(M.TIMESTAMP, 'yyyy-mm') month,
       to_char(M.TIMESTAMP, 'yyyy-mm-dd') day,
       to_char(M.TIMESTAMP, 'yyyymmdd-hh24:mi:ss')
--           || decode(count(*) OVER (PARTITION BY T.TIMESTAMP), 1, '', ' ['||count(*) OVER (PARTITION BY T.TIMESTAMP)||']')
         as SET_NAME,
       'http://mbp-mschulze.local/ords/dscan/media/files/'|| M.FILE_NAME as IMG
from   MEDIA            M
left outer join  V_MEDIA_TAGS     T on T.FILE_NAME = REGEXP_REPLACE(M.FILE_NAME, '.jpg$|.jpeg$', '.json')
left outer join  V_MEDIA_FULLTEXT F on F.FILE_NAME = REGEXP_REPLACE(M.FILE_NAME, '.jpg$|.jpeg$', '.json')
left outer join  V_MEDIA_CODELIST C on C.FILE_NAME = REGEXP_REPLACE(M.FILE_NAME, '.jpg$|.jpeg$', '.json')
where  M.content_type in ('image/jpg')
;

create table media_details
as
 (select  ID,
          CONTENT_TYPE,
          FILE_NAME,
          TYPE,
          TITLE,
          TIMESTAMP,
          IDX,
          CONTENT_SIZE,
          DEVICE,
          CODE,
          CARRIER,
          TRACKINGNR,
          NAME,
          PERSON,
          COMPANY,
          LOCATION,
          FULLTEXT,
          CODELIST,
          TAGLIST,
          HTML_DETAILS,
          MONTH,
          DAY,
          SET_NAME,
          IMG
  from v_media
 )
;

drop table media_details;
select * from media_details;
select count(*) from media_details;
delete from media_details where rownum < 38;

create or replace procedure update_media_details
 (strID Varchar2 default null,
  tsStart Timestamp with time zone default null
 ) is
begin
  MERGE INTO media_details T USING
    (select   *
     from     v_media
     where   (ID         = strID   or strID   is null)
      and    (Timestamp >= tsStart or tsStart is null)
    ) Q
    ON (T.ID = Q.ID)
    WHEN MATCHED THEN UPDATE
    SET CONTENT_TYPE  = Q.CONTENT_TYPE,
        TYPE          = Q.TYPE,
        TITLE         = Q.TITLE,
        TIMESTAMP     = Q.TIMESTAMP,
        IDX           = Q.IDX,
        CONTENT_SIZE  = Q.CONTENT_SIZE,
        CODE          = Q.CODE,
        CARRIER       = Q.CARRIER,
        TRACKINGNR    = Q.TRACKINGNR,
        NAME          = Q.NAME,
        PERSON        = Q.PERSON,
        COMPANY       = Q.COMPANY,
        LOCATION      = Q.LOCATION,
        DEVICE        = Q.DEVICE,
        FULLTEXT      = Q.FULLTEXT,
        CODELIST      = Q.CODELIST,
        TAGLIST       = Q.TAGLIST,
        HTML_DETAILS  = Q.HTML_DETAILS,
        MONTH         = Q.MONTH,
        DAY           = Q.DAY,
        SET_NAME      = Q.SET_NAME,
        IMG           = Q.IMG
    WHEN NOT MATCHED THEN INSERT VALUES (
        Q.ID,
        Q.CONTENT_TYPE,
        Q.FILE_NAME,
        Q.TYPE,
        Q.TITLE,
        Q.TIMESTAMP,
        Q.IDX,
        Q.CONTENT_SIZE,
        Q.DEVICE,
        Q.CODE,
        Q.CARRIER,
        Q.TRACKINGNR,
        Q.NAME,
        Q.PERSON,
        Q.COMPANY,
        Q.LOCATION,
        Q.FULLTEXT,
        Q.CODELIST,
        Q.TAGLIST,
        Q.HTML_DETAILS,
        Q.MONTH,
        Q.DAY,
        Q.SET_NAME,
        Q.IMG
    )
    ;
end;

begin
  update_media_details;
end;

select * from v_media;

select * from media_details;
select REGEXP_REPLACE('sfkjdsfh.jpeg', '.jpg$|.jpeg$', '.json') from dual;













































/*

CONTENT_TYPE=image/jpg
FILE_NAME=bike.jpeg

curl -X POST --data-binary @./${FILE_NAME} \
  -H "Content-Type: ${CONTENT_TYPE}" \
  -H "filename: ${FILE_NAME}" \
  http://localhost/ords/dscan/media/files/
{"message":"file uploaded"}
$




create table media_json
(
  id          NUMBER(10)     NOT NULL,
  file_name   VARCHAR2(100)  NOT NULL,
  content     clob constraint media_json_chk check (content is json (with unique keys))
);
/

/* tolerant to_number */
create or replace function To_To_Number (s Varchar2) return number is
begin
  DBMS_OUTPUT.PUT_LINE('['||s||']');
  return to_number(s, 'S9999999D9999999999999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''');
exception when others then
  DBMS_OUTPUT.PUT_LINE('['||s||']');
  DBMS_OUTPUT.PUT_LINE(''||DBMS_UTILITY.FORMAT_ERROR_STACK());
  return null;
end;


create or replace view V_MEDIA_RECOGNIZEDTEXT
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


create or replace view V_MEDIA_RECOGNIZEDCODES
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
;


select to_number('-0.00017175078392809', 'fm9999999D9999999999999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''') from dual;

to_number(Q.confidence, 'fm9999999D9999999999999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''')


select text, count(*) anz
from   V_MEDIA_RECOGNIZEDTEXT
group by text
order by 2 desc;



select * from V_MEDIA_RECOGNIZEDTEXT order by id, h desc, confidence desc;
select * from V_MEDIA_RECOGNIZEDCODES order by file_name;

select * from V_MEDIA_RECOGNIZEDTEXT where rtrim(translate (confidence, '-0123456789.', '            ')) is not null;

select * from Media order by 1;
select * from Media where id = 641;


select M.*, M.CONTENT.id from media_json M;

CREATE SEQUENCE NAME_DICTIONARY_seq;

--drop TABLE NAME_DICTIONARY;

CREATE TABLE NAME_DICTIONARY (
  id                  NUMBER default NAME_DICTIONARY_seq.NEXTVAL NOT NULL,
  re_pattern1         VARCHAR2(100)   NOT NULL,
  name                VARCHAR2(100)   NOT NULL,
  type                VARCHAR2(10),
  original_id         VARCHAR2(100)
);

ALTER TABLE NAME_DICTIONARY ADD (
  CONSTRAINT NAME_DICTIONARY_PK PRIMARY KEY (id)
);


CREATE TABLE MEDIA_AUTOTAGGING (
  id                  VARCHAR2(100)  NOT NULL,
  type                VARCHAR2(10)   NOT NULL,
  re_pattern1         VARCHAR2(100),
  re_pattern2         VARCHAR2(100),
  re_pattern3         VARCHAR2(100),
  tag_name            VARCHAR2(100)  NOT NULL,
  re_result_substr    VARCHAR2(100)  NOT NULL
);

select * from Media_Autotagging order by 1;

create or replace view V_MEDIA_AUTOTAGGING
as
(select MAT.type,
        MAT.ID,
        MRC.file_name,
        MRC.Symbology as matchcode1,
        MRC.payload   as matchcode2,
        ''            as matchcode3,
        MAT.tag_name,
        REGEXP_SUBSTR(MRC.Payload, MAT.re_result_substr) as tag_value,
        MAT.re_pattern1,
        MAT.re_pattern2,
        MAT.re_pattern3
 from   Media_Autotagging MAT
 join   V_MEDIA_RECOGNIZEDCODES MRC
   on   REGEXP_LIKE (MRC.Symbology, MAT.re_pattern1)
  and   REGEXP_LIKE (MRC.Payload,   MAT.re_pattern2)
 where  MAT.type = 'code'
 UNION ALL
 select MAT.type,
        MAT.ID,
        MRT.file_name,
        MRT.Text, -- matchcode1
        '',       -- matchcode2
        '',       -- matchcode3
        MAT.tag_name,
        nvl(REGEXP_SUBSTR(MRT.Text, MAT.re_result_substr, 1, 1, 'i'), '') as tag_value,
      --nvl(REGEXP_SUBSTR(MRT.Text, MAT.re_result_substr), MRT.Text) as tag_value,
        MAT.re_pattern1,
        MAT.re_pattern2,
        MAT.re_pattern3
 from   Media_Autotagging MAT
 join   V_MEDIA_RECOGNIZEDTEXT MRT
   on   REGEXP_LIKE (MRT.Text, MAT.re_pattern1, 'i')
 where  MAT.type = 'text'
UNION ALL
 select 'dict',
        'NAME_DICTIONARY_'||NAD.ID,
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
 join   V_MEDIA_RECOGNIZEDTEXT MRT
   on   REGEXP_LIKE (MRT.Text, NAD.re_pattern1)
);

select T.rowid, T.* from MEDIA_AUTOTAGGING T;
select Q.* from V_MEDIA_AUTOTAGGING Q;
select Q.* from V_MEDIA_AUTOTAGGING Q where id = 'Company_Text_001';

select   Q.ID,
         Q.file_name,
         Q.tag_name,
         Q.tag_value,
         count(*) as tag_count
from     V_MEDIA_AUTOTAGGING Q
group by Q.ID,
         Q.file_name,
         Q.tag_name,
         Q.tag_value
;


select text, count(*) cnt
from   V_MEDIA_RECOGNIZEDTEXT
group by text
order by 2 desc;


select *
from   V_MEDIA_RECOGNIZEDTEXT
where lower(Text) like '%dpd%'
order by 2 desc;



delete media;


create or replace view V_DistinctTags
as
select   DISTINCT
         M.ID,
         M.file_name,
         T.Tag_name,
         ltrim(rtrim(T.Tag_value)) as Tag_Value,
         rtrim(ltrim(Max(decode(T.tag_name, 'Type',       ltrim(rtrim(T.Tag_value)), '')))) as Type,
         rtrim(ltrim(Max(decode(T.tag_name, 'Code',       ltrim(rtrim(T.Tag_value)), '')))) as Code,
         rtrim(ltrim(Max(decode(T.tag_name, 'Name',       ltrim(rtrim(T.Tag_value)), '')))) as Name,
         rtrim(ltrim(Max(decode(T.tag_name, 'Person',     ltrim(rtrim(T.Tag_value)), '')))) as Person,
         rtrim(ltrim(Max(decode(T.tag_name, 'Carrier',    ltrim(rtrim(T.Tag_value)), '')))) as Carrier,
         rtrim(ltrim(Max(decode(T.tag_name, 'Company',    ltrim(rtrim(T.Tag_value)), '')))) as Company,
         rtrim(ltrim(Max(decode(T.tag_name, 'Location',   ltrim(rtrim(T.Tag_value)), '')))) as Location,
         rtrim(ltrim(Max(decode(T.tag_name, 'TrackingNr', ltrim(rtrim(T.Tag_value)), '')))) as TrackingNr
from     MEDIA M
join     V_MEDIA_AUTOTAGGING T on T.FILE_NAME = M.FILE_NAME
where    ltrim(rtrim(T.Tag_value)) is not null
  and not exists (
  select 1
  from   MEDIA_AUTOTAGGING MAT
  where  MAT.Tag_Name = T.Tag_Name
    and  MAT.type = 'ignore'
    and  REGEXP_LIKE (T.Tag_Value, MAT.re_pattern1, 'i')
 )
group by M.ID,
         M.file_name,
         T.Tag_name,
         T.Tag_value
order by M.ID,
         M.file_name,
         T.Tag_name
;

create or replace view V_MEDIA_TAGS
as
select    Q.ID,
          Q.file_name,
          Substr(LISTAGG(chr(10) || decode(Q.type, 'code', '🔒', 'text', '🏷', 'dict', '👤', '📎') || ' ' || Q.tag_name || ' ➜ <b>' || Q.tag_value || '</b>'),2) as TagList,
          LISTAGG(Q.Type,       '⸱')  as Type,
          LISTAGG(Q.Code,       '⸱')  as Code,
          LISTAGG(Q.Carrier,    '⸱')  as Carrier,
          LISTAGG(Q.Name,       '⸱')  as Name,
          LISTAGG(Q.Person,     '⸱')  as Person,
          LISTAGG(Q.Company,    '⸱')  as Company,
          LISTAGG(Q.Location,   '⸱')  as Location,
          LISTAGG(Q.TrackingNr, '⸱')  as TrackingNr
from      V_DistinctTags Q
group by  Q.ID,
          Q.file_name
;

select * from V_MEDIA_AUTOTAGGING where file_name = '20210312_09:57:30.3710_1.json';
select * from V_MEDIA_AUTOTAGGING where file_name = '20210312_10:04:19.2890_1.json';
select * from V_DistinctTags where file_name = '20210312_10:04:19.2890_1.json';
select * from V_DistinctTags where file_name = '20210312_09:57:30.3710_1.json';
select * from V_DistinctTags where file_name = '20210312_10:04:19.2890_1.json';
select * from V_DistinctTags where file_name = '20210312_10:06:11.7780_1.json';

select * from V_MEDIA_TAGS where file_name in ('20210312_10:04:19.2890_1.json', '20210312_09:57:30.3710_1.json');

select * from V_Media where file_name = '20210312_10:06:11.7780_1.jpg';
select * from Media_DETAILS where file_name = '20210312_10:06:11.7780_1.jpg';

;


select 24 - (round (y * 24)) as line,
       round (x*12) as col,
       Q.*
from   V_MEDIA_RECOGNIZEDTEXT Q
where  file_name = '20210313_11:05:35.6630_1.json'
order by 1,2
;


create or replace view V_MEDIA_FULLTEXT_DATA as
 (select   Q2.*,
           --lead(line) over (partition by file_name order by line, col) lllll,
           case when line = lag (line) over (partition by file_name order by line, col, y, x) then '⸱' else   ''     end  --as prefix,
           ||Q2.TEXT||
           case when line = lead(line) over (partition by file_name order by line, col, y, x) then ''  else  chr(10) end  as textline
  from
   (select   12 - (round (y * 12)) as line,
             round (x*12) as col,
             T.*
    from     V_MEDIA_RECOGNIZEDTEXT T
--    where    file_name = '20210313_11:05:35.6630_1.json'
    order by 1,
             2,
             y,
             x
   ) Q2
 );
select * from V_MEDIA_FULLTEXT_DATA;

create or replace view V_MEDIA_FULLTEXT
as
--with Q as (
--  select   Q2.*,
--         lead(line) over (partition by file_name order by line, col) lllll,
--           case when line = lag (line) over (partition by file_name order by line, col, y, x) then '⸱' else   ''     end  as prefix,
--           case when line = lead(line) over (partition by file_name order by line, col, y, x) then ''  else  chr(10) end  as suffix
--  from
--   (select   100 - (round (y * 100)) as line,
--             round (x*12) as col,
--             T.*
--    from     V_MEDIA_RECOGNIZEDTEXT T
----    where    file_name = '20210313_11:05:35.6630_1.json'
--    order by 1,
--             2,
--             y,
--             x
--   ) Q2
--)
select    Q.ID,
          Q.file_name,
          listagg_clob('textline','V_MEDIA_FULLTEXT_DATA', where_cond=>'ID='''||Q.ID||'''') as Fulltext
        --LISTAGG(Q.prefix || Q.Text || Q.suffix, '')  as Fulltext
from      MEDIA Q
group by  Q.ID,
          Q.file_name
;
/

select *
from   V_MEDIA_FULLTEXT Q
--where  file_name = '20210416_15:10:18.2270_1.json'
;




create or replace view V_MEDIA_CODELIST
as
with Q as (
  select   Q2.*,
           Symbology||' ➜ <b>'||payload||'</b>' as codelist
  from
   (select   distinct
             ID,
             File_Name,
             Symbology,
             payload
    from     V_MEDIA_RECOGNIZEDCODES C
--    where    file_name = '20210313_11:05:35.6630_1.json'
    order by 1,
             2
   ) Q2
)
select    Q.ID,
          Q.file_name,
          LISTAGG(codelist, '<br>') as Codelist
from      Q
group by  Q.ID,
          Q.file_name
;

select *
from   V_MEDIA_CODELIST Q
where  file_name = '20210313_11:05:35.6630_1.json'


CREATE OR REPLACE FUNCTION listagg_clob (
column_name IN VARCHAR2,
table_name  IN VARCHAR2,
where_cond  IN VARCHAR2 DEFAULT NULL,
order_by    IN VARCHAR2 DEFAULT NULL,
delimiter   IN VARCHAR2 DEFAULT '')
RETURN CLOB
IS
ret_clob CLOB;
BEGIN
EXECUTE IMMEDIATE q'!select replace(replace(XmlAgg(
                  XmlElement("a", !' || column_name ||')
                  order by ' ||nvl(order_by,'1') ||
                  q'!)
                  .getClobVal(),
              '<a>', ''),
            '</a>','!'|| delimiter ||q'!') as aggname
   from !' || table_name || q'!
  where  !' || nvl(where_cond,' 1=1') INTO ret_clob;
RETURN ret_clob;
END;
/




/*
** SYNChronizable Datastore
*/
create table SYNCD_TYPE (
  ID            number not null CONSTRAINT SYNCD_TYPE_PK PRIMARY KEY USING INDEX (CREATE UNIQUE INDEX SYNCD_TYPE_UI_ID ON SYNCD_TYPE(ID)),
  Name          varchar2(100) not null
);

create table SYNCD_CID (
  ID            number not null CONSTRAINT SYNCD_CID PRIMARY KEY USING INDEX (CREATE UNIQUE INDEX SYNCD_CID_UI_ID ON SYNCD_CID(ID)),
  Name          varchar2(100) not null,
  TS            timestamp(6) with time zone,
  UNIX_MILLIS   number
);

create table SYNCD_DATA (
  TID1          number default 0 not null constraint SYNCD_FK_TID1 references SYNCD_TYPE,
  TID2          number default 0 not null constraint SYNCD_FK_TID2 references SYNCD_TYPE,
  TID3          number default 0 not null constraint SYNCD_FK_TID3 references SYNCD_TYPE,
  TID4          number default 0 not null constraint SYNCD_FK_TID4 references SYNCD_TYPE,
  TID5          number default 0 not null constraint SYNCD_FK_TID5 references SYNCD_TYPE,
  KEY           varchar2(100) not null,
  DATA          CLOB,
  CID           number default 0 not null constraint SYNCD_FK_CID  references SYNCD_CID,
  SORT          number default 0 not null,
  DELETED       number default 0 not null,
  CONSTRAINT SYNCD_DATA_U1 UNIQUE (TID1, TID2, TID3, TID4, TID5) USING INDEX (CREATE UNIQUE INDEX SYNCD_DATA_UI_TID ON SYNCD_DATA(TID1, TID2, TID3, TID4, TID5) COMPRESS)
)
/

CREATE INDEX SYNCD_DATA_I_KEY ON SYNCD_DATA(KEY);
CREATE INDEX SYNCD_DATA_I_CID ON SYNCD_DATA(CID);




BEGIN
  ORDS.enable_schema(
    p_enabled             => TRUE,
    p_schema              => 'DSCAN',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'dscan',
    p_auto_rest_auth      => FALSE
  );

  COMMIT;
END;
/