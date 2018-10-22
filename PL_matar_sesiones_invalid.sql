--Se finalizan las sesiones en estado INVALID.
--Debe ejecutarse con usuario con rol DBA.
--Gustavo Tejerina

DECLARE
  v_cont NUMBER DEFAULT 0;
BEGIN
  DBMS_OUTPUT.ENABLE(buffer_size => NULL);
  FOR reg IN (SELECT 'ALTER SYSTEM KILL SESSION ' || '''' || sid || ',' || serial# || ''' IMMEDIATE' v_ddl FROM v$session WHERE status = 'INVALID' AND type = 'USER') LOOP
    EXECUTE IMMEDIATE reg.v_ddl;
    DBMS_OUTPUT.PUT_LINE(reg.v_ddl);
    v_cont := v_cont + 1;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Finalizada(s) ' || v_cont || ' sesion(es) en estado INVALID');
END;
