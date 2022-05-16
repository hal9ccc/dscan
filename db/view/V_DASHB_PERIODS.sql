drop table PERIODS;
create table PERIODS
 (rn           number         not null primary key,
  rn_prev      number         not null,
  rn_next      number         not null,
  name         varchar2(100)  not null,
  type         number         not null,
  from_base    varchar2(2)    not null  check ( from_base     in ('n', 's', 'mi', 'h', 'd', 'w', 'm', 'y')),
  from_add     number         not null,
  from_add_iv  varchar2(2)    not null  check ( from_add_iv   in ('n', 's', 'mi', 'h', 'd', 'w', 'm', 'y')),
  to_base      varchar2(2)    not null  check ( to_base       in ('n', 's', 'mi', 'h', 'd', 'w', 'm', 'y')),
  to_add       number         not null,
  to_add_iv    varchar2(2)    not null  check ( to_add_iv     in ('n', 's', 'mi', 'h', 'd', 'w', 'm', 'y')),
  to_minus_1ms number         default 1 check ( to_minus_1ms  in (0,1)),
  to_eom       number         default 1 check ( to_eom        in (0,1))
 );


delete periods;
select * from PERIODS;

insert into periods values ( -1460,     -1460,     -1095,     '3 years ago'     , 5   , 'y'     ,  -   3, 'y' ,  'y' ,      -   2, 'y' , 1, 0);
insert into periods values ( -1095,     -1460,      -730,     '2 years ago'     , 5   , 'y'     ,  -   2, 'y' ,  'y' ,      -   1, 'y' , 1, 0);
insert into periods values (  -180,      -730,      -150,     '6 months ago'    , 4   , 'm'     ,  -   6, 'm' ,  'm' ,      -   6, 'm' , 1, 1);
insert into periods values (  -150,      -180,      -120,     '5 months ago'    , 4   , 'm'     ,  -   5, 'm' ,  'm' ,      -   5, 'm' , 1, 1);
insert into periods values (  -120,      -150,       -90,     '4 months ago'    , 4   , 'm'     ,  -   4, 'm' ,  'm' ,      -   4, 'm' , 1, 1);
insert into periods values (   -90,      -120,       -60,     '3 months ago'    , 4   , 'm'     ,  -   3, 'm' ,  'm' ,      -   3, 'm' , 1, 1);
insert into periods values (   -60,       -90,       -30,     '2 months ago'    , 4   , 'm'     ,  -   2, 'm' ,  'm' ,      -   2, 'm' , 1, 1);
insert into periods values (   -28,       -30,       -21,     '4 weeks ago'     , 3   , 'w'     ,  -  28, 'd' ,  'w' ,      -  21, 'd' , 1, 0);
insert into periods values (   -21,       -28,       -14,     '3 weeks ago'     , 3   , 'w'     ,  -  21, 'd' ,  'w' ,      -  14, 'd' , 1, 0);
insert into periods values (   -14,       -21,        -7,     '2 weeks ago'     , 3   , 'w'     ,  -  14, 'd' ,  'w' ,      -   7, 'd' , 1, 0);
insert into periods values (   -10,        -6.001,    -9,     '10 days ago'     , 2   , 'd'     ,  -  10, 'd' ,  'd' ,      -   9, 'd' , 1, 0);
insert into periods values (    -9,        -8,        -8,     '9 days ago'      , 2   , 'd'     ,  -   9, 'd' ,  'd' ,      -   8, 'd' , 1, 0);
insert into periods values (    -8,        -8,        -7,     '8 days ago'      , 2   , 'd'     ,  -   8, 'd' ,  'd' ,      -   7, 'd' , 1, 0);
insert into periods values (    -7,        -8,        -6,     '7 days ago'      , 2   , 'd'     ,  -   7, 'd' ,  'd' ,      -   6, 'd' , 1, 0);
insert into periods values (    -6,        -7,        -5,     '6 days ago'      , 2   , 'd'     ,  -   6, 'd' ,  'd' ,      -   5, 'd' , 1, 0);
insert into periods values (    -5,        -6,        -4,     '5 days ago'      , 2   , 'd'     ,  -   5, 'd' ,  'd' ,      -   4, 'd' , 1, 0);
insert into periods values (    -4,        -5,        -3,     '4 days ago'      , 2   , 'd'     ,  -   4, 'd' ,  'd' ,      -   3, 'd' , 1, 0);
insert into periods values (    -3,        -4,        -2,     '3 days ago'      , 2   , 'd'     ,  -   3, 'd' ,  'd' ,      -   2, 'd' , 1, 0);
insert into periods values (    -2,        -3,        -1,     '2 days ago'      , 2   , 'd'     ,  -   2, 'd' ,  'd' ,      -   1, 'd' , 1, 0);
insert into periods values (    -0.299,    -1,        -0.29,  '10 hours ago'    , 1   , 'h'     ,  -  10, 'h' ,  'h' ,      -   9, 'h' , 1, 0);
insert into periods values (    -0.29,     -0.299,    -0.28,  '9 hours ago'     , 1   , 'h'     ,  -   9, 'h' ,  'h' ,      -   8, 'h' , 1, 0);
insert into periods values (    -0.28,     -0.29,     -0.27,  '8 hours ago'     , 1   , 'h'     ,  -   8, 'h' ,  'h' ,      -   7, 'h' , 1, 0);
insert into periods values (    -0.27,     -0.28,     -0.26,  '7 hours ago'     , 1   , 'h'     ,  -   7, 'h' ,  'h' ,      -   6, 'h' , 1, 0);
insert into periods values (    -0.26,     -0.27,     -0.25,  '6 hours ago'     , 1   , 'h'     ,  -   6, 'h' ,  'h' ,      -   5, 'h' , 1, 0);
insert into periods values (    -0.25,     -0.26,     -0.24,  '5 hours ago'     , 1   , 'h'     ,  -   5, 'h' ,  'h' ,      -   4, 'h' , 1, 0);
insert into periods values (    -0.24,     -0.25,     -0.23,  '4 hours ago'     , 1   , 'h'     ,  -   4, 'h' ,  'h' ,      -   3, 'h' , 1, 0);
insert into periods values (    -0.23,     -0.24,     -0.22,  '3 hours ago'     , 1   , 'h'     ,  -   3, 'h' ,  'h' ,      -   2, 'h' , 1, 0);
insert into periods values (    -0.22,     -0.23,     -0.21,  '2 hours ago'     , 1   , 'h'     ,  -   2, 'h' ,  'h' ,      -   1, 'h' , 1, 0);
insert into periods values (  -365.002,  -730,      -365.001, 'last 12 months'  , 0.01, 'n'     ,  -  12, 'm' ,  'n' ,          0, 'h' , 0, 0);
insert into periods values (  -365.001,  -365.002,   -30.001, 'last 365 days'   , 0.01, 'n'     ,  - 365, 'd' ,  'n' ,          0, 'h' , 0, 0);
insert into periods values (   -30.001,  -365.001,    -6.001, 'last 30 days'    , 0.01, 'n'     ,  -  30, 'd' ,  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -6.001,   -30.001,    -5.001, 'last 7 days'     , 0.01, 'n'     ,  -   7, 'd' ,  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -5.001,    -6.001,    -3.001, 'last 5 days'     , 0.01, 'n'     ,  -   5, 'd' ,  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -3.001,    -5.001,    -0.15,  'last 3 days'     , 0.01, 'n'     ,  -   3, 'd' ,  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -0.15,     -3.001,    -0.14,  'last 48 hours'   , 0.01, 'n'     ,  -  48, 'h' ,  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -0.14,     -0.15,     -0.13,  'last 24 hours'   , 0.01, 'n'     ,  -  24, 'h' ,  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -0.13,     -0.14,     -0.12,  'last 8 hours'    , 0.01, 'n'     ,  -   8, 'h' ,  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -0.12,     -0.13,     -0.11,  'last 4 hours'    , 0.01, 'n'     ,  -   4, 'h' ,  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -0.11,     -0.12,     -0.1,   'last hour'       , 0.01, 'n'     ,  -   1, 'h' ,  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -0.0015,   -0.11,      0.0014,'last 30 minutes' , 0.01, 'n'     ,  -  30, 'mi',  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -0.0014,   -0.0015,    0.0013,'last 15 minutes' , 0.01, 'n'     ,  -  15, 'mi',  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -0.0013,   -0.0014,    0.0012,'last 10 minutes' , 0.01, 'n'     ,  -  10, 'mi',  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -0.0012,   -0.0013,    0.0011,'last 5 minutes'  , 0.01, 'n'     ,  -   5, 'mi',  'n' ,          0, 'h' , 0, 0);
insert into periods values (    -0.0011,   -0.0012,    0.001, 'previous minute' , 0.01, 'mi'    ,  -   1, 'mi',  'mi',      +   0, 'mi', 1, 0);
insert into periods values (    -0.21,     -0.22,     -0.201, 'previous hour'   , 1   , 'h'     ,  -   1, 'h' ,  'h' ,      -   0, 'h' , 1, 0);
insert into periods values (    -1,        -2,        -0.1,   'yesterday'       , 2   , 'd'     ,  -   1, 'd' ,  'd' ,      -   0, 'd' , 1, 0);
insert into periods values (    -7.1,     -14,        -6.001, 'previous week'   , 3   , 'w'     ,  -   7, 'd' ,  'w' ,      -   0, 'd' , 1, 0);
insert into periods values (   -30,       -60,       -28,     'previous month'  , 4   , 'm'     ,  -   1, 'm' ,  'm' ,      -   1, 'm' , 1, 1);
insert into periods values (  -730,     -1095,      -180,     'previous year'   , 5   , 'y'     ,  -   1, 'y' ,  'y' ,      -   0, 'y' , 1, 0);
insert into periods values (     0,        -0.0011,    0.001, 'now'             , 0   , 'n'     ,  -   0, 'mi',  'n' ,      +   0, 'mi', 0, 0);
insert into periods values (     0.001,     0,         0.1,   'current minute'  , 0.01, 'mi'    ,  -   0, 'mi',  'mi',      +   1, 'mi', 1, 0);
insert into periods values (     0.1,       0.008,     0.21,  'current hour'    , 1   , 'h'     ,  -   0, 'h' ,  'h' ,      +   1, 'h' , 1, 0);
insert into periods values (     1,         0.1,       1.007, 'today'           , 2   , 'd'     ,  -   0, 'd' ,  'd' ,      +   1, 'd' , 1, 0);
insert into periods values (     1.007,     1,         1.030, 'current week'    , 3   , 'w'     ,  -   0, 'd' ,  'w' ,      +   7, 'd' , 1, 0);
insert into periods values (     1.030,     1.007,     1.365, 'current month'   , 4   , 'm'     ,  -   0, 'm' ,  'm' ,      +   0, 'm' , 1, 1);
insert into periods values (     1.365,     1.030,     2,     'current year'    , 5   , 'y'     ,  -   0, 'd' ,  'y' ,      +   1, 'y' , 1, 0);
insert into periods values (     0.002,     0.001,     0.003, 'in 1 minute'     , 0.01, 'mi'    ,  +   1, 'mi',  'mi',      +   2, 'mi', 1, 0);
insert into periods values (     0.003,     0.002,     0.004, 'in 2 minutes'    , 0.01, 'mi'    ,  +   2, 'mi',  'mi',      +   3, 'mi', 1, 0);
insert into periods values (     0.004,     0.003,     0.005, 'in 5 minutes'    , 0.01, 'mi'    ,  +   5, 'mi',  'mi',      +   6, 'mi', 1, 0);
insert into periods values (     0.005,     0.004,     0.006, 'in 10 minutes'   , 0.01, 'mi'    ,  +  10, 'mi',  'mi',      +  10, 'mi', 1, 0);
insert into periods values (     0.006,     0.005,     0.007, 'in 15 minutes'   , 0.01, 'mi'    ,  +  15, 'mi',  'mi',      +  15, 'mi', 1, 0);
insert into periods values (     0.007,     0.006,     0.008, 'in 30 minutes'   , 0.01, 'mi'    ,  +  30, 'mi',  'mi',      +  30, 'mi', 1, 0);
insert into periods values (     0.008,     0.007,     0.21,  'in 45 minutes'   , 0.01, 'mi'    ,  +  45, 'mi',  'mi',      +  45, 'mi', 1, 0);
insert into periods values (     0.21,      0.1,       0.22,  'in 1 hour'       , 0.1 , 'mi'    ,  +   1, 'h' ,  'mi',      +   2, 'h' , 1, 0);
insert into periods values (     0.22,      0.21,      0.23,  'in 2 hours'      , 0.1 , 'mi'    ,  +   2, 'h' ,  'mi',      +   3, 'h' , 1, 0);
insert into periods values (     0.23,      0.22,      0.24,  'in 3 hours'      , 0.1 , 'mi'    ,  +   3, 'h' ,  'mi',      +   4, 'h' , 1, 0);
insert into periods values (     0.24,      0.23,      0.25,  'in 4 hours'      , 0.1 , 'mi'    ,  +   4, 'h' ,  'mi',      +   5, 'h' , 1, 0);
insert into periods values (     0.25,      0.24,      0.26,  'in 5 hours'      , 0.1 , 'mi'    ,  +   5, 'h' ,  'mi',      +   6, 'h' , 1, 0);
insert into periods values (     0.26,      0.25,      0.27,  'in 6 hours'      , 0.1 , 'mi'    ,  +   6, 'h' ,  'mi',      +   7, 'h' , 1, 0);
insert into periods values (     0.27,      0.26,      0.28,  'in 12 hours'     , 0.1 , 'mi'    ,  +  12, 'h' ,  'mi',      +  13, 'h' , 1, 0);
insert into periods values (     0.28,      0.27,      2,     'in 24 hours'     , 0.1 , 'mi'    ,  +  24, 'h' ,  'mi',      +  25, 'h' , 1, 0);
insert into periods values (     2,         1.365,     3,     'tomorrow'        , 2   , 'd'     ,  +   1, 'd' ,  'd' ,      +   2, 'd' , 1, 0);
insert into periods values (     3,         2,         4,     'in 2 days'       , 2   , 'd'     ,  +   2, 'd' ,  'd' ,      +   3, 'd' , 1, 0);
insert into periods values (     4,         3,         5,     'in 3 days'       , 2   , 'd'     ,  +   3, 'd' ,  'd' ,      +   4, 'd' , 1, 0);
insert into periods values (     5,         4,         6,     'in 4 days'       , 2   , 'd'     ,  +   4, 'd' ,  'd' ,      +   5, 'd' , 1, 0);
insert into periods values (     6,         5,        14,     'in 5 days'       , 2   , 'd'     ,  +   5, 'd' ,  'd' ,      +   6, 'd' , 1, 0);
insert into periods values (    14,         6,        14,     'next week'       , 3   , 'w'     ,  +   7, 'd' ,  'w' ,      +  14, 'd' , 1, 0);

