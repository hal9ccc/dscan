create or replace view V_MEDIA_DETAILS
as
 (Select T.*,
         TO_CHAR(T.TIMESTAMP, 'YYYYMMDDHH24MISSFF3') as TIMESTAMP_STR,
         REGEXP_REPLACE(T.FILE_NAME, '.json$', '.jpg') as FILE_NAME_IMG
  From   MEDIA_DETAILS T
  --where  id = 581
 );

select * from V_MEDIA_DETAILS where carrier = 'asdfs';

update media set file_name = replace(FILE_NAME, ' ', '_');

delete MEDIA_DETAILS;


create type DSCAN_QUERY_PARAMETERS force as object
 (numWaitSec        number,
  numPeriod         number,
  tsFrom            timestamp with time zone,
  tsTo              timestamp with time zone
 )
/

-- auto-generated definition
create type DSCAN_QUERY_PARAMETERS_TABLE as table of DSCAN_QUERY_PARAMETERS
/
