--Genera un fichero, dentro de un directorio del servidor Oracle, con el contenido de una tabla o vista en formato CSV.
--Gustavo Tejerina

DECLARE

  v_fichero     UTL_FILE.FILE_TYPE;
  v_file_name   VARCHAR2(50) := 'salida.csv'; --Nombre de fichero de salida
  v_dir         VARCHAR2(50) := 'DIR'; --Nombre de directorio
  v_table       VARCHAR2(50) := 'EMPLOYEES'; --Nombre de tabla a exportar
  v_where       VARCHAR2(500) := 'WHERE ROWNUM <= 10'; --Cláusula where a ejecutar (si es el caso)
  v_sep         CHAR(1) := ';'; --Separador en CSV
  v_query       VARCHAR2(500);
  TYPE t_out IS REF CURSOR;
  cur_out         t_out;
  v_line        VARCHAR2(20000);
  v_count_cols  NUMBER;
  v_path        VARCHAR2(200);
  CURSOR c_query(v_tab VARCHAR2) IS
    SELECT column_name
      FROM all_tab_cols
     WHERE table_name = UPPER(v_tab)
     ORDER BY column_id;

BEGIN

  --Cuenta de campos de la tabla a exportar
  SELECT COUNT(1)
    INTO v_count_cols
    FROM all_tab_cols
   WHERE table_name = UPPER(v_table);
  --Obtención de path de directorio Oracle
  SELECT directory_path
    INTO v_path
    FROM all_directories
   WHERE directory_name = UPPER(v_dir);

  --Construcción de consulta para cursor variable
  v_table := UPPER(v_table);
  v_query := 'SELECT ';
  FOR r_query IN c_query(v_table) LOOP
    IF c_query%ROWCOUNT ^= v_count_cols THEN
      v_query := v_query || r_query.column_name || '||''' || v_sep || '''||';
    ELSE
      v_query := v_query || r_query.column_name;
    END IF;
  END LOOP;

  --Para añadir cláusula where si es el caso
  IF v_where IS NULL THEN
    v_query := v_query || ' FROM ' || UPPER(v_table);
  ELSE
    v_query := v_query || ' FROM ' || UPPER(v_table) || ' ' || v_where;
  END IF;

  DBMS_OUTPUT.PUT_LINE('- Fichero a generar: ' || v_path || v_file_name);
  DBMS_OUTPUT.PUT_LINE('- Query a emplear: ' || v_query);

  --Apertura de fichero
  v_fichero := UTL_FILE.FOPEN(v_dir, v_file_name, 'W');

  --Ejecución de query y escritura de resultados de la misma en CSV
  DBMS_OUTPUT.PUT_LINE('- Datos en fichero:');
  OPEN cur_out FOR v_query;
  LOOP
    FETCH cur_out INTO v_line;
    EXIT WHEN cur_out%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_line);
    UTL_FILE.PUT_LINE(v_fichero, v_line);
  END LOOP;

  --Cierre de fichero
  UTL_FILE.FCLOSE(v_fichero);

END;
/
