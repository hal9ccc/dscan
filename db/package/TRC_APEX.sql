CREATE OR REPLACE PACKAGE TRC_APEX AS
  /*
  ** kombiniertes Trace für APEX_DEBUG, DBMS_OUTPUT und einfache Tabelle
  **
  **
  ** Erstellen der Tabelle mit:
  **

  create table TRACE
  (
    TS   timestamp(6),
    NR   number,
    SRC  varchar2(100),
    TYPE varchar2(1),
    MSG  varchar2(4000)
  );

  */

  nr                     number := 0; -- Nummer des Trace-Eintrags im aktuellen Request

  l_owner                varchar2(200);
  l_name                 varchar2(200);
  l_lineno               number;
  l_caller               varchar2(200);
  l_caller_stored        boolean := false;


  booEnabled  boolean := false;
  --incr        constant INTERVAL DAY TO SECOND := interval '1' day / 86400000000;
  --curoffs     INTERVAL DAY TO SECOND := interval '0' day;

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
   );

  procedure msg
   (str varchar2
   );

  function msg
   (str varchar2
   ) return varchar2;

  procedure exit
   (str varchar2
   );

  procedure err
   (str varchar2
   );

  procedure info
   (str varchar2
   );

  Procedure afterServerError;

end;
/
create or replace synonym trc for trc_apex;