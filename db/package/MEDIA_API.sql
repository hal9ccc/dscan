CREATE OR REPLACE PACKAGE media_api AS

  PROCEDURE upload (
    p_timestamp     IN  varchar2,
    p_idx           IN  media.idx            %TYPE,
    p_file_name     IN  media.file_name      %TYPE,
    p_content_type  IN  media.content_type   %TYPE,
    p_content       IN  media.content        %TYPE,
    p_type          IN  media.type           %TYPE,
    p_title         IN  media.title          %TYPE,
    p_device        IN  media.device         %TYPE
   );

  PROCEDURE download (p_file_name  IN  media.file_name%TYPE);

END;
/