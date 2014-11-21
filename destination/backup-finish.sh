#!/bin/sh

# at first get the basedir where to put the backups
cd "$(dirname "$1")"
cwd="$(pwd)"
# then get the dir of this script
cd -
cd "$(dirname "$0")"
script_dir="$(pwd)"

cd "$cwd"

mv "$(basename "$1")" "$(basename "$1" .incomplete)" \
&& rm -f Latest \
&& ln -s "$(basename "$1" .incomplete)" Latest

# clean outdated backups
if [ -f "$script_dir/backup-date-filter.lua" ] ; then
  ls | lua "$script_dir/backup-date-filter.lua" | grep -- "- " | cut -c3- | nice xargs rm -rf
fi
