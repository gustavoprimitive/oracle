--Output línea a línea de un campo de tipo CLOB.
--Gustavo Tejerina

DECLARE

  v_clob        CLOB;
  v_cont_ini    NUMBER DEFAULT 1;
  v_cont_fin    NUMBER DEFAULT 0;
  v_out         VARCHAR2(32767);

BEGIN

  --Obtención de campo CLOB
  SELECT campo_clob INTO v_clob FROM tabla WHERE ROWNUM <= 1;

  --Iteración por cada salto de línea dentro del CLOB
  FOR i IN 1 .. REGEXP_COUNT(v_clob, CHR(10)) LOOP
  
    --Primera posición de cada línea
    IF i = 1 THEN
      v_cont_ini := 1;
    ELSE
      v_cont_ini := INSTR(v_clob, CHR(10), 1, i) + 1;
    END IF;
  
    --Posición del salto de cada línea
    v_cont_fin := INSTR(v_clob, CHR(10), 1, i + 1);
  
    --Subcadena   
    v_out := TO_CHAR(SUBSTR(v_clob, v_cont_ini, v_cont_fin - v_cont_ini));
  
    dbms_output.put_line(v_out);
  
  END LOOP;

END;
/
