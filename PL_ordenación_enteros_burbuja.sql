--Procedimiento que genera una colección de enteros aleatorios que posteriormente ordena de menor a mayor.
--Recibe como parámetro el número de enteros que tendrá la colección.
--Gustavo Tejerina

CREATE PROCEDURE p_order_random_integer(v_num_values NUMBER) IS
  
  --Colección de enteros
  TYPE t_col_random IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_col_random t_col_random;
  --Variable auxiliar para intercambio de valores
  v_aux NUMBER DEFAULT 0;

BEGIN

  --Asignación de valores aleatorios a la colección
  FOR i IN 1 .. v_num_values LOOP
    v_col_random(i) := sys.dbms_random.random;
  END LOOP;

  --Ordenación
  FOR i IN v_col_random.first + 1 .. v_col_random.last LOOP
    FOR j IN v_col_random.first .. v_col_random.last - 1 LOOP
      --Intercambio
      IF v_col_random(j) > v_col_random(j + 1) THEN
        v_aux := v_col_random(j);
        v_col_random(j) := v_col_random(j + 1);
        v_col_random(j + 1) := v_aux;
      END IF;
    END LOOP;
  END LOOP;

  --Output de enteros ordenados
  FOR i IN v_col_random.first .. v_col_random.last LOOP
    dbms_output.put_line(v_col_random(i));
  END LOOP;

END;
/

--Llamada a procedimiento para que ordene 20 valores aleatorios
BEGIN
p_order_random_integer(20);
END;
/
