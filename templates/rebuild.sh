#!/bin/bash
perl -i -pe 's/^##(\d+)/"##".($1+1)/e' "$0" && svn ci -m "${1:-triggering new build}" "$0"
##3
