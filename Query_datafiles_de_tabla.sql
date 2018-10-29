--Datafiles en que reside una determinada tabla
SELECT t.name AS TABLESPACE, d.name DATAFILE, d.status, d.enabled
  FROM v$datafile d, v$tablespace t
 WHERE d.ts# = t.ts#
   AND t.name IN (SELECT DISTINCT tablespace_name
                   FROM dba_extents
                  WHERE UPPER(segment_name) = UPPER('TABLE_X_POP_UP')) --Nombre de la tabla
 ORDER BY 1, 2;

