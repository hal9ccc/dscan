create or replace view V_MEDIA_FULLTEXT as
select    Q.ID,
          Q.file_name,
          listagg_clob('textline','V_MEDIA_FULLTEXT_DATA', where_cond=>'ID='''||Q.ID||'''') as Fulltext
        --LISTAGG(Q.prefix || Q.Text || Q.suffix, '')  as Fulltext
from      MEDIA Q
group by  Q.ID,
          Q.file_name
/
select * from V_MEDIA_FULLTEXT where id = 2132;
