--Genera un objeto colección de CLOB en el que se almacenan los valores de una cadena (separados por comas) como filas a través de PIPE ROW.
--Gustavo Tejerina

--Creación de tipo objeto de variable CLOB
CREATE OR REPLACE TYPE t_clob AS OBJECT (v_clob CLOB);
/

--Creación de tipo colección tabla del tipo objeto anterior
CREATE OR REPLACE TYPE t_col_clob IS TABLE OF t_clob;
/

--Función que recibe la cadena con los valores separados por comas y los separa y carga en la colección 
CREATE OR REPLACE FUNCTION f_pipe_row(v_cad CLOB) 
RETURN t_col_clob PIPELINED AS

  cursorsalida SYS_REFCURSOR;
  v_valor      CLOB;
  v_ocurr      NUMBER DEFAULT 0;
  
BEGIN
  --Obtención del número de subcadenas
  v_ocurr := LENGTH(v_cad) - LENGTH(REPLACE(v_cad, ',', NULL));
  --Extracción de las subcadenas
  FOR i IN 1 .. v_ocurr + 1 LOOP
    IF i = 1 THEN
      v_valor := SUBSTR(v_cad, 1, INSTR(v_cad, ',', 1, 1) - 1);
    ELSIF i < v_ocurr + 1 THEN
      v_valor := SUBSTR(v_cad,
                        INSTR(v_cad, ',', 1, i - 1) + 1,
                        INSTR(v_cad, ',', 1, i) - INSTR(v_cad, ',', 1, i - 1) - 1);
    ELSE
      v_valor := SUBSTR(v_cad,
                        INSTR(v_cad, ',', 1, i - 1) + 1,
                        LENGTH(v_cad) - INSTR(v_cad, ',', 1, i));
    END IF;
    --Llamada a pipe row con cada subcadena para cargar en la colección
    PIPE ROW(t_clob(v_valor));
  END LOOP;
END;
/

--Bloque anónimo que llama a la función anterior pasánsole la cadena y carga los valores de la misma en el cursor variable
SET SERVEROUTPUT ON

DECLARE

  cursorsalida SYS_REFCURSOR;
  v_cadena     CLOB := 'aaa,bbb,ccc,ddd,eee';
  v_valor      CLOB;
  
BEGIN

  OPEN cursorsalida FOR SELECT * FROM TABLE(f_pipe_row(v_cadena));
  --Recorrido del cursor variable y output de sus valores
  LOOP
    FETCH cursorsalida INTO v_valor;
    EXIT WHEN cursorsalida%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_valor);
  END LOOP;
  
END;
/
