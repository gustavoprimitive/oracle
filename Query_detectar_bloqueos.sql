--Ver datos de usuario, sesi�n y objeto bloqueado
SELECT s.sid,
       s.serial#,
       s.osuser "USUARIO SO",
       s.process "ID PROCESO SO",
       s.username "USUARIO BDD",
       o.object_name "NOMBRE OBJETO BDD",
       '(' || o.object_type || ')' "TIPO OBJETO BDD",
       s.program "PROGRAMA",
       o.owner "SCHEMA OBJETO",
       DECODE(l.type,
              'TM','Sentencia DML',
              'TX','Transacci�n',
              'UL','Bloqueo usuario',
              l.type) "TIPO BLOQUEO",
       DECODE(s.command,
              1,'Create table',
              2,'Insert',
              3,'Select',
              6,'Update',
              7,'Delete',
              9,'Create index',
              10,'Drop index',
              11,'Alter index',
              12,'Drop table',
              13,'Create sequence',
              14,'Alter sequence',
              15,'Alter table',
              16,'Drop sequence',
              17,'Grant',
              19,'Create synonym',
              20,'Drop synonym',
              21,'Create view',
              22,'Drop view',
              24,'Create procedure',
              25,'Alter procedure',
              42,'Alter session',
              44,'Commit',
              45,'Rollback',
              46,'Savepoint',
              47,'PL/SQL Exec',
              60,'Alter trigger',
              85,'Truncate table',
              0,'No command',
              '? : ' || s.command) "TIPO SENTENCIA",
       q.sql_text "SENTENCIA"
  FROM v$lock l, dba_objects o, v$session s, v$sql q
 WHERE l.id1 = o.object_id
   AND s.sid = l.sid
   AND q.sql_id = s.sql_id;

--Para finalizar sesi�n que bloquea una tabla
ALTER SYSTEM KILL SESSION 'SID,SERIAL#';
