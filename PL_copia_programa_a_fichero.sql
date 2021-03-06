--Genera un fichero, dentro de un directorio del servidor indicado, con el código fuente de un programa PL/SQL almacenado.
--Gustavo Tejerina

DECLARE

  v_program   all_source.name%TYPE := UPPER('&v_program'); --Nombre de objeto PL/SQL a copiar
  v_dir       VARCHAR2(500) := '&v_dir'; --Ruta de servidor para el directorio
  v_fichero   utl_file.file_type;
  v_file_name VARCHAR2(50);
  v_where     VARCHAR2(500);
  v_query     VARCHAR2(500);
  TYPE t_out IS REF CURSOR;
  cur_out t_out;
  v_line  all_source.text%TYPE;
  v_check NUMBER DEFAULT 0;
  e_excep EXCEPTION;

BEGIN

  --Construcción de consulta para cursor variable
  SELECT COUNT(DISTINCT(name))
    INTO v_check
    FROM all_source
   WHERE name = v_program;

  IF v_check = 0 THEN
    dbms_output.put_line('El nombre ' || v_program || ' no se corresponde con ningún objeto PL/SQL');
    RAISE e_excep;
  ELSE
    v_query := 'SELECT text FROM all_source WHERE name = ' || '''' || v_program || '''';
  END IF;

  --Creación de directorio
  v_dir_nom := dbms_random.string('U', 10);  
  
  SELECT COUNT(1)
    INTO v_check
    FROM all_directories
   WHERE directory_name = v_dir_nom;

  IF v_check = 0 THEN
    EXECUTE IMMEDIATE 'CREATE DIRECTORY '|| v_dir_nom || ' AS ' || '''' || v_dir || '''';
    EXECUTE IMMEDIATE 'GRANT READ, WRITE ON DIRECTORY ' || v_dir_nom ' TO public';
  ELSE
    dbms_output.put_line('El directorio ' || v_dir_nom || ' ya existe');
    RAISE e_excep;
  END IF;

  --Construcción de nombre de fichero
  v_file_name := v_program || '.sql';

  --Apertura de fichero
  v_fichero := utl_file.fopen(v_dir_nom, v_file_name, 'W');

  --Ejecución de query y escritura de resultados
  OPEN cur_out FOR v_query;
  LOOP
    FETCH cur_out INTO v_line;
    EXIT WHEN cur_out%NOTFOUND;
    utl_file.put_line(v_fichero, REPLACE(v_line, CHR(10), ''));
  END LOOP;

  --Cierre de fichero y cursor
  utl_file.fclose(v_fichero);
  CLOSE cur_out;

  --Borrado de directorio
  EXECUTE IMMEDIATE 'DROP DIRECTORY ' || v_dir_nom;

EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(SQLERRM);
  
END;
/
