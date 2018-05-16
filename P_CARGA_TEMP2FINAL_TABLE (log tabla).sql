  /*
  @P_DATA_TEMP2END_TABLE
  Procedimiento para la carga de datos mediante bulk binds desde una tabla temporal a la tabla final del modelo de datos.
  Parámetros: 
  - load_log. Tipo boolean, si true: genera tabla con los datos del volcado. Por defecto, true.
  - no_logging. Tipo boolean, si true: cambia la tabla destino a modo nologging mientras dura la carga. Por defecto, true. 
  - no_constraints. Tipo boolean, si true: deshabilita las constraints de la tabla destino mientras dura la carga. Por defecto, true. 
  - bulks_size. Tipo pls_integer: número de registros de cada volcado del cursor a la colección. Por defecto, 100.
  - trunc_end_table: Tipo boolean, si true: trunca ta tabla destino antes de comenzar la carga. Por defecto, false.
  
  Nota: Se deben sustituir las cadenas:
  - "source_table" por el nombre de la tabla con los datos de origen,
  - "end_table" por el nombre real de tabla destino,
  - "log_table" por el nombre de tabla de log deseado.
  
  17/11/2017
  v 1.0
  */

  CREATE OR REPLACE PROCEDURE p_data_temp2end_table(load_log        BOOLEAN DEFAULT TRUE,
                                                    no_logging      BOOLEAN DEFAULT TRUE,
                                                    no_constraints  BOOLEAN DEFAULT TRUE,
                                                    bulks_size      PLS_INTEGER DEFAULT 100,
                                                    trunc_end_table BOOLEAN DEFAULT FALSE) AS

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
  --Variable para comprobar existencia de tabla log
  v_check NUMBER DEFAULT 0;
  --Variable contador para el total de registros
  v_sum NUMBER DEFAULT 0;

  --Procedimineto local de registro de carga en tabla temporal
  PROCEDURE p_insert_log(v_num_rec  NUMBER,
                         v_comments VARCHAR2 DEFAULT NULL) IS
  
  BEGIN
  
    --Inserción de resultado ok en log
    EXECUTE IMMEDIATE 'INSERT /*+ APPEND */ INTO log_table
                       VALUES (' || v_count || ',' 
                                 || '''' || 'end_table' || '''' || ',' 
                                 || '''' || $$PLSQL_UNIT || '''' || ',' 
                                 || '''' || to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || '''' || ',' 
                                 || v_num_rec || ',' 
                                 || '''' || nvl(v_comments, 'Ok. ' || v_sum || ' Registro(s)') || '''' || ')';
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
    
  END;

  --Main
BEGIN

  --Si load_log = true, se crea la tabla auxiliar de log de carga
  IF load_log THEN
  
    SELECT COUNT(1)
      INTO v_check
      FROM all_tables
     WHERE table_name = upper('log_table');
  
    --Si no existe la tabla de log se crea, si existe se trunca
    IF v_check = 0 THEN
      EXECUTE IMMEDIATE 'CREATE TABLE log_table NOLOGGING (
                            loop_number        NUMBER NULL,
                            end_table          VARCHAR2(100) NULL,
                            procedure_name     VARCHAR2(100) NULL,
                            time_execution     VARCHAR2(100) NULL,
                            records_inserted   NUMBER NULL,
                            comments           VARCHAR2(1000) NULL)';
    ELSE
      EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || 'log_table';
    END IF;
  END IF;

  --Si trunc_end_table = true, limpiado de tabla destino
  IF trunc_end_table THEN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || 'end_table';
  END IF;

  --Si no_logging = true, se pasa a modo nologging la tabla destino
  IF no_logging THEN
    EXECUTE IMMEDIATE 'ALTER TABLE ' || 'end_table' || ' NOLOGGING';
  END IF;

  --Si no_constraints = true, se deshabilitan las restricciones de la tabla destino
  IF no_constraints THEN
    FOR cur_no_constraints IN (SELECT DISTINCT 'ALTER TABLE ' || table_name || ' DISABLE CONSTRAINT ' || constraint_name AS v_order
                                 FROM all_constraints
                                WHERE table_name = 'end_table') LOOP
    
      EXECUTE IMMEDIATE cur_no_constraints.v_order;
    
    END LOOP;
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
        p_insert_log(col_source.count);
      END IF;
    
      --Salida con cursor sin datos
      EXIT WHEN cur_source%NOTFOUND;
    
    EXCEPTION
      WHEN OTHERS THEN
        --Llamada a procedimineto local de log con resultado error
        IF load_log THEN
          p_insert_log(col_source.count, 'ERROR: Fallo en bucle. ' || SQLERRM);
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
  END IF;

  --Si no_constraints = true, se habilitan de nuevo las restricciones de la tabla destino
  IF no_constraints THEN
    FOR cur_no_constraints IN (SELECT DISTINCT 'ALTER TABLE ' || table_name || ' ENABLE CONSTRAINT ' || constraint_name AS v_order
                                 FROM all_constraints
                                WHERE table_name = 'end_table') LOOP
    
      EXECUTE IMMEDIATE cur_no_constraints.v_order;
    
    END LOOP;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
  
    ROLLBACK;
    IF load_log THEN
      --Llamada a procedimineto local de log con resultado error
      p_insert_log(NULL, 'ERROR: Excepción global. ' || SQLERRM);
    END IF;
  
END;
/
