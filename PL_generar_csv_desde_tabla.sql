--Genera un fichero, dentro de un directorio del servidor Oracle, con el contenido de una tabla o vista en formato CSV.
--Gustavo Tejerina

DECLARE

  v_file_name CONSTANT VARCHAR2(50) := 'salida.csv'; --Nombre de fichero de salida
  v_dir       CONSTANT VARCHAR2(50) := 'DIR'; --Nombre de directorio
  v_table     CONSTANT VARCHAR2(50) := 'EMPLOYEES'; --Nombre de tabla a exportar
  v_where     CONSTANT VARCHAR2(500) := 'WHERE ROWNUM <= 10'; --Cláusula where a ejecutar (si es el caso)
  v_sep       CONSTANT CHAR(1) := ';'; --Separador en CSV
  v_query     VARCHAR2(500);
  v_csv_file   utl_file.file_type;
  TYPE t_out IS REF CURSOR;
  cur_out      t_out;
  v_line       VARCHAR2(20000);
  v_count_cols NUMBER;
  v_path       VARCHAR2(200);
  v_txt_error  VARCHAR2(500);
  e_error EXCEPTION;
  
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

  IF v_count_cols = 0 THEN
    v_txt_error := 'ERROR. No se encuentra la tabla ' || v_table;
    RAISE e_error;
  END IF;

  --Obtención de path de directorio Oracle
  BEGIN
    SELECT directory_path
      INTO v_path
      FROM all_directories
     WHERE directory_name = UPPER(v_dir);
  EXCEPTION
    WHEN OTHERS THEN
      v_txt_error := 'ERROR. No se encuentra el directorio ' || v_dir;
      RAISE e_error;
  END;

  --Construcción de consulta para cursor variable
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
    v_query := v_query || ' FROM ' || v_table;
  ELSE
    v_query := v_query || ' FROM ' || v_table || ' ' || v_where;
  END IF;

  dbms_output.put_line('- Fichero a generar: ' || v_path || v_file_name);
  dbms_output.put_line('- Query a emplear: ' || v_query);

  --Apertura de fichero
  BEGIN
    v_csv_file := utl_file.fopen(v_dir, v_file_name, 'W');
  EXCEPTION
    WHEN OTHERS THEN
      v_txt_error := 'ERROR al generar el fichero ' || v_file_name || ' en ' || v_dir;
      RAISE e_error;
  END;

  --Ejecución de query y escritura de resultados de la misma en CSV
  dbms_output.put_line('- Datos en fichero:');

  BEGIN
    OPEN cur_out FOR v_query;
  EXCEPTION
    WHEN OTHERS THEN
      v_txt_error := 'ERROR al ejecutar la consulta';
      RAISE e_error;
  END;

  BEGIN
    LOOP
      FETCH cur_out INTO v_line;
      EXIT WHEN cur_out%NOTFOUND;
      dbms_output.put_line(v_line);
      utl_file.put_line(v_csv_file, v_line);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      v_txt_error := 'ERROR al escribir el fichero ' || v_file_name || ' en ' || v_path;
  END;

  --Cierre de fichero
  utl_file.fclose(v_csv_file);

EXCEPTION
  WHEN e_error THEN
    dbms_output.put_line(chr(9) || v_txt_error);
  
END;
/

