CREATE TABLE media (
  id             NUMBER(10)     NOT NULL,
  content_type   VARCHAR2(100)  NOT NULL,
  file_name      VARCHAR2(100)  NOT NULL,
  content        BLOB           ,
  type           VARCHAR2(100)  NOT NULL,
  title          VARCHAR2(100)  NOT NULL,
  timestamp      timestamp      NOT NULL,
  idx            int            NOT NULL,
  device         VARCHAR2(100)
);


ALTER TABLE media ADD (
  CONSTRAINT media_pk PRIMARY KEY (id)
);

ALTER TABLE media ADD (
  CONSTRAINT media_uk UNIQUE (file_name)
);

CREATE SEQUENCE media_seq;