create or replace view V_MEDIA_FULLTEXT_DATA as
(select   Q2."LINE",Q2."COL",Q2."ID",Q2."FILE_NAME",Q2."IDX",Q2."CONTENT_TYPE",Q2."TIMESTAMP",Q2."TEXT",Q2."CONFIDENCE",Q2."X",Q2."Y",Q2."W",Q2."H",
           --lead(line) over (partition by file_name order by line, col) lllll,
           case when line = lag (line) over (partition by file_name order by line, col, y, x) then '⸱' else   ''     end  --as prefix,
           ||Q2.TEXT||
           case when line = lead(line) over (partition by file_name order by line, col, y, x) then ''  else  chr(10) end  as textline
  from
   (select   12 - (round (y * 12)) as line,
             round (x*12) as col,
             T.*
    from     V_MEDIA_RECOGNIZED_TEXT T
--    where    file_name = '20210313_11:05:35.6630_1.json'
    order by 1,
             2,
             y,
             x
   ) Q2
 )
/

