-- name: collection-mysql-data-types
select concat(char(34), @PKEY, char(34)) as pkey,
  concat(char(34), @DMA_SOURCE_ID, char(34)) as dma_source_id,
  concat(char(34), @DMA_MANUAL_ID, char(34)) as dma_manual_id,
  concat(char(34), src.table_catalog, char(34)) as table_catalog,
  concat(char(34), src.table_schema, char(34)) as table_schema,
  concat(char(34), src.table_name, char(34)) as table_name,
  concat(char(34), src.data_type, char(34)) as data_type,
  src.data_type_count as data_type_count
from (
    select i.table_catalog as table_catalog,
      i.TABLE_SCHEMA as table_schema,
      i.TABLE_NAME as table_name,
      i.DATA_TYPE as data_type,
      count(1) as data_type_count
    from information_schema.columns i
    where i.TABLE_SCHEMA not in (
        'mysql',
        'information_schema',
        'performance_schema',
        'sys'
      )
    group by i.table_catalog,
      i.TABLE_SCHEMA,
      i.TABLE_NAME,
      i.DATA_TYPE
  ) src;

-- name: collection-mysql-the-other-query
select concat(char(34), @PKEY, char(34)) as pkey,
  concat(char(34), @DMA_SOURCE_ID, char(34)) as dma_source_id,
  concat(char(34), @DMA_MANUAL_ID, char(34)) as dma_manual_id,
  concat(char(34), src.table_catalog, char(34)) as table_catalog,
  concat(char(34), src.table_schema, char(34)) as table_schema,
  concat(char(34), src.table_name, char(34)) as table_name,
  concat(char(34), src.data_type, char(34)) as data_type,
  src.data_type_count as data_type_count
from (
    select i.table_catalog as table_catalog,
      i.TABLE_SCHEMA as table_schema,
      i.TABLE_NAME as table_name,
      i.DATA_TYPE as data_type,
      count(1) as data_type_count
    from information_schema.columns i
    where i.TABLE_SCHEMA not in (
        'mysql',
        'information_schema',
        'performance_schema',
        'sys'
      )
    group by i.table_catalog,
      i.TABLE_SCHEMA,
      i.TABLE_NAME,
      i.DATA_TYPE
  ) src;

-- name: extended-collection-mysql-table-details
select
  /*+ MAX_EXECUTION_TIME(5000) */
  concat(char(34), @PKEY, char(34)) as pkey,
  concat(char(34), @DMA_SOURCE_ID, char(34)) as dma_source_id,
  concat(char(34), @DMA_MANUAL_ID, char(34)) as dma_manual_id,
  concat(char(34), table_schema, char(34)) as table_schema,
  concat(char(34), table_name, char(34)) as table_name,
  concat(char(34), table_engine, char(34)) as table_engine,
  table_rows as table_rows,
  data_length as data_length,
  index_length as index_length,
  concat(char(34), is_compressed, char(34)) as is_compressed,
  concat(char(34), is_partitioned, char(34)) as is_partitioned,
  partition_count as partition_count,
  index_count as index_count,
  fulltext_index_count as fulltext_index_count
