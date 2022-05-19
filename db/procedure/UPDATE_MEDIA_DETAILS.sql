create or replace procedure update_media_details
 (numID     Number default null,
  tsStart   Timestamp with time zone default SYSTIMESTAMP - NUMTODSINTERVAL(1, 'DAY')
 ) is

  /*
  ** "materializes" contents from v_media in media_details, to enable fast queries
  */

  n number := 0;

  procedure m (
    MediaId in number
  ) is
  begin
    trc.msg('saving tags on '||MediaId||'...');
    n := n + 1;
    MERGE INTO media_details T USING
      (select   *
       from     v_media
       where    ID         = MediaId
      ) Q
      ON (T.ID = Q.ID)
      WHEN MATCHED THEN UPDATE
      SET TYPE          = nvl(TYPE,           Q.TYPE),
          TITLE         = nvl(TITLE,          Q.TITLE),
          CODE          = nvl(CODE,           Q.CODE),
          CARRIER       = nvl(CARRIER,        Q.CARRIER),
          TRACKINGNR    = nvl(TRACKINGNR,     Q.TRACKINGNR),
          NAME          = nvl(NAME,           Q.NAME),
          PERSON        = nvl(PERSON,         Q.PERSON),
          COMPANY       = nvl(COMPANY,        Q.COMPANY),
          LOCATION      = nvl(LOCATION,       Q.LOCATION),
          DEVICE        = nvl(DEVICE,         Q.DEVICE),
          INFO1         = nvl(INFO1,          Q.INFO1),
          INFO2         = nvl(INFO2,          Q.INFO2),
          INFO3         = nvl(INFO3,          Q.INFO3),
          INFO4         = nvl(INFO4,          Q.INFO4),
          FULLTEXT      = nvl(FULLTEXT,       Q.FULLTEXT),
          CODELIST      = nvl(CODELIST,       Q.CODELIST),
          TAGLIST       = nvl(TAGLIST,        Q.TAGLIST),
          HTML_DETAILS  = nvl(HTML_DETAILS,   Q.HTML_DETAILS),
          MONTH         = nvl(MONTH,          Q.MONTH),
          DAY           = nvl(DAY,            Q.DAY),
          SET_NAME      = nvl(SET_NAME,       Q.SET_NAME),
          IMG           = nvl(IMG,            Q.IMG)
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
  end;




begin
  trc.ENTER('update_media_details', 'numID', numID, 'tsStart', tsStart);

  if numID is not null then
    m (numID);

  else
    for c in (
      Select   *
      from     MEDIA
      where    timestamp > tsStart
      order by timestamp
    )
    loop
      m (c.ID);
    end loop;
  end if;

  trc.EXIT('update_media_details, count='||n);

exception when others then
  trc.ERR('Failed updating media_details: '||SQLERRM);
end;

begin
  update_media_details;
  commit;
end;

select * from TRACE where ts > systimestamp - numtodsinterval(70, 'minute') order by ts, nr;

begin
  update_media_details(1442);
  commit;
end;

begin
  update_media_details(tsStart => SYSTIMESTAMP - NUMTODSINTERVAL(500, 'DAY'));
  commit;
end;




delete MEDIA_DETAILS;

select   * from     v_media        where   ID = 1442
select   * from     V_MEDIA_DETAILS order by id desc--  where   cid is null
;