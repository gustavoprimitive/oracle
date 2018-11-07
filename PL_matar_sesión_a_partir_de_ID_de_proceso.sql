--Finaliza una sesión Oracle a partir del ID en el S.O. del proceso de dicha sesión.
--Gustavo Tejerina

SET SERVEROUTPUT ON

DECLARE

  v_proceso NUMBER := &v_proceso; --Nº de proceso en S.O. 
  v_sid     v$session.sid%TYPE;
  v_serial  v$process.serial#%TYPE;
  v_status  v$session.state%TYPE;
  v_check   NUMBER DEFAULT 0;

  --Proceso local para extraer los IDs del proceso en Oracle y su estado 
  PROCEDURE p_datos_proceso(v_proceso NUMBER,
                            v_sid     OUT v$session.sid%TYPE,
                            v_serial  OUT v$session.serial#%TYPE,
                            v_status  OUT v$session.state%TYPE) AS
  BEGIN
  
    SELECT s.sid, s.serial#, s.state
      INTO v_sid, v_serial, v_status
      FROM v$session s, v$process p
     WHERE regexp_substr(s.process, '^[0-9]+') = v_proceso
       AND s.paddr = p.addr;
  
  EXCEPTION
    WHEN OTHERS THEN
      v_sid    := NULL;
      v_serial := NULL;
      v_status := NULL;
  END;

BEGIN

  p_datos_proceso(v_proceso, v_sid, v_serial, v_status);

  --Si se han obtenido los datos del proceso, se finaliza la sesión
  IF v_sid IS NOT NULL AND v_serial IS NOT NULL THEN
    EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION ''' || v_sid || ',' || v_serial || ''' IMMEDIATE';
  
    --Se comprueba si se ha finalizado la sesión
    p_datos_proceso(v_proceso, v_sid, v_serial, v_status);
  
    IF v_status IS NULL THEN
      dbms_output.put_line('Proceso finalizado');
    ELSE
      dbms_output.put_line('El proceso se mantiene en estado ' || v_status);
    END IF;
  
  ELSE
    dbms_output.put_line('ERROR. Proceso no encontrado');
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(SQLERRM);
END;
/
