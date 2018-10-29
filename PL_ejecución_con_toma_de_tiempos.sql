--Itera una ejecuci�n el n�mero de veces deseado para obtener trazas con los tiempos invertidos
--Gustavo Tejerina

DECLARE

  v_num_iter NUMBER := '&v_num_iter'; --N� de ejecuciones a realizar
  v_ini      TIMESTAMP;
  v_fin      TIMESTAMP;
  v_interv   INTERVAL DAY(1) TO SECOND(6);
  v_horas    NUMBER DEFAULT 0;
  v_minutos  NUMBER DEFAULT 0;
  v_segundos NUMBER DEFAULT 0;

BEGIN

  FOR i IN 1 .. v_num_iter LOOP
  
    --Momento de inicio de ejecuci�n
    v_ini := systimestamp;
  
    --Traza
    dbms_output.put_line(v_ini || chr(9) || 'INFO' || chr(9) || 'Ejecuci�n #' || i);
  
    --Aqu� ir�a el c�digo del que se quieren registrar los tiempos ->
    --Generaci�n de delay de entre 1 y 3 segundos
    dbms_lock.sleep(dbms_random.value(1, 3));
    -- <- Aqu� ir�a el c�digo del que se quieren registrar los tiempos
  
    --Momento de fin de ejecuci�n
    v_fin := systimestamp;
  
    --Obtenci�n de intervalo
    v_interv   := v_fin - v_ini;
    v_horas    := extract(hour FROM v_interv);
    v_minutos  := extract(minute FROM v_interv);
    v_segundos := extract(SECOND FROM v_interv);
  
    --Traza
    dbms_output.put_line(chr(9) || v_horas || ' hora(s) ' || v_minutos || ' minuto(s) ' || v_segundos || ' segundo(s)' || dchr(10));
  
  END LOOP;

END;
/
