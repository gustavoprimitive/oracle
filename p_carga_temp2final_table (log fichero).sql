  /*
  @P_DATA_TEMP2END_TABLE
  Procedimiento para la carga de datos mediante bulk binds desde una tabla temporal a la tabla final del modelo de datos.
  Parámetros: 
  - load_log. Tipo boolean, si true: se generan trazas de seguimiento. Por defecto, true.
  - no_logging. Tipo boolean, si true: cambia la tabla destino a modo nologging mientras dura la carga. Por defecto, true. 
  - no_constraints. Tipo boolean, si true: deshabilita las constraints de la tabla destino mientras dura la carga. Por defecto, true. 
  - bulks_size. Tipo pls_integer: número de registros de cada volcado del cursor a la colección. Por defecto, 100.
  - trunc_end_table: Tipo boolean, si true: trunca ta tabla destino antes de comenzar la carga. Por defecto, false.
  - dir. Tipo varchar2: nombre del directorio en el que se generará el fichero de trazas.
  
  Nota: Se deben sustituir las cadenas:
  - "source_table" por el nombre de la tabla con los datos de origen,
  - "end_table" por el nombre real de tabla destino,
  
  Gustavo Tejerina
  17/11/2017
  v 1.0
  */

  CREATE OR REPLACE PROCEDURE p_data_temp2end_table(load_log        BOOLEAN DEFAULT TRUE,
                                                    no_logging      BOOLEAN DEFAULT TRUE,
                                                    no_constraints  BOOLEAN DEFAULT TRUE,
                                                    bulks_size      PLS_INTEGER DEFAULT 100,
                                                    trunc_end_table BOOLEAN DEFAULT FALSE,
                                                    dir             VARCHAR2) AS

  --Cursor con los datos de origen a insertar en la tabla destino
  CURSOR cur_source IS
    SELECT * 
      FROM source_table;

  --Tipo colección tabla para volcar el cursor
  TYPE t_cur_source IS TABLE OF cur_source%ROWTYPE;

  --Colección para contener los datos del cursor
  col_source t_cur_source;

  --Contadores
  --Variable contador para el nº de iteración
  v_count NUMBER DEFAULT 0;
  --Variable para comprobar existencia del directorio
  v_check NUMBER DEFAULT 0;
  --Variable contador para el total de registros
  v_sum NUMBER DEFAULT 0;

  --Variables para el tratamiento del fichero
  v_out_file UTL_FILE.FILE_TYPE;
  --Construcción de nombre de fichero
  v_file_name VARCHAR2(100);

  --Excepción
  e_end_exec EXCEPTION;

  --Procedimineto local para escritura de fichero de log
  PROCEDURE p_logger(v_num_rec NUMBER, v_comments VARCHAR2 DEFAULT NULL) IS
  
  BEGIN
  
    IF v_count = 0 OR v_num_rec IS NULL THEN
      --Otros eventos
      utl_file.put_line(v_out_file,
                        '[' || to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || '] ' || $$PLSQL_UNIT || chr(9) || v_comments);
    ELSIF v_count = 1 THEN
      --Inicio de carga
      utl_file.put_line(v_out_file, '[' || to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || '] ' || $$PLSQL_UNIT || chr(9) || 'Comienzo de carga a tabla destino');
      utl_file.put_line(v_out_file, '[' || to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || '] ' || $$PLSQL_UNIT || chr(9) || 'Inserción de bloque en iteración ' 
                                        || v_count || '. Resultado: ' || nvl(v_comments, 'Ok. ') || nvl(v_comments, v_sum || ' Registro(s)'));
    ELSE
      --Salida de resultado de inserción de bloque en tabla destino
      utl_file.put_line(v_out_file, '[' || to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || '] ' || $$PLSQL_UNIT || chr(9) || 'Inserción de bloque en iteración ' 
                                        || v_count || '. Resultado: ' || nvl(v_comments, 'Ok. ') || nvl(v_comments, v_sum || ' Registro(s)'));
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
    
  END;

  --Main
