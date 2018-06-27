/******************** METADATA ********************/
--Tablas del esquema COND_ADMIN y su descripción
SELECT t.table_name, c.comments
  FROM all_tables t, all_tab_comments c
 WHERE t.table_name = c.table_name
   AND t.owner = 'COND_ADMIN'
 ORDER BY 1;

--Campos de una tabla dada y su descripción
SELECT c.*
  FROM all_col_comments c
 WHERE c.owner = 'COND_ADMIN'
   AND c.table_name = 'TB_ANOTACION_EXT' --Nombre tabla
 ORDER BY 2, 3;

--Integridad referencial de una tabla dada: muestra las PK y FK
SELECT tabla_origen,
       nombre_restriccion,
       columna,
       tabla_referenciada,
       columna_referenciada,
       usuario
  FROM ((SELECT ac.table_name        tabla_origen,
                ac.constraint_name   nombre_restriccion,
                acc.column_name      columna,
                ac.r_constraint_name,
                ac.owner             usuario
           FROM all_constraints ac
          INNER JOIN all_cons_columns acc
             ON ac.owner = acc.owner
            AND ac.constraint_name = acc.constraint_name
          WHERE ac.constraint_type = 'R') a INNER JOIN
        (SELECT acc.table_name     tabla_referenciada,
                ac.constraint_name,
                column_name        columna_referenciada,
                ac.owner           usuario2
           FROM all_cons_columns acc
          INNER JOIN all_constraints ac
             ON ac.owner = acc.owner
            AND ac.constraint_name = acc.constraint_name
          WHERE ac.constraint_type = 'P') b ON
        a.r_constraint_name = b.constraint_name AND a.usuario = b.usuario2)
 WHERE tabla_origen = 'TB_CONDUCTOR' --Nombre tabla
 ORDER BY 6, 1, 2;
 
--Objetos sobre los que tiene permisos el usuario actual (logado)
SELECT table_name  "Nombre objeto",
       object_type "Tipo objeto",
       owner       "Propietario objeto",
       grantee     "Rol/usuario actual",
       privilege   "Sentencia permitida"
  FROM sys.all_tab_privs, all_objects
 WHERE object_name = table_name
   AND grantee IN (SELECT granted_role FROM user_role_privs)
 ORDER BY 2, 1, 5; 

/******************** REGISTRO DE PENADOS ********************/
--Penas de titular a partir de DOI
SELECT p.doi,
       p.id_persona,
       p.nombre,
       p.primer_apellido,
       p.segundo_apellido,
       p.cod_pais,
       TO_CHAR(p.fecha_nacimiento, 'DD/MM/YYYY'),
       sp.*
  FROM tb_persona p, tb_siraj_pena sp
 WHERE doi = '33925587N' --DOI de titular
   AND sp.cdociden LIKE '%' || p.doi || '%';
   
--Búsqueda de ejecutoria a partir de DOI
SELECT p.doi,
       p.nombre,
       p.primer_apellido,
       p.segundo_apellido,
       TO_CHAR(p.fecha_nacimiento, 'DD/MM/YYYY') fecha_nacimiento,
       TO_CHAR(TO_DATE(fechauto, 'YYYYMMDD'), 'DD/MM/YYYY') fechauto,
       TO_CHAR(TO_DATE(finipena, 'YYYYMMDD'), 'DD/MM/YYYY') finipena,
       sp.ndurapena,
       TO_CHAR(TO_DATE(ffinpena, 'YYYYMMDD'), 'DD/MM/YYYY') ffinpena,
       CASE canotdgt
         WHEN 'ST' THEN 'Suspensión Temporal'
         WHEN 'PV' THEN 'Pérdida de Vigencia'
         WHEN 'IT' THEN 'Intervención'
         WHEN 'SI' THEN 'Solicitud de Información'
         ELSE canotdgt
       END canotdgt
  FROM tb_persona p, tb_siraj_pena sp
 WHERE doi = '39450933E' --DOI de titular
   AND sp.cdociden LIKE '%' || p.doi || '%'
   AND sp.nejecutor LIKE '%359' --Nº de ejecutoria
   AND sp.anyoejec = 2017 --Año de ejecutoria
   AND cestadgt = 1; --Estado batch procesado   

/******************** INFORMES Y CONSULTAS U.E. (RESPER) ********************/   
--Consulta petición RESPER   
SELECT tipo "Tipo de mensaje",
       idsdln "WorkflowId",
       UPPER(txnombre || ' ' || txapellidos) "Nombre de titular",
       DECODE(codisexo, 'M', 'Hombre', 'F', 'Mujer', codisexo) "Género",
       dlugnaci "Lugar de nacimiento",
       TO_CHAR(TO_DATE(fecenvio, 'YYYYMMDD'), 'DD/MM/YYYY') "Fecha de envío",
       txautore "Autoridad emisora",
       DECODE(xestadop, '0', 'Pendiente', '1', 'Finalizado', 'A', 'Erroneo', xestadop) "Estado de peticion",
       DECODE(xestadop, '0', 'Pendiente envío de consulta', '1', 'Pendiente de respuesta', '2', 'Recibido', xestadop) "Estado de peticion de detalle",
       destadop "Descripción estado"
  FROM (SELECT 'Mensaje SDLN request' tipo, idsdln, txnombre, txapellidos, codisexo, dlugnaci, fecenvio, NULL txautore, xestadop, NULL xestadod, destadop, NULL numadmin
          FROM tb_conue_sdln_p
        UNION ALL
        SELECT 'Mensaje SDLN response' tipo, idsdln, txnombre, txapellidos, codisexo, dlugnaci, fecenvio, txautore, NULL xestadop, xestadod estado, destadop, numadmin
          FROM tb_conue_sdln_r)
 WHERE idsdln = '14512c38-3818-4745-9eb8-9a7156fb2bc8' --ID de worklow
--OR UPPER(txnombre) LIKE UPPER('%%') --Nombre titular
--OR UPPER(txapellidos) LIKE UPPER('%%') --Apellido(s) titular
--OR numadmin LIKE '%%'; --Nº administrativo de licencia U.E.