create or replace trigger BIU_MEDIA_DETAILS
	before insert or update
	on MEDIA_DETAILS
	for each row
DECLARE
begin
  :new.CID := SEQ_MEDIA_CHANGE.nextval;
  DSCAN_Q_API.enqueue_sync_media(:new.ID, :new.CID);
end;
/