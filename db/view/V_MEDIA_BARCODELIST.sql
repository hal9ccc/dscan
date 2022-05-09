create or replace view V_MEDIA_BARCODELIST as
with Q as (
  select   Q2.*,
           Symbology||' ➜ <b>'||payload||'</b>' as codelist
  from
   (select   distinct
             ID,
             File_Name,
             Symbology,
             payload
    from     V_MEDIA_DETECTED_BARCODES C
--    where    file_name = '20210313_11:05:35.6630_1.json'
    order by 1,
             2
   ) Q2
)
select    Q.ID,
          Q.file_name,
          LISTAGG(codelist, '<br>') as Codelist
from      Q
group by  Q.ID,
          Q.file_name
/

