select t.*, t.rowid from media t order by timestamp desc, content_type;

select * from TRACE where ts > systimestamp - numtodsinterval(1, 'minute') order by ts, nr;

truncate table trace;

update media set status = 'scanned', cid = 0;

commit;

drop package body DSCAN_TASK_API;

select * from media order by file_name desc;
select * from media_details order by timestamp desc;


begin DBMS_UTILITY.compile_schema(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')); end;
/


select *
from sys.all_errors
where owner = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
order by 1,2,3
;

update media set hidden = 0 where id <= 1663;
select count(*) from media where nvl(hidden,0) = 0;
select count(*) from media_details where nvl(hidden,0) = 0;
commit;

delete media_details;

begin
  update_media_details;
  commit;
end;


/*
** from https://oracle-base.com/articles/misc/oracle-rest-data-services-ords-restful-web-services-handling-media
*/

drop table media;


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





select * from media order by id desc;


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

select * from media_details;
select count(*) from media_details;
delete from media_details where rownum < 38;
select * from V_MEDIA where id = 1341;
select * from V_MEDIA_CODELIST where file_name = '2022-05-08 20:59:58.2790_1.json';
select * from V_MEDIA where file_name = '2022-05-08 20:59:58.2790_1.json';
select * from V_MEDIA where file_name = '2022-05-08 20:59:58.2790_1.json';
select * from V_MEDIA where id = 1366;
select * from MEDIA_DETAILS where file_name = '2022-05-08 20:59:58.2790_1.jpg';



delete media where timestamp > sysdate -1;

select * from v_media order by id desc;
select * from v_media where ID = '1366 ' order by id desc;
select * from media_details order by id desc;

select * from media order by timestamp desc;
select * from media_details order by TIMESTAMP desc;
select REGEXP_REPLACE('sfkj dsfh.jpeg', '.jpg$|.jpeg$', '.json') from dual;












































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






select to_number('-0.00017175078392809', 'fm9999999D9999999999999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''') from dual;

to_number(Q.confidence, 'fm9999999D9999999999999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''')


select text, count(*) anz
from   V_MEDIA_RECOGNIZEDTEXT
group by text
order by 2 desc;



select * from V_MEDIA_RECOGNIZEDTEXT order by id, h desc, confidence desc;
select * from V_MEDIA_DETECTEDBARCODES order by file_name;

select * from V_MEDIA_RECOGNIZEDTEXT where rtrim(translate (confidence, '-0123456789.', '            ')) is not null;
select * from V_MEDIA_RECOGNIZEDTEXT where file_name = '2022-05-08 18:36:14.7460_1.json';

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
 join   V_MEDIA_DETECTEDBARCODES MRC
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
    from     V_MEDIA_DETECTEDBARCODES C
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




select * from media;

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