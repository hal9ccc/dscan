create or replace view V_MEDIA_DISTINCTTAGS as
select   DISTINCT
         M.ID,
         M.file_name,
         T.Tag_name,
         ltrim(rtrim(T.Tag_value)) as Tag_Value,
         rtrim(ltrim(Max(decode(T.tag_name, 'Type',       ltrim(rtrim(T.Tag_value)), '')))) as Type,
         rtrim(ltrim(Max(decode(T.tag_name, 'Code',       ltrim(rtrim(T.Tag_value)), '')))) as Code,
         rtrim(ltrim(Max(decode(T.tag_name, 'Name',       ltrim(rtrim(T.Tag_value)), '')))) as Name,
         rtrim(ltrim(Max(decode(T.tag_name, 'Person',     ltrim(rtrim(T.Tag_value)), '')))) as Person,
         rtrim(ltrim(Max(decode(T.tag_name, 'Carrier',    ltrim(rtrim(T.Tag_value)), '')))) as Carrier,
         rtrim(ltrim(Max(decode(T.tag_name, 'Company',    ltrim(rtrim(T.Tag_value)), '')))) as Company,
         rtrim(ltrim(Max(decode(T.tag_name, 'Location',   ltrim(rtrim(T.Tag_value)), '')))) as Location,
         rtrim(ltrim(Max(decode(T.tag_name, 'TrackingNr', ltrim(rtrim(T.Tag_value)), '')))) as TrackingNr
from     MEDIA M
join     V_MEDIA_AUTOTAGGING T on T.FILE_NAME = M.FILE_NAME
where    ltrim(rtrim(T.Tag_value)) is not null
  and not exists (
  select 1
  from   MEDIA_AUTOTAGGING MAT
  where  MAT.Tag_Name = T.Tag_Name
    and  MAT.type = 'ignore'
    and  REGEXP_LIKE (T.Tag_Value, MAT.re_pattern1, 'i')
 )
group by M.ID,
         M.file_name,
         T.Tag_name,
         T.Tag_value
order by M.ID,
         M.file_name,
         T.Tag_name
;
/
