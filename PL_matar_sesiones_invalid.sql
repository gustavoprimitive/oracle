--Se finalizan las sesiones en estado INVALID.
--Debe ejecutarse con usuario con rol DBA.
--Gustavo Tejerina

SET SERVEROUTPUT ON

DECLARE

  v_cont NUMBER DEFAULT 0;

BEGIN

  dbms_output.enable(buffer_size => NULL);
  
  FOR reg IN (SELECT 'ALTER SYSTEM KILL SESSION ' || '''' || sid || ',' || serial# || ''' IMMEDIATE' v_ddl FROM v$session WHERE status = 'INVALID' AND type = 'USER') LOOP
    EXECUTE IMMEDIATE reg.v_ddl;
    dbms_output.put_line(reg.v_ddl);
    v_cont := v_cont + 1;
  END LOOP;
  dbms_output.put_line(CHR(10) || 'Finalizada(s) ' || v_cont || ' sesion(es) en estado INVALID');
END;
/