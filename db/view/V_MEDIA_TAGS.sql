create or replace view V_MEDIA_TAGS as
select    Q.ID,
          Q.file_name,
          Substr(LISTAGG(chr(10) || decode(Q.tag_name,
            'code', '🔒',
            'person', '👤',
            'location', '📍',
            'company', '🏬',
            'carrier', '🚛',
            'trackingnr', '#️⃣',
            'uri', '🔗',
            'person', '👤',
            '🏷')
            || /* ' ' || Q.tag_name || ' ➜'||*/ ' <b>' || Q.tag_value || '</b>'),2) as TagList,
          LISTAGG(Q.Type,       '⸱')  as Type,
          LISTAGG(Q.Code,       '⸱')  as Code,
          LISTAGG(Q.Carrier,    '⸱')  as Carrier,
          LISTAGG(Q.Name,       '⸱')  as Name,
          LISTAGG(Q.Person,     '⸱')  as Person,
          LISTAGG(Q.Company,    '⸱')  as Company,
          LISTAGG(Q.Location,   '⸱')  as Location,
          LISTAGG(Q.TrackingNr, '⸱')  as TrackingNr
from      V_Media_DistinctTags Q
group by  Q.ID,
          Q.file_name
;
/

select * from v_media_tags where id = '1442';

