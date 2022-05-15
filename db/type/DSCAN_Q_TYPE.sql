-- Create payload database type.
CREATE OR REPLACE TYPE DSCAN_Q_TYPE AS OBJECT (
  id            VARCHAR2(255),
  cid           INT,
  details       VARCHAR2(4000)
);
/