commit;

create or replace view V_DASHB_PERIODS as
with T as (select * from V_NOW where not exists (select 1 from GT_NOW)
           UNION ALL
           select * from GT_NOW
          ),
     F as (select 0 as TYPE, 'Now' as TYPE_DESCR, 'Dy DD.MM.YYYY HH24:MI:SS' as FMT from dual union all
           select 0.01,      'Second',         'Dy DD.MM.RR HH24:MI:SS'             from dual union all
           select 0.1,       'Minute',         'Dy DD.MM.RR HH24:MI'                from dual union all
           select 1,         'Hour',           'Dy DD.MM.RR HH24:"00"'              from dual union all
           select 2,         'Day',            'Dy DD.MM.RR'                        from dual union all
           select 3,         'Week',           '"CW" IW RR'                         from dual union all
           select 4,         'Month',          'Mon YYYY'                           from dual union all
           select 5,         'Year',           'YYYY'                               from dual
          )
Select "NOW","RN",RN_PREV,RN_NEXT,"NAME","TYPE","BEGIN","END",
       APP_UTIL.UNIX_MILLIS(BEGIN) as BEGIN_MILLIS,
       APP_UTIL.UNIX_MILLIS(END  ) as END_MILLIS,
       FMT,
       TYPE_DESCR,
       to_char("BEGIN", FMT) || decode(to_char("BEGIN", FMT), to_char("END", FMT), '', ' - '||to_char("END", FMT)) as DESCR
