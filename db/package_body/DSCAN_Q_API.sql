CREATE OR REPLACE PACKAGE BODY DSCAN_Q_API AS

  g_msg                 DSCAN_Q_TYPE;

  g_process_job_loop    NUMBER       := 100;

  g_enqueue_options     DBMS_AQ.enqueue_options_t;
  g_dequeue_options     DBMS_AQ.dequeue_options_t;
  g_message_properties  DBMS_AQ.message_properties_t;
  g_message_handle      RAW(16);

  ex_timeout      EXCEPTION;
  PRAGMA EXCEPTION_INIT(ex_timeout, -25228);

  /*
  ** **************************************************************************
  ** Create and start queue.
  **
  ** begin DSCAN_TASK_API.init_queue; end;
  **
  */
  PROCEDURE init_queue
  is
    procedure x (stmt varchar2)
    is
    begin
      DBMS_OUTPUT.PUT_LINE(stmt);
      execute immediate stmt;
    end;
  BEGIN
    x('begin DBMS_AQADM.create_queue_table (
      queue_table        => DSCAN_TASK_API.c_Queue_Name,
      queue_payload_type => ''DSCAN_TASK_TYPE'');
      end;'
      );

    x('begin DBMS_AQADM.create_queue (
        queue_name         => DSCAN_TASK_API.c_Queue_Name,
        queue_table        => c_Queue_Name || ''_QTAB''
      );
      end;'
    );

    x('begin DBMS_AQADM.start_queue (
        queue_name         => DSCAN_TASK_API.c_Queue_Name,
        enqueue            => TRUE
      );
      end;'
    );
  END;

  /*
  ** **************************************************************************
  */
  function msg (
    p_id             in VARCHAR2,
    p_cid            in INT,
    p_details        in VARCHAR2 default null
  )
  return DSCAN_Q_TYPE is
  begin
    return DSCAN_Q_TYPE (
      p_id,
      p_cid,
      p_details
    );
  end;


  /*
  ** **************************************************************************
  **
  ** begin DSCAN_TASK_API.enqueue_export_image(123); end;
  */
  PROCEDURE enqueue_sync_media (
    p_id             in  Varchar2,
    p_cid            in  Number
  ) is
  begin
    g_msg := DSCAN_Q_API.msg(p_id, p_cid);

    -- remove all older messages from queue
    g_dequeue_options.dequeue_mode := DBMS_AQ.REMOVE_NODATA;
    g_dequeue_options.wait := 0;

    begin
      loop
        -- loop until the queue is emptied
        DBMS_AQ.dequeue (
          queue_name          => c_Queue_Name,
          dequeue_options     => g_dequeue_options,
          message_properties  => g_message_properties,
          payload             => g_msg,
          msgid               => g_message_handle
        );
      end loop;

    exception when ex_timeout then
      null;
    end;

    -- post our new message
    DBMS_AQ.enqueue (
      queue_name          => c_QUEUE_NAME,
      enqueue_options     => g_enqueue_options,
      message_properties  => g_message_properties,
      payload             => g_msg,
      msgid               => g_message_handle
    );
  end;


  /*
  ** **************************************************************************
  ** for dequeuing in a view
  */
