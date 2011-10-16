#!/bin/bash

echo "Content-Type: text/xml"
echo ""

wget -q  -O - 'http://search.twitter.com/search.atom?q=tomee' | perl -pe 's,(<entry>.*?</entry>),\n$1\n,g'| perl -pe 's,<entry>.*?</entry>,, unless m/TomEE/'