from (
    select t.table_schema as table_schema,
      t.table_name as table_name,
      t.table_rows as table_rows,
      t.DATA_LENGTH as DATA_LENGTH,
      t.INDEX_LENGTH as INDEX_LENGTH,
      t.DATA_LENGTH + t.INDEX_LENGTH as total_length,
      t.ROW_FORMAT as row_format,
      t.TABLE_TYPE as table_type,
      t.ENGINE as table_engine,
      if(pks.table_name is not null, 1, 0) as has_primary_key,
      if(t.ROW_FORMAT = 'COMPRESSED', 1, 0) as is_compressed,
      if(pt.PARTITION_METHOD is not null, 1, 0) as is_partitioned,
      COALESCE(pt.PARTITION_COUNT, 0) as partition_count,
      COALESCE(idx.index_count, 0) as index_count,
      COALESCE(idx.fulltext_index_count, 0) as fulltext_index_count,
      COALESCE(idx.spatial_index_count, 0) as spatial_index_count
    from information_schema.TABLES t
      left join (
        select TABLE_SCHEMA,
          TABLE_NAME,
          PARTITION_METHOD,
          SUBPARTITION_METHOD,
          count(1) as PARTITION_COUNT
        from information_schema.PARTITIONS
        where table_schema not in (
            'mysql',
            'information_schema',
            'performance_schema',
            'sys'
          )
        group by TABLE_SCHEMA,
          TABLE_NAME,
          PARTITION_METHOD,
          SUBPARTITION_METHOD
      ) pt on (
        t.table_schema = pt.table_schema
        and t.TABLE_NAME = pt.TABLE_NAME
      )
      left join (
        select table_schema,
          TABLE_NAME
        from information_schema.statistics
        where table_schema not in (
            'mysql',
            'information_schema',
            'performance_schema',
            'sys'
          )
        group by table_schema,
          TABLE_NAME,
          index_name
        having SUM(
            if(
              non_unique = 0
              and NULLABLE != 'YES',
              1,
              0
            )
          ) = count(*)
      ) pks on (
        t.table_schema = pks.table_schema
        and t.TABLE_NAME = pks.TABLE_NAME
      )
      left join (
        select s.table_schema,
          s.table_name,
          count(1) as index_count,
          sum(
            if(s.INDEX_TYPE = 'FULLTEXT', 1, 0)
          ) as fulltext_index_count,
          sum(if(s.INDEX_TYPE = 'SPATIAL', 1, 0)) as spatial_index_count
        from information_schema.STATISTICS s
        where s.table_schema not in (
            'mysql',
            'information_schema',
            'performance_schema',
            'sys'
          )
        group by s.table_schema,
          s.table_name
      ) idx on (
        t.table_schema = idx.table_schema
        and t.TABLE_NAME = idx.TABLE_NAME
      )
    where t.table_schema not in (
        'mysql',
        'information_schema',
        'performance_schema',
        'sys'
      )
  ) user_tables;

-- name: collection-mysql-config
select distinct concat(char(34), @pkey, char(34)) as pkey,
  concat(char(34), @dma_source_id, char(34)) as dma_source_id,
  concat(char(34), @dma_manual_id, char(34)) as dma_manual_id,
  concat(char(34), src.variable_category, char(34)) as variable_category,
  concat(char(34), src.variable_name, char(34)) as variable_name,
  concat(char(34), src.variable_value, char(34)) as variable_value
