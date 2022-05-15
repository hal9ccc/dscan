-- taken from https://oracle-base.com/articles/misc/decoupling-to-improve-performance

GRANT AQ_ADMINISTRATOR_ROLE, AQ_USER_ROLE TO DSCAN;
GRANT EXECUTE ON DBMS_AQ TO DSCAN;

begin
  DBMS_AQADM.create_queue_table (
    queue_table        => 'DSCAN_QTAB',
    queue_payload_type => 'DSCAN_Q_TYPE');
end;

begin
  DBMS_AQADM.create_queue (
    queue_name         => 'DSCAN_QUEUE',
    queue_table        => 'DSCAN_QTAB',
    retention_time     => 300 -- keep removed messages for 300 seconds
  );
end;

begin
  DBMS_AQADM.start_queue (
    queue_name         => 'DSCAN_QUEUE',
    enqueue            => TRUE
  );
end;

select * from ALL_DIRECTORIES;

rollback;

with dq as (select DSCAN_TASK_API.dequeue(2) n from dual)
select  DQ.n
        ID,
        FILE_NAME,
        SET_NAME,
        IDX,
        CID,
        HIDDEN,
        STATUS,
        TYPE,
        CODE,
        CARRIER,
--        CODELIST,
        COMPANY,
        CONTENT_SIZE,
        CONTENT_TYPE,
        DAY,
        DEVICE,
        FILE_NAME_IMG,
        FULLTEXT,
--        HTML_DETAILS,
        IMG,
        LOCATION,
        MONTH,
        NAME,
        PERSON,
--        TAGLIST,
        TIMESTAMP_STR as TIMESTAMP,
        TITLE,
        TRACKINGNR
from    DQ, V_MEDIA_DETAILS
where   timestamp > systimestamp - numtodsinterval(nvl(148, 8760), 'hour')
order by 1
;


truncate table trace;


select   to_char(TS) as TS, nr, src, TYPE, msg from trace
  where  ts > SYSTIMESTAMP - interval '150' minute
    and  src not like '%DASHB%'
    and  src not like '%SENSOR%'
    and  src not like '%INTRACK_FI%'
    and  msg not like 'V_DASHB_QUERY%'
order by ts desc, nr desc;