--Finaliza una sesión Oracle a partir del nombre del servidor y del ID del proceso de dicha sesión.
--Gustavo Tejerina

SET SERVEROUTPUT ON

DECLARE

  v_proceso NUMBER := '&v_proceso'; --Nº de proceso en S.O. 
  v_sid    v$session.sid%TYPE;
  v_serial v$process.serial#%TYPE;

BEGIN

  SELECT s.sid, s.serial#
    INTO v_sid, v_serial
    FROM v$session s, v$process p
   WHERE regexp_substr(s.process,'^[0-9]+') = v_proceso   
     AND s.paddr = p.addr;

  EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION ''' || v_sid || ',' || v_serial || ''' IMMEDIATE';

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    dbms_output.put_line('ERROR. Proceso no encontrado');
  WHEN OTHERS THEN
    dbms_output.put_line(SQLERRM);
END;
/
