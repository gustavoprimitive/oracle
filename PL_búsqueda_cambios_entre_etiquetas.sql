--Muestra el código fuente de un bloque almacenado entre los comentarios identificativos de cambio
--Gustavo Tejerina

DECLARE

  v_object    all_source.name%TYPE := 'NBSPM_COMBINACIONPERMITIDA'; --Nombre del programa
  v_label     all_source.text%TYPE := 'NEORIS'; --Texto en etiqueta
  v_owner     all_source.owner%TYPE DEFAULT 'SA';
  v_info      VARCHAR2(500);
  v_firstline NUMBER;
  v_lastline  NUMBER;

  --Líneas con etiqueta
  CURSOR cur_changes IS(
    SELECT ROWNUM, line, s.text
      FROM all_source s
     WHERE s.owner = v_owner
       AND UPPER(s.name) = UPPER(v_object)
       AND UPPER(s.text) LIKE '%--%' || UPPER(v_label) || '%');

  TYPE t_rec_source IS RECORD(v_line all_source.line%TYPE,
                              v_text all_source.text%TYPE);
  TYPE t_source IS TABLE OF t_rec_source;
  v_source t_source := t_source();

BEGIN

  --Buffer sin límite para salida de datos
  dbms_output.enable(buffer_size => NULL);

  --Salida de datos generales y cabecera
  SELECT 'El programa (' || LOWER(object_type) || ') ' || object_name || ' fue creado en: ' || TO_CHAR(created, 'DD/MM/YYYY HH24:MI:SS') || CHR(10) || 
         'Modificado por última vez: ' || TO_CHAR(TO_DATE(TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS'), 'DD/MM/YYYY HH24:MI:SS') || CHR(10) || 
         'Su estado es: ' || status
    INTO v_info
    FROM dba_objects
   WHERE object_name = v_object
     AND owner = v_owner;

  dbms_output.put_line('******** Datos generales ********' || CHR(10));
  dbms_output.put_line(v_info || CHR(10));
  dbms_output.put_line('******** Resultados en programa ' || v_object || ' buscando por la etiqueta ' || v_label || ' ********' || CHR(10));
  dbms_output.put_line('Nºlínea' || CHR(9) || CHR(9) || 'Código' || CHR(10));

  FOR r_changes IN cur_changes LOOP
  
    --Separar los números de línea primera y última de las ocurrencias con el texto buscado
    IF MOD(r_changes.rownum, 2) ^= 0 THEN
      v_firstline := r_changes.line;
    ELSE
      v_lastline := r_changes.line;
    END IF;
  
    IF v_firstline > 0 AND v_lastline > v_firstline THEN
    
      --Colección tabla con el código fuente entre ocurrencias con texto en etiqueta consecutivas
      SELECT line, REPLACE(text, CHR(10), CHR(32)) 
      BULK COLLECT INTO v_source
        FROM all_source s
       WHERE s.owner = v_owner
         AND UPPER(s.name) = UPPER(v_object)
         AND line BETWEEN v_firstline AND v_lastline;
    
      --Salida de datos
      FOR j IN v_source.FIRST .. v_source.LAST LOOP
        dbms_output.put_line(v_source(j).v_line || CHR(9) || v_source(j).v_text);
      END LOOP;
      dbms_output.put_line(CHR(10));
    END IF;
  
  END LOOP;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    dbms_output.put_line('ERROR Programa ' || v_object || ' inexistente o sin resultados por búsqueda en etiquetas');
  WHEN OTHERS THEN
    dbms_output.put_line(SQLERRM);
  
END;
/
