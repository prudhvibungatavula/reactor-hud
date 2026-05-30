#!/usr/bin/env bash
ps -eo comm,rss --sort=-rss 2>/dev/null | awk '
NR>1 && $2+0 > 50000 && $1 != "Isolated" {
    printf "%-11s %dM\n", substr($1,1,11), $2/1024
    count++
    if (count >= 7) exit
}'
