CREATE OR REPLACE FUNCTION listagg_clob (
column_name IN VARCHAR2,
table_name  IN VARCHAR2,
where_cond  IN VARCHAR2 DEFAULT NULL,
order_by    IN VARCHAR2 DEFAULT NULL,
delimiter   IN VARCHAR2 DEFAULT ',')
RETURN CLOB
IS
ret_clob CLOB;
BEGIN
EXECUTE IMMEDIATE q'!select replace(replace(XmlAgg(
                  XmlElement("a", !' || column_name ||')
                  order by ' ||nvl(order_by,'1') ||
                  q'!)
                  .getClobVal(),
              '<a>', ''),
            '</a>','!'|| delimiter ||q'!') as aggname
   from !' || table_name || q'!
  where  !' || nvl(where_cond,' 1=1') INTO ret_clob;
RETURN ret_clob;
END;
/
