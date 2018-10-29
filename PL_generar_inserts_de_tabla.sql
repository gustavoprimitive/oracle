--Genera las sentencias DML de inserción a partir de los registros de una tabla.
--Gustavo Tejerina

SET SERVEROUTPUT ON

DECLARE

  v_tabla all_tables.table_name%TYPE := 'table_mod_level'; --Nombre de la tabla
  v_where VARCHAR2(32767) := 'WHERE ROWNUM <= 2'; --Cláusula WHERE para restringir los registros de la tabla
  
  CURSOR cur_tab_cols(v_tabla VARCHAR2) IS
    SELECT column_name, data_type
      FROM all_tab_cols
     WHERE table_name = v_tabla
       AND owner = 'SA'
     ORDER BY column_id;
	 
  v_query      VARCHAR2(32767);
  v_count_cols NUMBER DEFAULT 0;
  cur_output   SYS_REFCURSOR;
  v_output     VARCHAR2(32767);

begin

  dbms_output.enable(NULL);

  --Obtención de número de columnas de la tabla
  SELECT COUNT(*)
    INTO v_count_cols
    FROM all_tab_cols
   WHERE table_name = UPPER(v_tabla);

  --Formación de la cabecera de la consulta
  v_query := 'SELECT ' || '''' || 'INSERT INTO ' || v_tabla || '(';
  FOR r_tab_cols IN cur_tab_cols(UPPER(v_tabla)) LOOP
    IF cur_tab_cols%ROWCOUNT < v_count_cols THEN
      v_query := v_query || LOWER(r_tab_cols.column_name) || ',';
    ELSE
      v_query := v_query || LOWER(r_tab_cols.column_name) || ') VALUES(' || '''' || '||';
    END IF;
  END LOOP;

  --Formación de la parte de la consulta para la obtención de valores
  FOR r_tab_cols IN cur_tab_cols(UPPER(v_tabla)) LOOP
    --No numéricos
	IF r_tab_cols.data_type IN ('CHAR', 'VARCHAR2', 'DATE') THEN
      IF cur_tab_cols%ROWCOUNT < v_count_cols THEN
        v_query := v_query || '''' || '''' || '''' || '''||' || r_tab_cols.column_name || '||''' || '''' || '''' || '''' || '||''' || ',' || '''||';
      ELSE
        v_query := v_query || '''' || '''' || '''' || '''||' || r_tab_cols.column_name || '||''' || '''' || '''' || ');' || '''';
      END IF;
    --Numéricos
    ELSE
      IF cur_tab_cols%ROWCOUNT < v_count_cols THEN
        v_query := v_query || 'NVL(REPLACE(TO_CHAR(' || r_tab_cols.column_name || '),' || ''',' || ''',' || '''.' || '''' || '),''' || 'NULL' || '''' || ')' || '||''' || ',' || '''||';
      ELSE
        v_query := v_query || 'NVL(REPLACE(TO_CHAR(' || r_tab_cols.column_name || '),' || ''',' || ''',' || '''.' || '''' || '),''' || 'NULL' || '''' || ')' || '||''' || ');' || '''';
      END IF;
    END IF;
  END LOOP;

  v_query := v_query || ' from ' || v_tabla || ' ' || v_where;

  --Output de consulta
  dbms_output.put_line(v_query);
  --Output de cursor con las dml de inserción de los registros
  OPEN cur_output FOR v_query;
  LOOP
    FETCH cur_output INTO v_output;
    EXIT WHEN cur_output%NOTFOUND;
    dbms_output.put_line(v_output);
  END LOOP;

END;
/