#!/usr/bin/perl -T

use strict;
use warnings;

print "Content-Type: text/html\n\n";
my $artifact = "/apache-tomee/1.0.1-SNAPSHOT/";
$artifact = $ENV{PATH_INFO} if $ENV{PATH_INFO};

$artifact = "/$artifact/";
$artifact =~ s,/+,/,g;
$artifact =~ s,[^a-zA-Z.[0-9]-],,g;
$artifact =~ s,\.\./,,g;

my $content = `wget -q -O - http://repository.apache.org/snapshots/org/apache/openejb$artifact`;

my $ua = <<EOF;
    <script type="text/javascript">

      var _gaq = _gaq || [];
      _gaq.push(['_setAccount', 'UA-2717626-1']);
      _gaq.push(['_setDomainName', 'apache.org']);
      _gaq.push(['_trackPageview']);

      (function() {
        var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
        ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
      })();

    </script>
EOF

$content = join(" ", split("[ \r\n]+", $content));
$content =~ s/(<tr>)/\n$1/g;
$content =~ s,(</tr>),$1\n,g;

foreach my $line (split("\n", $content)) {
    next if $line =~ /\.(sha1|md5|jar|pom|xml)|Parent/;
    $line =~ s,</head>,$ua\n</head>,i;
    print $line . "\n";
}
