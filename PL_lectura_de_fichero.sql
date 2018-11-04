--Lectura de fichero a partir de su nombre y del nombre del directorio de Oracle que lo contiene.
--Gustavo Tejerina

SET SERVEROUTPUT ON

DECLARE

  v_dir       all_directories.directory_name%TYPE := upper('&v_dir');
  v_file_name VARCHAR2(500) := '&v_file_name';
  v_file      utl_file.file_type;
  v_check_dir NUMBER DEFAULT 0;
  e_excep_dir EXCEPTION;
  v_out VARCHAR2(32767);

BEGIN

  --Comprobación de existencia de directorio
  SELECT COUNT(1)
    INTO v_check_dir
    FROM all_directories
   WHERE directory_name = v_dir;

  --Si no existe el directorio se termina la ejecución
  IF v_check_dir = 0 THEN
    RAISE e_excep_dir;
  --Si existe el directorio se intenta la apertura del fichero
  ELSE
    BEGIN
      v_file := utl_file.fopen(v_dir, v_file_name, 'R');
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
  
    --Se lee el contenido del fichero abierto  
    LOOP
      BEGIN
        utl_file.get_line(v_file, v_out);
        dbms_output.put_line(v_out);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          utl_file.fclose(v_file);
          EXIT;
      END;
    END LOOP;
  
  END IF;

EXCEPTION
  WHEN e_excep_dir THEN
    dbms_output.put_line('ERROR. No se encuentra el directorio ' || v_dir);
  WHEN OTHERS THEN
    IF SQLCODE = -29283 THEN
      dbms_output.put_line('ERROR. No se puede leer el fichero ' || v_file_name);
    ELSE
      dbms_output.put_line(SQLERRM);
    END IF;
END;
/
