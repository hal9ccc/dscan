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
          CID,
          HIDDEN,
          STATUS,
          CONTENT_SIZE,
          DEVICE,
          INFO1,
          INFO2,
          INFO3,
          INFO4,
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
