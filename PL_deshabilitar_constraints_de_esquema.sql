--Des/habilitado de constraints de un esquema cuyo nombre se solicita en ejecución
--Gustavo Tejerina

DECLARE
  v_owner all_constraints.owner%TYPE := UPPER('&v_owner');
  enable BOOLEAN := true; --true: habilitar, false: deshabilitar
  v_action VARCHAR2(10);
  v_ddl VARCHAR2(500);
  v_status all_constraints.status%TYPE;
  v_count NUMBER DEFAULT 0;
BEGIN
  IF enable THEN
    v_action := 'ENABLE';
    v_status := 'DISABLED';
  ELSE
    v_action := 'DISABLE';
    v_status := 'ENABLED';  
  END IF;
    FOR rec IN (SELECT c.owner, c.table_name, c.constraint_name
                FROM all_constraints c
                WHERE c.status = v_status
                AND c.owner = v_owner
                ORDER BY c.constraint_type DESC) LOOP
      v_ddl := 'alter table "' || rec.owner || '"."' || rec.table_name || '" ' || v_action || ' constraint ' || rec.constraint_name;
      dbms_output.put_line(v_ddl);
      BEGIN
        dbms_utility.exec_ddl_statement(v_ddl);
      EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line(CHR(9) || SQLERRM);
      END;
    END LOOP;
    SELECT COUNT(1) INTO v_count FROM all_constraints WHERE owner =  v_owner AND status = v_status;
    dbms_output.put_line(CHR(10) || 'Existe(n) ' || v_count || ' constraint(s) en estado ' || v_status);
END;
/
