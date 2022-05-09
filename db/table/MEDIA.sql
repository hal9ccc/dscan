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
  comment        VARCHAR2(4000 char),
  changed_at     timestamp with time zone,
  deleted        number(1)
);

alter table media add  status         VARCHAR2(100);
alter table media add  "COMMENT"      VARCHAR2(4000 char);
alter table media add  changed_at     timestamp with time zone;
alter table media add  deleted        number(1);


ALTER TABLE media ADD (
  CONSTRAINT media_pk PRIMARY KEY (id)
);

ALTER TABLE media ADD (
  CONSTRAINT media_uk UNIQUE (file_name)
);

CREATE SEQUENCE media_seq;