BEGIN

  SELECT COUNT(1)
    INTO v_check
    FROM all_directories
   WHERE DIRECTORY_NAME = dir;

  IF v_check = 0 THEN
    dbms_output.put_line('ERROR. No se encuentra el directorio ' || dir);
    RAISE e_end_exec;
  END IF;

  --Construcción de nombre de fichero
  v_file_name := lower($$PLSQL_UNIT) || '_' || to_char(SYSDATE, 'DD-MM-YYYY-HH24:MI:SS') || '.log';
  --Apertura de fichero
  v_out_file := sys.UTL_FILE.FOPEN(dir, v_file_name, 'W');

  --Si trunc_end_table = true, limpiado de tabla destino
  IF trunc_end_table THEN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || 'end_table';
    p_logger(NULL, 'Ejecutado truncado de la tabla destino');
  END IF;

  --Si no_logging = true, se pasa a modo nologging la tabla destino
  IF no_logging THEN
    EXECUTE IMMEDIATE 'ALTER TABLE ' || 'end_table' || ' NOLOGGING';
    p_logger(NULL, 'Modificada la tabla destino a propiedad "nologging"');
  END IF;

  --Si no_constraints = true, se deshabilitan las restricciones de la tabla destino
  IF no_constraints THEN
    FOR cur_no_constraints IN (SELECT 'ALTER TABLE ' || table_name || ' DISABLE CONSTRAINT ' || constraint_name AS v_order
                                 FROM all_constraints
                                WHERE table_name = 'end_table') LOOP
    
      EXECUTE IMMEDIATE cur_no_constraints.v_order;
    
    END LOOP;
  
    p_logger(NULL, 'Desahabilitadas las restricciones de la tabla destino');
  
  END IF;

  --Apertura de cursor
  OPEN cur_source;

  --Recorrido del cursor
  LOOP
  
    BEGIN
    
      --Volcado a colección en bloques de 100 registros (por defecto)
      FETCH cur_source BULK COLLECT INTO col_source LIMIT bulks_size;
    
      --Incremento para el número de iteración
      v_count := v_count + 1;
    
      --Inserción de bloque como bulk binds y con el hint append
      FORALL i IN col_source.first .. col_source.last
        INSERT /*+ APPEND */ INTO end_table
        VALUES col_source(i);
      COMMIT;
    
      --Incremento de número de registros totales
      v_sum := v_sum + col_source.count;
    
      --Llamada a procedimineto local de log con resultado ok
      IF load_log THEN
        p_logger(col_source.count);
      END IF;
    
      --Salida con cursor sin datos
      EXIT WHEN cur_source%NOTFOUND;
    
    EXCEPTION
      WHEN OTHERS THEN
        --Llamada a procedimineto local de log con resultado error
        IF load_log THEN
          p_logger(col_source.count, 'ERROR: Fallo en bucle. ' || SQLERRM);
        ELSE
          NULL;
        END IF;
      
    END;
  
  END LOOP;

  --Cierre de cursor
  CLOSE cur_source;

  --Si no_logging = true, se restablece el modo logging de la tabla destino
  IF no_logging THEN
    EXECUTE IMMEDIATE 'ALTER TABLE ' || 'end_table' || ' LOGGING';
    p_logger(NULL, 'Restrablecida la tabla destino a propiedad "logging"');
  END IF;

  --Si no_constraints = true, se habilitan de nuevo las restricciones de la tabla destino
  IF no_constraints THEN
    FOR cur_no_constraints IN (SELECT 'ALTER TABLE ' || table_name || ' ENABLE CONSTRAINT ' || constraint_name AS v_order
                                 FROM all_constraints
                                WHERE table_name = 'end_table') LOOP
    
      EXECUTE IMMEDIATE cur_no_constraints.v_order;
    
    END LOOP;
  
    p_logger(NULL, 'Habilitadas las restricciones de la tabla destino');
  
  END IF;

  --Output de final de carga
  p_logger(NULL, 'Fin de carga a tabla destino');
  p_logger(NULL, 'Total: ' || v_sum || ' registro(s) en ' || v_count || ' bloque(s)');

  --Cierre de fichero
  utl_file.fclose(v_out_file);

EXCEPTION
  WHEN OTHERS THEN
  
    ROLLBACK;
    IF load_log THEN
      --Llamada a procedimineto local de log con resultado error
      p_logger(NULL, 'ERROR: Excepción global. ' || SQLERRM);
      dbms_output.put_line('ERROR: Excepción global. ' || SQLERRM);
    END IF;
  
END;
/
