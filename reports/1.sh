#!/bin/sh
echo '.tables'|sqlite3 -header -line devel.db|fmt --width 1|sort