--  FUNCTION dequeue (
--    p_wait_seconds   in number default null
--  ) return number is
--    PRAGMA AUTONOMOUS_TRANSACTION;
--
--      ex_timeout      EXCEPTION;
--      PRAGMA EXCEPTION_INIT(ex_timeout, -25228);
--
--  begin
--    if p_wait_seconds is null then return null; end if;
--
--    g_dequeue_options.wait         := p_wait_seconds;
----    g_dequeue_options.browse_mode  := DBMS_AQ.BROWSE;
--
--    DBMS_AQ.dequeue (
--      queue_name          => c_Queue_Name,
--      dequeue_options     => g_dequeue_options,
--      message_properties  => g_message_properties,
--      payload             => g_msg,
--      msgid               => g_message_handle
--    );
--
--    return g_msg;
--
--  exception when ex_timeout then
--    return 0;
--  END;



  /*
  ** **************************************************************************
  */
  procedure dequeue (
    p_wait_seconds   in number default null
  ) is

  begin
    g_dequeue_options.wait := p_wait_seconds;

    DBMS_AQ.dequeue (
      queue_name          => c_Queue_Name,
      dequeue_options     => g_dequeue_options,
      message_properties  => g_message_properties,
      payload             => g_msg,
      msgid               => g_message_handle
    );
  END;



  /*
  ** **************************************************************************
  */
  procedure DSCAN_SYNC_QUERY (
    p_result_cursor   out sys_refcursor,
    p_hours           in number default 24,
    p_wait_seconds    in number default 15,
    p_last_cid        in number default 0
  ) is

      n               number;
      wait_seconds    number := p_wait_seconds;
      num_rows        number;
      max_cid         number;
      cid             number;

  BEGIN
    /*
    ** bewirkt, dass Datenbankänderungen zwischen Zählen neuer Records
    ** und Erstellen des REF_CURSOR nicht gesehen werden
    */
    --ROLLBACK;
    --SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    --trc.msg('query '||p_hours||' hours, last_cid='||p_last_cid||' p_wait_seconds:'||p_wait_seconds);

    if p_last_cid > 0 and p_wait_seconds > 0 then
      -- look for newer rows
      select count(*),
             max(cid)
      into   num_rows,
             max_cid
      from   V_MEDIA_DETAILS
      where  timestamp  > systimestamp - numtodsinterval(p_hours, 'hour')
        and  cid        > p_last_cid
      ;

      --trc.msg('num_rows:'||num_rows||' cid='||max_cid);

      if num_rows = 0 then
        -- no newer rows yet, wait on queue
        trc.msg('waiting...');
        loop
          begin
            dequeue(wait_seconds);

          exception when ex_timeout then
            -- timed out
            trc.msg('timeout');
            exit;
          end;

          cid := g_msg.cid;
          if cid > p_last_cid then
            -- got a change notification
            exit;
          else
            -- dequeue another cid
            null;
          end if;
        end loop;
      end if;
    end if;

    OPEN p_result_cursor FOR
      SELECT   *
      FROM     V_MEDIA_DETAILS
 		  WHERE    timestamp  > systimestamp - numtodsinterval(p_hours, 'hour')
 		    and    cid > nvl(p_last_cid, -1)
      ORDER BY CID
    ;

  END;





  /*
  ** **************************************************************************
  **
  ** begin DSCAN_TASK_API.process_tasks_job; end;
  */
  --  function process_tasks
  --   (p_wait_seconds number)
  --  return number is
  --
  --    ex_timeout      EXCEPTION;
  --    PRAGMA EXCEPTION_INIT(ex_timeout, -25228);
  --
  --    msgcount        number := 0;
  --
  --  begin
  --
  --    loop
  --
  --      begin
  --        --trc.msg('wait '||p_wait_seconds);
  --        dequeue(p_wait_seconds);
  --
  --        msgcount := msgcount + 1;
  --
  --        case g_msg.task
  --          when c_EXP_IMG then
  --            trc.msg('EXP Bild #'||g_msg.info1);
  --            INTRACK_BILDER.EXPORT(g_msg.info1);
  --
  --          when c_EXP_TAB then
  --            trc.msg('EXP table '||g_msg.info1||' devices '||g_msg.info2);
  --            DSCAN.EXPORT(g_msg.info1, g_msg.info2);
  --
  --        end case;
  --
  --        commit;
  --
  --      exception
  --        when ex_timeout then
  --          exit;
  --      end;
  --
  --    end loop;
  --
  --    return msgcount;
  --    --trc.msg('done');
  --  END;
  -- -----------------------------------------------------------------

END;
/
