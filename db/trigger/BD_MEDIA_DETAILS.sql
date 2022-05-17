create or replace trigger BD_MEDIA_DETAILS
	before delete
	on MEDIA_DETAILS
	for each row
DECLARE
begin
  --update media set hidden = 1 where id = :old.id;
  delete media where id = :old.id;
end;
/