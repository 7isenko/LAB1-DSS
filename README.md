### Запуск

Из терминала: `psql ... -f exec.sql`\
Из psql: `\i exec.sql` или `\include exec.sql`

### Установка аргументов

Из терминала (для строки): `psql ... -v myvariable="'value'"`\
Или если использовать трюк для строк: `psql ... -v myvariable=value`

Из psql: `\set myvariable value`

### Пример

Из терминала: `psql -h pg -d studs -f exec.sql -v schema=public -v table=location`

Из psql: 
```postgresql
\set schema public
\set table location
\include exec.sql
```