from (
    select 'ALL_VARIABLES' as variable_category,
      variable_name,
      variable_value
    from (
        select variable_name,
          variable_value
        from (
            select upper(variable_name) as variable_name,
              variable_value
            from performance_schema.global_variables
            union
            select upper(variable_name),
              variable_value
            from performance_schema.session_variables
            where variable_name not in (
                select variable_name
                from performance_schema.global_variables
              )
          ) a
        where a.variable_name not in ('FT_BOOLEAN_SYNTAX')
          and a.variable_name not like '%PUBLIC_KEY'
          and a.variable_name not like '%PRIVATE_KEY'
      ) all_vars
    union
    select 'GLOBAL_STATUS' as variable_category,
      variable_name,
      variable_value
    from (
        select upper(variable_name) as variable_name,
          variable_value
        from performance_schema.global_status a
        where a.variable_name not in ('FT_BOOLEAN_SYNTAX')
          and a.variable_name not like '%PUBLIC_KEY'
          and a.variable_name not like '%PRIVATE_KEY'
      ) global_status
    union
    select 'CALCULATED_METRIC' as variable_category,
      variable_name,
      variable_value
    from (
        select 'IS_MARIADB' as variable_name,
          if(upper(gv.variable_value) like '%MARIADB%', 1, 0) as variable_value
        from performance_schema.global_variables gv
        where gv.variable_name = 'VERSION'
        union
        select 'TABLE_SIZE' as variable_name,
          total_data_size_bytes as variable_value
        from (
            select table_schema,
              sum(data_length) as total_data_size_bytes
            from (
                select t.table_schema as table_schema,
                  t.table_name as table_name,
                  t.table_rows as table_rows,
                  t.DATA_LENGTH as DATA_LENGTH,
                  t.INDEX_LENGTH as INDEX_LENGTH,
                  t.DATA_LENGTH + t.INDEX_LENGTH as total_length,
                  t.ROW_FORMAT as row_format,
                  t.TABLE_TYPE as table_type,
                  t.ENGINE as table_engine,
                  if(pks.table_name is not null, 1, 0) as has_primary_key
                from information_schema.TABLES t
                  left join (
                    select table_schema,
                      TABLE_NAME
                    from information_schema.statistics
                    where table_schema not in (
                        'mysql',
                        'information_schema',
                        'performance_schema',
                        'sys'
                      )
                    group by table_schema,
                      TABLE_NAME,
                      index_name
                    having SUM(
                        if(
                          non_unique = 0
                          and NULLABLE != 'YES',
                          1,
                          0
                        )
                      ) = count(*)
                  ) pks on (
                    t.table_schema = pks.table_schema
                    and t.TABLE_NAME = pks.TABLE_NAME
                  )
                where t.table_schema not in (
                    'mysql',
                    'information_schema',
                    'performance_schema',
                    'sys'
                  )
              ) user_tables
            group by user_tables.table_schema
          ) data_summary
        union
        select 'TABLE_NO_INNODB_SIZE' as variable_name,
          non_innodb_data_size_bytes as variable_value
        from (
            select table_schema,
              sum(
                if(upper(table_engine) != 'INNODB', data_length, 0)
              ) as non_innodb_data_size_bytes
            from (
                select t.table_schema as table_schema,
                  t.table_name as table_name,
                  t.table_rows as table_rows,
                  t.DATA_LENGTH as DATA_LENGTH,
                  t.INDEX_LENGTH as INDEX_LENGTH,
                  t.DATA_LENGTH + t.INDEX_LENGTH as total_length,
                  t.ROW_FORMAT as row_format,
                  t.TABLE_TYPE as table_type,
                  t.ENGINE as table_engine,
                  if(pks.table_name is not null, 1, 0) as has_primary_key
                from information_schema.TABLES t
                  left join (
                    select table_schema,
                      TABLE_NAME
                    from information_schema.statistics
                    where table_schema not in (
                        'mysql',
                        'information_schema',
                        'performance_schema',
                        'sys'
                      )
                    group by table_schema,
                      TABLE_NAME,
                      index_name
                    having SUM(
                        if(
                          non_unique = 0
                          and NULLABLE != 'YES',
                          1,
                          0
                        )
                      ) = count(*)
                  ) pks on (
                    t.table_schema = pks.table_schema
                    and t.TABLE_NAME = pks.TABLE_NAME
                  )
                where t.table_schema not in (
                    'mysql',
                    'information_schema',
                    'performance_schema',
                    'sys'
                  )
              ) user_tables
            group by user_tables.table_schema
          ) data_summary
        union
        select 'TABLE_INNODB_SIZE' as variable_name,
          innodb_data_size_bytes as variable_value
        from (
            select table_schema,
              sum(
                if(upper(table_engine) = 'INNODB', data_length, 0)
              ) as innodb_data_size_bytes
            from (
                select t.table_schema as table_schema,
                  t.table_name as table_name,
                  t.table_rows as table_rows,
                  t.DATA_LENGTH as DATA_LENGTH,
                  t.INDEX_LENGTH as INDEX_LENGTH,
                  t.DATA_LENGTH + t.INDEX_LENGTH as total_length,
                  t.ROW_FORMAT as row_format,
                  t.TABLE_TYPE as table_type,
                  t.ENGINE as table_engine,
                  if(pks.table_name is not null, 1, 0) as has_primary_key
                from information_schema.TABLES t
                  left join (
                    select table_schema,
                      TABLE_NAME
                    from information_schema.statistics
                    where table_schema not in (
                        'mysql',
                        'information_schema',
                        'performance_schema',
                        'sys'
                      )
                    group by table_schema,
                      TABLE_NAME,
                      index_name
                    having SUM(
                        if(
                          non_unique = 0
                          and NULLABLE != 'YES',
                          1,
                          0
                        )
                      ) = count(*)
                  ) pks on (
                    t.table_schema = pks.table_schema
                    and t.TABLE_NAME = pks.TABLE_NAME
                  )
                where t.table_schema not in (
                    'mysql',
                    'information_schema',
                    'performance_schema',
                    'sys'
                  )
              ) user_tables
            group by user_tables.table_schema
          ) data_summary
        union
        select 'TABLE_COUNT' as variable_name,
          total_table_count as variable_value
        from (
            select table_schema,
              count(table_name) as total_table_count
            from (
                select t.table_schema as table_schema,
                  t.table_name as table_name,
                  t.table_rows as table_rows,
                  t.DATA_LENGTH as DATA_LENGTH,
                  t.INDEX_LENGTH as INDEX_LENGTH,
                  t.DATA_LENGTH + t.INDEX_LENGTH as total_length,
                  t.ROW_FORMAT as row_format,
                  t.TABLE_TYPE as table_type,
                  t.ENGINE as table_engine,
                  if(pks.table_name is not null, 1, 0) as has_primary_key
                from information_schema.TABLES t
                  left join (
                    select table_schema,
                      TABLE_NAME
                    from information_schema.statistics
                    where table_schema not in (
                        'mysql',
                        'information_schema',
                        'performance_schema',
                        'sys'
                      )
                    group by table_schema,
                      TABLE_NAME,
                      index_name
                    having SUM(
                        if(
                          non_unique = 0
                          and NULLABLE != 'YES',
                          1,
                          0
                        )
                      ) = count(*)
                  ) pks on (
                    t.table_schema = pks.table_schema
                    and t.TABLE_NAME = pks.TABLE_NAME
                  )
                where t.table_schema not in (
                    'mysql',
                    'information_schema',
                    'performance_schema',
                    'sys'
                  )
              ) user_tables
            group by user_tables.table_schema
          ) data_summary
        union
        select 'TABLE_NO_INNODB_COUNT' as variable_name,
          non_innodb_table_count as variable_value
        from (
            select table_schema,
              sum(if(upper(table_engine) != 'INNODB', 1, 0)) as non_innodb_table_count
            from (
                select t.table_schema as table_schema,
                  t.table_name as table_name,
                  t.table_rows as table_rows,
                  t.DATA_LENGTH as DATA_LENGTH,
                  t.INDEX_LENGTH as INDEX_LENGTH,
                  t.DATA_LENGTH + t.INDEX_LENGTH as total_length,
                  t.ROW_FORMAT as row_format,
                  t.TABLE_TYPE as table_type,
                  t.ENGINE as table_engine,
                  if(pks.table_name is not null, 1, 0) as has_primary_key
                from information_schema.TABLES t
                  left join (
                    select table_schema,
                      TABLE_NAME
                    from information_schema.statistics
                    where table_schema not in (
                        'mysql',
                        'information_schema',
                        'performance_schema',
                        'sys'
                      )
                    group by table_schema,
                      TABLE_NAME,
                      index_name
                    having SUM(
                        if(
                          non_unique = 0
                          and NULLABLE != 'YES',
                          1,
                          0
                        )
                      ) = count(*)
                  ) pks on (
                    t.table_schema = pks.table_schema
                    and t.TABLE_NAME = pks.TABLE_NAME
                  )
                where t.table_schema not in (
                    'mysql',
                    'information_schema',
                    'performance_schema',
                    'sys'
                  )
              ) user_tables
            group by user_tables.table_schema
          ) data_summary
        union
        select 'TABLE_INNODB_COUNT' as variable_name,
          innodb_table_count as variable_value
        from (
            select table_schema,
              sum(if(upper(table_engine) = 'INNODB', 1, 0)) as innodb_table_count
            from (
                select t.table_schema as table_schema,
                  t.table_name as table_name,
                  t.table_rows as table_rows,
                  t.DATA_LENGTH as DATA_LENGTH,
                  t.INDEX_LENGTH as INDEX_LENGTH,
                  t.DATA_LENGTH + t.INDEX_LENGTH as total_length,
                  t.ROW_FORMAT as row_format,
                  t.TABLE_TYPE as table_type,
                  t.ENGINE as table_engine,
                  if(pks.table_name is not null, 1, 0) as has_primary_key
                from information_schema.TABLES t
                  left join (
                    select table_schema,
                      TABLE_NAME
                    from information_schema.statistics
                    where table_schema not in (
                        'mysql',
                        'information_schema',
                        'performance_schema',
                        'sys'
                      )
                    group by table_schema,
                      TABLE_NAME,
                      index_name
                    having SUM(
                        if(
                          non_unique = 0
                          and NULLABLE != 'YES',
                          1,
                          0
                        )
                      ) = count(*)
                  ) pks on (
                    t.table_schema = pks.table_schema
                    and t.TABLE_NAME = pks.TABLE_NAME
                  )
                where t.table_schema not in (
                    'mysql',
                    'information_schema',
                    'performance_schema',
                    'sys'
                  )
              ) user_tables
            group by user_tables.table_schema
          ) data_summary
        union
        select 'TABLE_NO_PK_COUNT' as variable_name,
          total_tables_without_primary_key as variable_value
        from (
            select table_schema,
              sum(if(has_primary_key = 0, 1, 0)) as total_tables_without_primary_key
            from (
                select t.table_schema as table_schema,
                  t.table_name as table_name,
                  t.table_rows as table_rows,
                  t.DATA_LENGTH as DATA_LENGTH,
                  t.INDEX_LENGTH as INDEX_LENGTH,
                  t.DATA_LENGTH + t.INDEX_LENGTH as total_length,
                  t.ROW_FORMAT as row_format,
                  t.TABLE_TYPE as table_type,
                  t.ENGINE as table_engine,
                  if(pks.table_name is not null, 1, 0) as has_primary_key
                from information_schema.TABLES t
                  left join (
                    select table_schema,
                      TABLE_NAME
                    from information_schema.statistics
                    where table_schema not in (
                        'mysql',
                        'information_schema',
                        'performance_schema',
                        'sys'
                      )
                    group by table_schema,
                      TABLE_NAME,
                      index_name
                    having SUM(
                        if(
                          non_unique = 0
                          and NULLABLE != 'YES',
                          1,
                          0
                        )
                      ) = count(*)
                  ) pks on (
                    t.table_schema = pks.table_schema
                    and t.TABLE_NAME = pks.TABLE_NAME
                  )
                where t.table_schema not in (
                    'mysql',
                    'information_schema',
                    'performance_schema',
                    'sys'
                  )
              ) user_tables
            group by user_tables.table_schema
          ) data_summary
        union
        select 'MYSQLX_PLUGIN' as variable_name,
          p.mysqlx_plugin_enabled as variable_value
        from (
            select if(agg.mysqlx_plugin > 0, 1, 0) as mysqlx_plugin_enabled
            from (
                select sum(
                    if(
                      upper(p.plugin_name) like '%MYSQLX%',
                      1,
                      0
                    )
                  ) as mysqlx_plugin
                from (
                    select p.plugin_name as plugin_name,
                      p.PLUGIN_STATUS
                    from information_schema.PLUGINS p
                  ) p
              ) agg
          ) p
        union
        select 'MEMCACHED_PLUGIN' as variable_name,
          p.memcached_plugin_enabled as variable_value
        from (
            select if(agg.memcached_plugin > 0, 1, 0) as memcached_plugin_enabled
            from (
                select sum(
                    if(
                      upper(p.plugin_name) like '%MEMCACHED%',
                      1,
                      0
                    )
                  ) as memcached_plugin
                from (
                    select p.plugin_name as plugin_name,
                      p.PLUGIN_STATUS
                    from information_schema.PLUGINS p
                  ) p
              ) agg
          ) p
        union
        select 'CLONE_PLUGIN' as variable_name,
          p.clone_plugin_enabled as variable_value
        from (
            select if(agg.clone_plugin > 0, 1, 0) as clone_plugin_enabled
            from (
                select sum(
                    if(
                      upper(p.plugin_name) like '%CLONE%',
                      1,
                      0
                    )
                  ) as clone_plugin
                from (
                    select p.plugin_name as plugin_name,
                      p.PLUGIN_STATUS
                    from information_schema.PLUGINS p
                  ) p
              ) agg
          ) p
        union
        select 'KEYRING_PLUGIN' as variable_name,
          p.keyring_plugin_enabled as variable_value
        from (
            select if(agg.keyring_plugin > 0, 1, 0) as keyring_plugin_enabled
            from (
                select sum(
                    if(
                      upper(p.plugin_name) like '%KEYRING%',
                      1,
                      0
                    )
                  ) as keyring_plugin
                from (
                    select p.plugin_name as plugin_name,
                      p.PLUGIN_STATUS
                    from information_schema.PLUGINS p
                  ) p
              ) agg
          ) p
        union
        select 'VALIDATE_PASSWORD_PLUGIN' as variable_name,
          p.validate_password_plugin_enabled as variable_value
        from (
            select if(agg.validate_password_plugin > 0, 1, 0) as validate_password_plugin_enabled
            from (
                select sum(
                    if(
                      upper(p.plugin_name) like '%VALIDATE_PASSWORD%',
                      1,
                      0
                    )
                  ) as validate_password_plugin
                from (
                    select p.plugin_name as plugin_name,
                      p.PLUGIN_STATUS
                    from information_schema.PLUGINS p
                  ) p
              ) agg
          ) p
        union
        select 'THREAD_POOL_PLUGIN' as variable_name,
          p.thread_pool_plugin_enabled as variable_value
        from (
            select if(agg.thread_pool_plugin > 0, 1, 0) as thread_pool_plugin_enabled
            from (
                select sum(
                    if(
                      upper(p.plugin_name) like '%THREAD_POOL%',
                      1,
                      0
                    )
                  ) as thread_pool_plugin
                from (
                    select p.plugin_name as plugin_name,
                      p.PLUGIN_STATUS
                    from information_schema.PLUGINS p
                  ) p
              ) agg
          ) p
        union
        select 'FIREWALL_PLUGIN' as variable_name,
          p.firewall_plugin_enabled as variable_value
        from (
            select if(agg.firewall_plugin > 0, 1, 0) as firewall_plugin_enabled
            from (
                select sum(
                    if(
                      upper(p.plugin_name) like '%FIREWALL%',
                      1,
                      0
                    )
                  ) as firewall_plugin
                from (
                    select p.plugin_name as plugin_name,
                      p.PLUGIN_STATUS
                    from information_schema.PLUGINS p
                  ) p
              ) agg
          ) p
        union
        select 'VERSION_NUM' as variable_name,
          if(
            version() rlike '^[0-9]+\.[0-9]+\.[0-9]+$' = 1,
            version(),
            SUBSTRING_INDEX(VERSION(), '.', 2) || '.0'
          ) as variable_value
      ) calculated_metrics
  ) src;
