--Inserción de registros de tabla origen a destino por bloques, mediante INSERT con subquery, y controlando el nº de registros del bloque
--Se confirma la transacción tras la inserción de cada bloque
--Gustavo Tejerina

DECLARE

  --Número de registros de cada confirmación de transacción
  c_rows_trans CONSTANT NUMBER := 500;
  --Contadores
  v_total_count NUMBER DEFAULT 0;
  v_ins_count   NUMBER DEFAULT 0;

  --Procedimiento local de output de traza
  PROCEDURE p_log(i NUMBER, v_ins_count NUMBER) AS
  BEGIN
    dbms_output.put_line(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || chr(9) || 'Inserción #' || i || ' - ' || v_ins_count || ' registros totales insertados');
  END;

BEGIN

  dbms_output.enable(NULL);

  --Nº total de registros
  SELECT COUNT(*) INTO v_total_count FROM employees;

  --Inserción de bloques registros hasta llegar al total
  FOR i IN 1 .. (v_total_count / c_rows_trans) + 1 LOOP
  
    INSERT /*+ APPEND */ INTO employees_final
      SELECT employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id
        FROM (SELECT e.*, ROWNUM n_row FROM employees e)
       WHERE n_row BETWEEN v_ins_count + 1 AND v_ins_count + c_rows_trans;
  
    --Contador de total insertados
    v_ins_count := v_ins_count + c_rows_trans;
  
    --Traza
    IF SQL%ROWCOUNT > 0 THEN
      p_log(i, v_ins_count);
    END IF;
  
    COMMIT;
  
  END LOOP;

END;
/
