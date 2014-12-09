#!/bin/sh
cd "$(dirname "$0")"

tmp="/tmp/$(basename "$0").stdout~"
tmpE="/tmp/$(basename "$0").stderr~"

t0="2014-12-08T04:23:01"
t0="2014-12-08-042301"

for src in "$(basename "$0" .sh)".*.stdin
do
  dst="$(basename "$src" .stdin).stdout"
  ./backup-date-filter.lua $t0 < "$src" 1> "$tmp" 2> "$tmpE"
  diff "$tmp" "$dst"
  if [ $? -ne 0 ] ; then
    echo "Failed: $src" 1>&2
  else
    echo "OK: $src" 1>&2
  fi
  rm "$tmp" "$tmpE"
done

