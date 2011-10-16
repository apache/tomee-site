#!/bin/bash

echo "Content-Type: text/xml"
echo ""

wget -q  -O - 'http://search.twitter.com/search.atom?q=tomee' | tr '\n\r' '  '| perl -pe 's,(<entry>),\n$1,g; s,(</entry>),$1\n,g;'| perl -pe 's,<entry>.*?</entry>,, unless m/TomEE/'
