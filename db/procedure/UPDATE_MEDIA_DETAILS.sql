create or replace procedure update_media_details
 (strID Varchar2 default null,
  tsStart Timestamp with time zone default null
 ) is

  M MEDIA%ROWTYPE;

begin
  trc.ENTER('update_media_details', 'strID', strID, 'tsStart', tsStart);

  if strID is not null then
    select *
    into   M
    from   MEDIA
    where  ID = strID
    ;

    --if M.content_type = 'text/json'
  end if;


  MERGE INTO media_details T USING
    (select   *
     from     v_media
     where   (ID         = strID   or strID   is null)
--      and    (Timestamp >= tsStart or tsStart is null)
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
    );

  trc.EXIT('update_media_details, rowcount='||SQL%ROWCOUNT);

exception when others then
  trc.ERR('Failed updating media_details: '||SQLERRM);
end;

begin
  update_media_details;
end;

begin
  update_media_details('1366');
end;

