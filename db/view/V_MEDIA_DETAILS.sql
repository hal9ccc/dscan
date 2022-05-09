create or replace view V_MEDIA_DETAILS
as
 (Select T.*,
         TO_CHAR(T.TIMESTAMP, 'YYYYMMDDHH24MISSFF3') as TIMESTAMP_STR,
         REGEXP_REPLACE(T.FILE_NAME, '.json$', '.jpg') as FILE_NAME_IMG
  From   MEDIA_DETAILS T
 );

select * from V_MEDIA_DETAILS;

update media set file_name = replace(FILE_NAME, ' ', '_');

