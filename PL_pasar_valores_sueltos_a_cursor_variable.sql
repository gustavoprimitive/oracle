--Genera una consulta con valores sueltos para asignar a cursor variable. 
--Los valores serán registros distintos de un mismo campo.
--Gustavo Tejerina

SET SERVEROUTPUT ON

DECLARE

  --Cadena con los datos de entrada a procesar
  v_cad CLOB := 'aaa,bbb,ccc,ddd,eee';
  --Cadena con la consulta que se generará
  v_query      CLOB;
  cursorsalida SYS_REFCURSOR;
  v_valor      CLOB;

BEGIN

  v_query := 'SELECT * FROM (';

  --Recorro la cadena tantas veces como ocurrencias de "," más 1
  FOR i IN 1 .. REGEXP_COUNT(v_cad, ',') + 1 LOOP
    IF i < (REGEXP_COUNT(v_cad, ',') + 1) THEN
      --Genero la subconsulta con cada subcadena sobre la tabla DUAL y hago UNION a la siguiente subconsulta que se concatene
      IF i = 1 THEN
        v_query := v_query || 'SELECT ' || '''' || SUBSTR(v_cad, 
														  1, 
														  INSTR(v_cad, ',', 1, i) - 1) 
														  || '''' || ' AS campo FROM dual UNION ALL ';
      ELSE
        v_query := v_query || 'SELECT ' || '''' || SUBSTR(v_cad,
														  INSTR(v_cad, ',', 1, i - 1) + 1,
														  INSTR(v_cad, ',', 1, i) - INSTR(v_cad, ',', 1, i - 1) - 1) 
														  || '''' || ' AS campo FROM dual UNION ALL ';
      END IF;
    ELSE
      v_query := v_query || 'SELECT ' || '''' ||
                 SUBSTR(v_cad,
                        INSTR(v_cad, ',', 1, i - 1) + 1,
                        LENGTH(v_cad) - INSTR(v_cad, ',', 1, i)) 
						|| '''' || ' AS campo FROM dual)';
    END IF;
  END LOOP;

  --Añado la condición
  v_query := v_query || ' WHERE campo ^= ''aaa''';

  --Salida de query
  dbms_output.put_line(v_query);

  OPEN cursorsalida FOR v_query;

  --Salida de contenido de cursor variable
  LOOP
    FETCH cursorsalida INTO v_valor;
    EXIT WHEN cursorsalida%NOTFOUND;
    dbms_output.put_line(v_valor);
  END LOOP;

END;
/
