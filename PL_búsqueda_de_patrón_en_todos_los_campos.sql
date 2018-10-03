--Búsqueda de un patrón en todos los campos de las tablas de un esquema dado
--Los datos de entrada son el patrón de búsqueda y el nombre del esquema
--Gustavo Tejerina

DECLARE

  --Datos de entrada
  v_patron  VARCHAR2(100) := '&v_patron';
  v_esquema all_users.username%TYPE := upper('&v_esquema');

  v_query CLOB;
  v_tabla all_tables.table_name%TYPE;
  TYPE t_col_res IS TABLE OF ROWID;
  v_res t_col_res;
  e_no_existe EXCEPTION;

  --Cursor con los nombres de las tablas del esquema
  CURSOR cur_tablas(v_esquema all_users.username%TYPE) IS
    SELECT table_name 
      FROM all_tables at, all_objects ao 
     WHERE at.table_name = ao.object_name 
       AND object_type = 'TABLE' 
       AND at.owner = v_esquema;

  --Cursor con los nombres de las columnas de la tabla recibida  
  CURSOR cur_campos(v_tabla all_tables.table_name%TYPE) IS
    SELECT column_name, data_type
      FROM all_tab_cols
     WHERE owner = v_esquema
       AND table_name = v_tabla
       AND data_type IN ('NUMBER','CHAR','VARCHAR2','DATE');

  --Subprograma para el output de resultados   
  PROCEDURE p_output_resultado(v_res t_col_res) IS
  BEGIN
  
    dbms_output.put_line('Tabla ' || v_tabla || '. Encontrado el patrón "' || v_patron || '" en el/los siguiente/s valor/es de ROWID: ');
  
    FOR i IN v_res.first .. v_res.last LOOP
      dbms_output.put_line(v_res(i));
    END LOOP;
  
    dbms_output.put_line(chr(10));
  
  END;

--Main
BEGIN

  --Recorrido de tablas de esquema

    FOR r_cur_tablas IN cur_tablas(v_esquema) LOOP
      v_tabla := r_cur_tablas.table_name;
      v_query := 'SELECT ROWID FROM ';
      v_query := v_query || v_esquema || '.' || r_cur_tablas.table_name;
    
      --Recorrido de columnas de tabla
      FOR r_cur_campos IN cur_campos(v_tabla) LOOP
      
        --Si es primera iteración se concatena la cláusula WHERE
        IF cur_campos%ROWCOUNT = 1 THEN
          IF r_cur_campos.data_type IN ('CHAR', 'VARCHAR2') THEN
            v_query := v_query || ' WHERE "' || r_cur_campos.column_name || '" LIKE ''%' || v_patron || '%''';
          ELSE
            v_query := v_query || ' WHERE "' || r_cur_campos.column_name || '" LIKE ''%' || TO_CHAR(v_patron) || '%''';
          END IF;
          --Si no es primera iteración se concatena el operador OR
        ELSE
          IF r_cur_campos.data_type IN ('CHAR', 'VARCHAR2') THEN
            v_query := v_query || ' OR "' || r_cur_campos.column_name || '" LIKE ''%' || v_patron || '%''';
          ELSE
            v_query := v_query || ' OR "' || r_cur_campos.column_name || '" LIKE ''%' || TO_CHAR(v_patron) || '%''';
          END IF;
        END IF;
      END LOOP;
    
      --Ejecución de consulta y volcado de resultados
      /*BEGIN*/
        EXECUTE IMMEDIATE v_query BULK COLLECT INTO v_res;
      /*EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;*/
      --Output si se han encontrado resultados
      IF v_res.count > 0 THEN
        p_output_resultado(v_res);
      END IF;
    
      v_query := NULL;
    
    END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(v_query);
    dbms_output.put_line(SQLERRM);     
  
END;
/
