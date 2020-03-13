--Borrado de objetos de un esquema
--Gustavo Tejerina

DECLARE 
  v_owner all_objects.owner%TYPE := UPPER('&v_owner');
  v_count NUMBER := 0;
  CURSOR c_ddl(v_owner all_objects.owner%TYPE) IS SELECT 'DROP TABLE ' || owner || '.' || table_name || ' CASCADE CONSTRAINTS PURGE' AS ddl
                                                  FROM all_tables
                                                  WHERE owner = v_owner
                                                  UNION ALL
                                                  SELECT 'DROP ' || object_type || ' ' || owner || '.' || object_name AS ddl
                                                  FROM all_objects
                                                  WHERE owner = v_owner
                                                  ORDER BY 1;
BEGIN
FOR r IN c_ddl(v_owner) LOOP 
  dbms_output.put_line('- ' || r.ddl);
  BEGIN 
    EXECUTE IMMEDIATE r.ddl;
  EXCEPTION 
    WHEN others THEN 
      dbms_output.put_line(CHR(9) || 'ERROR: ' || SQLERRM);
  END;
END LOOP;
SELECT COUNT(1) INTO v_count FROM all_objects WHERE owner = v_owner;
dbms_output.put_line(CHR(10) || 'Existe(n) ' || v_count || ' objeto(s) en el esquema ' || v_owner); 
END;
/