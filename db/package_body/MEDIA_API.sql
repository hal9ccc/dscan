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
        v_timestamp := nvl(to_timestamp(p_timestamp, 'yyyy-mm-dd"T"hh24:mi:ss"Z"'), SYSTIMESTAMP);
    exception
      when others then
        trc.err('Failed to convert timestamp: '||p_timestamp);
        v_timestamp := SYSTIMESTAMP;
    end;

    v_file_name := p_file_name; --to_char(v_timestamp, 'YYYYMMDD-HH24:MI:SS,FF4')||'_'||ltrim(to_char(p_idx, '0000'))||'.jpg';
    v_title     := nvl(p_title, to_char(v_timestamp, 'YYYYMMDD-HH24:MI:SS')||'-'||ltrim(to_char(p_idx, '0000')));

    begin
      select ID
      into   v_id
      from   MEDIA
      where  FILE_NAME = v_file_name
      ;

      UPDATE media
        SET  id         = v_id,
             content    = p_content,
             title      = v_title,
             device     = p_device,
             timestamp  = v_timestamp
      WHERE  file_name  = v_file_name
      ;
      trc.MSG('updated MEDIA record #'||v_id);

    exception when no_data_found then
      v_id := media_seq.NEXTVAL;
      INSERT INTO media (id, content, content_type, file_name, "TYPE", title, timestamp, idx, device)
      VALUES (v_id, p_content, p_content_type, v_file_name, p_type, v_title, v_timestamp, p_idx, p_device);
      trc.MSG('inserted MEDIA record #'||v_id);
    end;

    COMMIT;

    if p_content_type = 'text/json' then
      begin
        DBMS_SCHEDULER.CREATE_JOB (
          job_name   => 'update_media_details_'||v_id,
          job_type   => 'PLSQL_BLOCK',
          job_action => 'BEGIN  update_media_details('||v_id||'); END;',
          start_date => SYSTIMESTAMP, -- - NUMTODSINTERVAL(1, 'day'),
          enabled    => true
        );
        trc.EXIT('created job update_media_details_'||v_id);

      exception when others then
        trc.err('error creating job');
      end;
    end if;

    trc.EXIT('upload complete ('||DBMS_LOB.GETLENGTH(p_content)||' byte)');

  EXCEPTION
    when others then
      trc.err('error saving media content');
      raise;
  END;


  PROCEDURE download (p_file_name  IN  media.file_name%TYPE) IS
    l_rec  media%ROWTYPE;
  BEGIN
    --trc.ENTER('download', 'p_file_name', p_file_name);
    SELECT *
    INTO   l_rec
    FROM   media
    WHERE  file_name = p_file_name;

    OWA_UTIL.mime_header(l_rec.content_type, FALSE);
    HTP.p('Content-Length: ' || DBMS_LOB.getlength(l_rec.content));
    HTP.p('Content-Disposition: filename="' || l_rec.file_name || '"');
    OWA_UTIL.http_header_close;

    WPG_DOCLOAD.download_file(l_rec.content);
    --trc.EXIT('download');
  END;

END;
/

