drop table media_details;

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