from
 (select T.now,
         P.RN,
         P.RN_PREV,
         P.RN_NEXT,
         P.NAME,
         P.TYPE,
         F.FMT,
         F.TYPE_DESCR,
         APP_UTIL.calc_ts( name, decode(from_base, 'n', now, 's', second, 'mi', minute, 'h', hour, 'd', day, 'w', week, 'm', month, 'y', year), from_add, decode(from_add_iv, 'ms', i_ms, 's', i_s, 'mi', i_mi, 'h', i_h, 'd', i_d), decode(from_add_iv, 'm', i_m, 'y', i_y), 0           , 0      ) as "BEGIN",
         APP_UTIL.calc_ts( name, decode(to_base  , 'n', now, 's', second, 'mi', minute, 'h', hour, 'd', day, 'w', week, 'm', month, 'y', year), to_add  , decode(to_add_iv,   'ms', i_ms, 's', i_s, 'mi', i_mi, 'h', i_h, 'd', i_d), decode(to_add_iv,   'm', i_m, 'y', i_y), to_minus_1ms, to_eom ) as "END"
  from   T, periods P join F on F.TYPE = P.TYPE
 ) Q1
;

truncate table trace;
select * from trace where ts > sysdate - interval '5' minute order by 1;

select add_months(systimestamp - numtodsinterval(81, 'DAY'), 1) from dual;


select * from V_NOW;
select * from PERIODS;
select * from V_DASHB_PERIODS order by type desc, rn;
select * from V_DASHB_PERIODS where name = 'current month';
select * from PERIODS where name = 'current month';
select * from V_DASHB_PERIODS where TYPE_DESCR = 'Month';