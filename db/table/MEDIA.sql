CREATE TABLE media (
  id             NUMBER(10)     NOT NULL,
  content_type   VARCHAR2(100)  NOT NULL,
  file_name      VARCHAR2(100)  NOT NULL,
  content        BLOB           ,
  type           VARCHAR2(100)  NOT NULL,
  title          VARCHAR2(100)  NOT NULL,
  timestamp      timestamp      NOT NULL,
  idx            int            NOT NULL,
  device         VARCHAR2(100),
  status         VARCHAR2(100),
  cid            number(12),
  hidden         number(1),
  info1          VARCHAR2(4000 char),
  info2          VARCHAR2(4000 char),
  info3          VARCHAR2(4000 char),
  info4          VARCHAR2(4000 char)
);

-- Patch:
--alter table media add  status         VARCHAR2(100);
--alter table media add  cid            number(9);
--alter table media add  hidden         number(1);
--alter table media add  info1          VARCHAR2(4000 char);
--alter table media add  info2          VARCHAR2(4000 char);
--alter table media add  info3          VARCHAR2(4000 char);
--alter table media add  info4          VARCHAR2(4000 char);
select * from media;
update media set status = 'scanned', cid=0;


ALTER TABLE media ADD (
  CONSTRAINT media_pk PRIMARY KEY (id)
);

ALTER TABLE media ADD (
  CONSTRAINT media_uk UNIQUE (file_name)
);

CREATE SEQUENCE media_seq;


--create index media_ui_file_name on media (file_name);
create index media_i_timestamp on media (timestamp);