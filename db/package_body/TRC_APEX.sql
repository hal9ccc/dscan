CREATE OR REPLACE PACKAGE BODY TRC_APEX AS
  /*
  ** **************************************************************************
  */
  procedure enable
  is
    i number;
  begin
    if booEnabled then
      return;
    end if;

    --APEX_DEBUG.ENABLE(9);

    booEnabled := true;
    return;
  end;

  /*
  ** **************************************************************************
  */
  function prefix
  return varchar2 is
  begin
    return l_owner||rtrim('.'||l_name, '.') || rtrim(':'||l_lineno, ':');
  end;

  /*
  ** **************************************************************************
  */
  procedure write_message
   (src  in varchar2,
    type in varchar2,
    msg  in varchar2
   ) is
  PRAGMA AUTONOMOUS_TRANSACTION;
    ts timestamp := SYSTIMESTAMP;
    n number;
  begin
    begin
      dbms_output.put_line(substrb(ltrim(ts||' '||prefix||' ')||type||' '||msg,1,4000));
    exception when others then null;
    end;

    select to_number(SYS_CONTEXT('USERENV','SID'))
    into   n
    from   dual
    ;

    insert into trace
      (ts, nr, src, type, msg)
    values
      (ts, n+(nr/10000), src, type, substrb(msg,1,4000))
    ;

    commit;

    l_caller_stored := false;
    l_lineno        := '';
    l_owner         := '';
    l_name          := '';

    nr := nr + 1;
  end;

  /*
  ** **************************************************************************
  */
  procedure enter
   (str varchar2,
    p_name01  IN VARCHAR2 DEFAULT NULL,
    p_value01 IN VARCHAR2 DEFAULT NULL,
    p_name02  IN VARCHAR2 DEFAULT NULL,
    p_value02 IN VARCHAR2 DEFAULT NULL,
    p_name03  IN VARCHAR2 DEFAULT NULL,
    p_value03 IN VARCHAR2 DEFAULT NULL,
    p_name04  IN VARCHAR2 DEFAULT NULL,
    p_value04 IN VARCHAR2 DEFAULT NULL,
    p_name05  IN VARCHAR2 DEFAULT NULL,
    p_value05 IN VARCHAR2 DEFAULT NULL,
    p_name06  IN VARCHAR2 DEFAULT NULL,
    p_value06 IN VARCHAR2 DEFAULT NULL,
    p_name07  IN VARCHAR2 DEFAULT NULL,
    p_value07 IN VARCHAR2 DEFAULT NULL,
    p_name08  IN VARCHAR2 DEFAULT NULL,
    p_value08 IN VARCHAR2 DEFAULT NULL,
    p_name09  IN VARCHAR2 DEFAULT NULL,
    p_value09 IN VARCHAR2 DEFAULT NULL,
    p_name10  IN VARCHAR2 DEFAULT NULL,
    p_value10 IN VARCHAR2 DEFAULT NULL
   )
  is
  begin
    if not l_caller_stored then OWA_UTIL.WHO_CALLED_ME (l_owner, l_name,l_lineno,l_caller); end if;
    --apex_debug.enter
    -- (prefix||' { '||str,
    --  p_name01  => p_name01,
    --  p_value01 => p_value01,
    --  p_name02  => p_name02,
    --  p_value02 => p_value02,
    --  p_name03  => p_name03,
    --  p_value03 => p_value03,
    --  p_name04  => p_name04,
    --  p_value04 => p_value04,
    --  p_name05  => p_name05,
    --  p_value05 => p_value05,
    --  p_name06  => p_name06,
    --  p_value06 => p_value06,
    --  p_name07  => p_name07,
    --  p_value07 => p_value07,
    --  p_name08  => p_name08,
    --  p_value08 => p_value08,
    --  p_name09  => p_name09,
    --  p_value09 => p_value09,
    --  p_name10  => p_name10,
    --  p_value10 => p_value10
    -- );

    write_message (prefix, '{', str||' '||ltrim(
         case when p_name01 is not null then ' '||p_name01 || '=>"' || p_value01 || '"' else '' end
      || case when p_name02 is not null then ' '||p_name02 || '=>"' || p_value02 || '"' else '' end
      || case when p_name03 is not null then ' '||p_name03 || '=>"' || p_value03 || '"' else '' end
      || case when p_name04 is not null then ' '||p_name04 || '=>"' || p_value04 || '"' else '' end
      || case when p_name05 is not null then ' '||p_name05 || '=>"' || p_value05 || '"' else '' end
      || case when p_name06 is not null then ' '||p_name06 || '=>"' || p_value06 || '"' else '' end
      || case when p_name07 is not null then ' '||p_name07 || '=>"' || p_value07 || '"' else '' end
      || case when p_name08 is not null then ' '||p_name08 || '=>"' || p_value08 || '"' else '' end
      || case when p_name09 is not null then ' '||p_name09 || '=>"' || p_value09 || '"' else '' end
      || case when p_name10 is not null then ' '||p_name10 || '=>"' || p_value10 || '"' else '' end
    ));

  end;

  /*
  ** **************************************************************************
  */
  procedure msg
    (str varchar2
    )
  is
  begin
    if not l_caller_stored then OWA_UTIL.WHO_CALLED_ME (l_owner, l_name,l_lineno,l_caller); end if;
    --apex_debug.message(prefix||' - '||str, p_level => apex_debug.c_log_level_app_trace);
    write_message (prefix, '-', str);
  end;

  function msg
   (str varchar2
   ) return varchar2
  is
  begin
    msg(str);
    return str;
  end;


  /*
  ** **************************************************************************
  */
  procedure exit
    (str varchar2
    )
  is
  begin
    if not l_caller_stored then OWA_UTIL.WHO_CALLED_ME (l_owner, l_name,l_lineno,l_caller); end if;
    --apex_debug.info(prefix||' } '||str);
    write_message (prefix, '}', str);
  end;


  /*
  ** **************************************************************************
  */
  procedure err
    (str varchar2
    )
  is
    procedure l (s in varchar2) is
    begin
      --apex_debug.error(prefix||' X '||s);
      write_message (prefix, 'X', s);
    end;
  begin
    l('********************************************************************************');
    if str     > ' ' then l(str);     end if;
    if SQLERRM > ' ' then l(SQLERRM); end if;
    if DBMS_UTILITY.FORMAT_ERROR_BACKTRACE > ' ' then
      l(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    end if;
    if DBMS_UTILITY.FORMAT_CALL_STACK > ' ' then
      l(DBMS_UTILITY.FORMAT_CALL_STACK);
    end if;
    l('********************************************************************************');
  end;

  /*
  ** **************************************************************************
  */
  procedure info
    (str varchar2
    )
  is
  begin
    if not l_caller_stored then OWA_UTIL.WHO_CALLED_ME (l_owner, l_name,l_lineno,l_caller); end if;
    --apex_debug.info(prefix||' * '||str);
    write_message (prefix, '*', str);
  end;


  /*
  ** **************************************************************************
  */
  Procedure afterServerError
  is
    a       ora_name_list_t;
    s       varchar2(32767 byte); -- SQL text
    m       varchar2(32767 byte); -- Error Message
    n       number;

    PRAGMA AUTONOMOUS_TRANSACTION;

  begin
    if not l_caller_stored then OWA_UTIL.WHO_CALLED_ME (l_owner, l_name,l_lineno,l_caller); end if;

    trc.enter ('*** afterServerError ***********************************');

    s := '';
    n := ora_sql_txt(a);
    if n > 0 then
      for i in 1..n loop
        s := s || replace(a(i), chr(0), '');
      end loop;
    end if;
    -- führende und abschließende Zeilenumbrüche entfernen
    if ascii(s) < 32 then
      s := substr(s,2);
    end if;
    if ascii(substr(s, length(s))) < 32 then
      s := substr(s,1,length(s)-1);
    end if;

    m := '';
    n := ora_server_error_depth;
    if n > 0 then
      for i in 1..n loop
        m := substrb(m || ora_server_error_msg(i), 1, 32768);
      end loop;
    end if;

    if m is not null or s is not null then
      --dil.setLastError(dil.err('{sqlerrm}'||' bei [{sql}]', 'sqlerrm', m, 'sql', s));
      trc.err (m);
    else
      trc.err ('no error.');
    end if;

    trc.exit ('*** afterServerError ***********************************');

    commit;

  exception
    when others then
      trc.err ('*** afterServerError ***********************************');
      commit;
  end;


begin
  --enable();
  null;
end;
/
