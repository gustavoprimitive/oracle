--Output l�nea a l�nea de un campo de tipo CLOB.
--Gustavo Tejerina

DECLARE

  v_clob        CLOB;
  v_cont_ini    NUMBER DEFAULT 1;
  v_cont_fin    NUMBER DEFAULT 0;
  v_out         VARCHAR2(32767);
  v_cont_lineas NUMBER DEFAULT 0;

BEGIN

  --Obtenci�n de campo CLOB
  SELECT clob_field INTO v_clob FROM prueba WHERE rownum <= 1;

  --N� de ocurrencias de salto de l�nea dentro del CLOB
  v_cont_lineas := REGEXP_COUNT(v_clob, CHR(10));

  FOR i IN 1 .. v_cont_lineas LOOP
  
    --Primera posici�n de cada l�nea
    IF i = 1 THEN
      v_cont_ini := 1;
    ELSE
      v_cont_ini := INSTR(v_clob, CHR(10), 1, i) + 1;
    END IF;
  
    --Posici�n del salto de cada l�nea
    v_cont_fin := INSTR(v_clob, CHR(10), 1, i + 1);
  
    --Subcadena   
    v_out := TO_CHAR(SUBSTR(v_clob, v_cont_ini, v_cont_fin - v_cont_ini));
  
    dbms_output.put_line(v_out);
  
  END LOOP;

END;
/
