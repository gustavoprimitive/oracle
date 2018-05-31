--Ocupación en MB y % de los tablespaces
SELECT fs.tablespace_name "TABLESPACE",
       (df.totalspace - fs.freespace) "ESPACIO OCUPADO (MB)",
       fs.freespace "ESPACIO LIBRE (MB)",
       df.totalspace "ESPACIO TOTAL (MB)",
       ROUND(100 * ((df.totalspace - fs.freespace) / df.totalspace)) "OCUPACION RESPECTO MAXIMO (%)"
  FROM (SELECT tablespace_name, ROUND(SUM(bytes) / 1024 / 1024) TotalSpace
          FROM dba_data_files
         GROUP BY tablespace_name) df,
       (SELECT tablespace_name, ROUND(SUM(bytes) / 1024 / 1024) FreeSpace
          FROM dba_free_space
         GROUP BY tablespace_name) fs
 WHERE df.tablespace_name = fs.tablespace_name
 ORDER BY 5 DESC;

 
--Ocupación en MB y % de los datafiles de los tablespaces 
SELECT tablespace,
       datafile,
       DECODE("¿ES AUTOEXTEND?", 0, 'No', 'Si') AS "¿ES AUTOEXTEND?",
       "ESPACIO TOTAL (MB)",
       DECODE("ESPACIO LIBRE (MB)", NULL, '(Lleno)', "ESPACIO LIBRE (MB)") AS "ESPACIO LIBRE (MB)",
       DECODE("ESPACIO OCUPADO (MB)", NULL, '(Lleno)', "ESPACIO OCUPADO (MB)") AS "ESPACIO OCUPADO (MB)",
       DECODE("OCUPACION (%)", '%', '100%', "OCUPACION (%)") AS "OCUPACION (%)",
       DECODE("DEFINIDO TAMAÑO MAXIMO (MB)", 0, 'N/A', "DEFINIDO TAMAÑO MAXIMO (MB)") AS "TAMAÑO MAXIMO DEFINIDO (MB)",
       DECODE("OCUPACION RESPECTO MAXIMO (%)", NULL, 'N/A', "OCUPACION RESPECTO MAXIMO (%)") AS "OCUPACION RESPECTO MAXIMO (%)"
  FROM (SELECT dd.tablespace_name "TABLESPACE",
               dd.file_name "DATAFILE",
               MAX(dd.maxbytes) AS "¿ES AUTOEXTEND?",
               MAX(dd.bytes) / 1024 / 1024 AS "ESPACIO TOTAL (MB)",
               SUM(df.bytes) / 1024 / 1024 AS "ESPACIO LIBRE (MB)",
               (MAX(dd.bytes) - SUM(df.bytes)) / 1024 / 1024 AS "ESPACIO OCUPADO (MB)",
               ROUND((MAX(dd.bytes) - SUM(df.bytes)) * 100 / MAX(dd.bytes), 2) || '%' AS "OCUPACION (%)",
               MAX(dd.maxbytes) / 1024 / 1024 AS "DEFINIDO TAMAÑO MAXIMO (MB)",
               DECODE(ROUND((MAX(dd.bytes) - SUM(df.bytes)) * 100 / DECODE(MAX(dd.maxbytes), 0, '', MAX(dd.maxbytes)), 2) || '%', '%', '', ROUND((MAX(dd.bytes) - SUM(df.bytes)) * 100 / DECODE(MAX(dd.maxbytes), 0, '', MAX(dd.maxbytes)), 2) || '%') AS "OCUPACION RESPECTO MAXIMO (%)"
          FROM dba_data_files dd, dba_free_space df
         WHERE dd.tablespace_name = df.tablespace_name(+)
           AND dd.file_id = df.file_id(+)
        --AND UPPER(dd.tablespace_name) = UPPER('PRIME_IM_CASCADE')
         GROUP BY dd.tablespace_name, dd.file_name)
 ORDER BY 1, 2;


--Ocupación en MB de las tablas de un tablespace dado
SELECT segment_name "Tabla", bytes / 1024 / 1024 "Tamaño MB"
  FROM user_segments
 WHERE segment_type LIKE 'TABLE%'
   AND segment_name IN (SELECT table_name
                          FROM all_tables
                         WHERE table_name = user_segments.segment_name
                         --AND UPPER(tablespace_name) = UPPER('HIS_RAW_DATA')
                       )
   AND (bytes / 1024 / 1024) > 1
 ORDER BY 2 DESC;
