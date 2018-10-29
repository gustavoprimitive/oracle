--Finaliza una sesión Oracle a partir del nombre del servidor y del ID del proceso de dicha sesión.
--Gustavo Tejerina

DECLARE

  v_sid    v$session.sid%TYPE;
  v_serial v$process.serial#%TYPE;

BEGIN

  SELECT s.sid, s.serial#
    INTO v_sid, v_serial
    FROM v$session s, v$process p, v$instance i
   WHERE p.spid = '&v_proceso' --Nº de proceso en S.O.
     AND s.paddr = p.addr
     AND UPPER(i.host_name) = UPPER('&v_host'); --Hostname de máquina

  EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION ''' || v_sid || ',' || v_serial || ''' IMMEDIATE';

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    dbms_output.put_line('Proceso no encontrado');
  WHEN OTHERS THEN
    dbms_output.put_line(SQLERRM);
END;
/
