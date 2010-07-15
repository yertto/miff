#!/bin/sh
for table in `reports/1.sh`; do
  echo "`echo "select count(*) from $table;"|sqlite3 devel.db`\t $table"
done
