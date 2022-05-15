
CREATE OR REPLACE PACKAGE DSCAN_Q_API AS

  c_Queue_Name           constant varchar2(100) := 'DSCAN_QUEUE';
  c_SYNC_MEDIA           constant varchar2(100) := 'sync';

  PROCEDURE init_queue;

  function msg (
    p_id             in VARCHAR2,
    p_cid            in INT,
    p_details        in VARCHAR2 default null
  )
  return DSCAN_Q_TYPE;

  PROCEDURE enqueue_sync_media (
    p_id             in  Varchar2,
    p_cid            in  Number
  );

  --FUNCTION dequeue (
  --p_wait_seconds   in number default null
  --)
  --return number;

  PROCEDURE dequeue (
    p_wait_seconds   in number default null
  );


  procedure DSCAN_SYNC_QUERY (
    p_result_cursor   out sys_refcursor,
    p_hours           in number default 24,
    p_wait_seconds    in number default 15,
    p_last_cid        in number default 0
  );

  --function process_tasks
  -- (p_wait_seconds number
  -- )
  --return number;
END;
/
