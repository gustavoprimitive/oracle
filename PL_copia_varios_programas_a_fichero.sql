--Genera varios ficheros, dentro de un directorio del servidor Oracle, con el código fuente de los programas PL/SQL almacenados que se indiquen.
--Gustavo Tejerina


DECLARE

  TYPE typ_program IS VARRAY(50) OF all_source.name%TYPE;
  v_program   typ_program := typ_program('PM_NOTIF_CANC_CLIENTE_VF',
                                         'VF_GESTION_SMS_MAIL'); --Nombre de objectos PL/SQL a copiar
  v_dir       VARCHAR2(500) := '/home/mqm/neoris/validasql'; --Ruta de servidor para el directorio
  v_dir_nom	  all_directories.directory_name%TYPE;
  v_fichero   utl_file.file_type;
  v_file_name VARCHAR2(50);
  v_where     VARCHAR2(500);
  v_query     VARCHAR2(500);
  TYPE t_out IS REF CURSOR;
  cur_out t_out;
  v_line  all_source.text%TYPE;

BEGIN

  v_dir_nom := dbms_random.string('U', 10);

  --Alta de directorio
  EXECUTE IMMEDIATE 'CREATE DIRECTORY ' || v_dir_nom || ' AS ' || '''' || v_dir || '''';
  EXECUTE IMMEDIATE 'GRANT READ, WRITE ON DIRECTORY ' || v_dir_nom || ' TO public';

  FOR i IN v_program.FIRST .. v_program.LAST LOOP
  
    --Construcción de consulta para cursor variable
    v_query := 'SELECT text FROM all_source WHERE name = ' || '''' || UPPER(v_program(i)) || '''';
  
    --Construcción de nombre de fichero
    v_file_name := UPPER(v_program(i)) || '.sql';
  
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
  
  END LOOP;

  --Borrado de directorio
  EXECUTE IMMEDIATE 'DROP DIRECTORY ' || v_dir_nom;

EXCEPTION
  WHEN OTHERS THEN
       IF SQLCODE = -955 THEN
         dbms_output.put_line('El nombre para el directorio ya es nombre de un objeto existente');
       ELSE
         dbms_output.put_line(SQLERRM);
       END IF;
END;
/