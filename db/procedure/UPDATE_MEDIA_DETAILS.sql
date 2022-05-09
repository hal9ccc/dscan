create or replace procedure update_media_details
 (numID     Number default null,
  tsStart   Timestamp with time zone default null
 ) is

  /*
  ** "materializes" contents from v_media in media_details, to enable fast queries
  **
  ** sorry, two sets of nearly identical statements for performance reasons. Otherwise single update wouldn't be fast
  */

  M MEDIA%ROWTYPE;

begin
  trc.ENTER('update_media_details', 'numID', numID, 'tsStart', tsStart);

  if numID is not null then
    select *
    into   M
    from   MEDIA
    where  ID = numID
    ;

    --if M.content_type = 'text/json'
  end if;

  if numID is not null then
    /*
    ** Update a single record
    */

    MERGE INTO media_details T USING
      (select   *
       from     v_media
       where    ID         = numID
      ) Q
      ON (T.ID = Q.ID)
      WHEN MATCHED THEN UPDATE
      SET CONTENT_TYPE  = Q.CONTENT_TYPE,
          TYPE          = Q.TYPE,
          TITLE         = Q.TITLE,
          TIMESTAMP     = Q.TIMESTAMP,
          IDX           = Q.IDX,
          CID           = Q.CID,
          HIDDEN        = Q.HIDDEN,
          STATUS        = Q.STATUS,
          CONTENT_SIZE  = Q.CONTENT_SIZE,
          CODE          = Q.CODE,
          CARRIER       = Q.CARRIER,
          TRACKINGNR    = Q.TRACKINGNR,
          NAME          = Q.NAME,
          PERSON        = Q.PERSON,
          COMPANY       = Q.COMPANY,
          LOCATION      = Q.LOCATION,
          DEVICE        = Q.DEVICE,
          INFO1         = Q.INFO1,
          INFO2         = Q.INFO2,
          INFO3         = Q.INFO3,
          INFO4         = Q.INFO4,
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
          Q.CID,
          Q.HIDDEN,
          Q.STATUS,
          Q.CONTENT_SIZE,
          Q.DEVICE,
          Q.INFO1,
          Q.INFO2,
          Q.INFO3,
          Q.INFO4,
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
      );

  else
    /*
    ** Update multiple records
    */

    MERGE INTO media_details T USING
      (select   *
       from     v_media
       --where    ID         = numID
      ) Q
      ON (T.ID = Q.ID)
      WHEN MATCHED THEN UPDATE
      SET CONTENT_TYPE  = Q.CONTENT_TYPE,
          TYPE          = Q.TYPE,
          TITLE         = Q.TITLE,
          TIMESTAMP     = Q.TIMESTAMP,
          IDX           = Q.IDX,
          CID           = Q.CID,
          HIDDEN        = Q.HIDDEN,
          STATUS        = Q.STATUS,
          CONTENT_SIZE  = Q.CONTENT_SIZE,
          CODE          = Q.CODE,
          CARRIER       = Q.CARRIER,
          TRACKINGNR    = Q.TRACKINGNR,
          NAME          = Q.NAME,
          PERSON        = Q.PERSON,
          COMPANY       = Q.COMPANY,
          LOCATION      = Q.LOCATION,
          DEVICE        = Q.DEVICE,
          INFO1         = Q.INFO1,
          INFO2         = Q.INFO2,
          INFO3         = Q.INFO3,
          INFO4         = Q.INFO4,
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
          Q.CID,
          Q.HIDDEN,
          Q.STATUS,
          Q.CONTENT_SIZE,
          Q.DEVICE,
          Q.INFO1,
          Q.INFO2,
          Q.INFO3,
          Q.INFO4,
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
      );
  end if;

  trc.EXIT('update_media_details, rowcount='||SQL%ROWCOUNT);

exception when others then
  trc.ERR('Failed updating media_details: '||SQLERRM);
end;

begin
  update_media_details;
end;

begin
  update_media_details(1442);
end;


select   * from     v_media        where   ID = 1442
select   * from     MEDIA_DETAILS  where   ID = 1442