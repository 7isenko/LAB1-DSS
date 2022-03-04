create or replace function get_indexes(tbl_name varchar)
    returns table
            (
                i_name name,
                c_name name
            )
as
$$
BEGIN
    return query select i.relname as index_name,
                        a.attname as column_name
                 from pg_class t,
                      pg_class i,
                      pg_index ix,
                      pg_attribute a
                 where t.oid = ix.indrelid
                   and i.oid = ix.indexrelid
                   and a.attrelid = t.oid
                   and a.attnum = ANY (ix.indkey)
                   and t.relkind = 'r'
                   and t.relname = tbl_name::name
                   and t.relfilenode = tbl_name::regclass::oid /* Fixes a ton of other indexes from another students' schemes */

                 order by t.relname,
                          i.relname;
END;
$$ language plpgsql;

create or replace function get_full_info(schema_name varchar, tbl_name varchar)
    returns table
            (
                No                int,
                column_name       name,
                type              varchar,
                cml               int,
                description       varchar,
                index_name        name,
                numeric_precision int,
                numeric_scale     int
            )
as
$$
BEGIN
    return query select info.ordinal_position::int         as No,
                        info.column_name::name,
                        info.udt_name::varchar             as type,
                        info.character_maximum_length::int as cml,
                        pgd.description::varchar,
                        i_name::name                  as index_name,
                        info.numeric_precision::int,
                        info.numeric_scale::int
                 from information_schema.columns as info
                          left join pg_catalog.pg_statio_all_tables st
                                    on (info.table_name = st.relname and info.table_schema = st.schemaname)
                          left join pg_catalog.pg_description pgd
                                    on (pgd.objsubid = info.ordinal_position and pgd.objoid = st.relid)
                          left join get_indexes(table_name) ind on (ind.c_name = info.column_name)
                 where table_schema = schema_name
                   and table_name = tbl_name
                 order by ordinal_position;
END;
$$ language plpgsql;

create or replace function compile_type(type varchar,
                                        cml int,
                                        numeric_precision int,
                                        numeric_scale int) returns varchar as
$$
begin
    if (type = 'varchar') then
        return type || '(' || cml || ')';
    end if;

    if (type = 'numeric') then
        return type || '(' || numeric_precision || ',' || numeric_scale || ')';
    end if;

    return type;
end;
$$ language plpgsql;

create or replace function get_info(schema_name varchar, tbl_name varchar)
    returns table
            (
                No          int,
                column_name name,
                type        varchar,
                description varchar,
                index_name  name
            )
as
$$
BEGIN
    return query select inf.No,
                        inf.column_name,
                        compile_type(inf.type, inf.cml, inf.numeric_precision, inf.numeric_scale),
                        inf.description,
                        inf.index_name
                 from get_full_info(schema_name, tbl_name) as inf;
END;
$$ language plpgsql;


create or replace function get_compact_info(schema_name varchar, tbl_name varchar)
    returns table
            (
                "No."         int,
                "Column name" name,
                "Attributes"  text
            )
as
$$
BEGIN
    return query select inf.No,
                        inf.column_name,
                        concat('Type: ', type, chr(10), 'Commen: ', description, chr(10), 'Index: ', index_name)
                 from get_info(schema_name, tbl_name) as inf;
END;
$$ language plpgsql;
