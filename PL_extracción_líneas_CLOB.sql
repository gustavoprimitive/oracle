--Output línea a línea de un campo de tipo CLOB.
--Gustavo Tejerina

DECLARE

  v_clob        CLOB;
  v_cont_ini    NUMBER DEFAULT 1;
  v_cont_fin    NUMBER DEFAULT 0;
  v_out         VARCHAR2(32767);
  v_cont_lineas NUMBER DEFAULT 0;

BEGIN

  --Obtención de campo CLOB
  SELECT clob_field INTO v_clob FROM prueba WHERE rownum <= 1;

  --Nº de ocurrencias de salto de línea dentro del CLOB
  v_cont_lineas := regexp_count(v_clob, chr(10));

  FOR i IN 1 .. v_cont_lineas LOOP
  
    --Primera posición de cada línea
    IF i = 1 THEN
      v_cont_ini := 1;
    ELSE
      v_cont_ini := instr(v_clob, chr(10), 1, i) + 1;
    END IF;
  
    --Posición del salto de cada línea
    v_cont_fin := instr(v_clob, chr(10), 1, i + 1);
  
    --Subcadena   
    v_out := to_char(substr(v_clob, v_cont_ini, v_cont_fin - v_cont_ini));
  
    dbms_output.put_line(v_out);
  
  END LOOP;

END;
/
