#!/usr/bin/perl

use strict;
use warnings;

print "Content-Type: text/html\n\n";

my $a = "apache-tomee/1.0.1-SNAPSHOT/";
$a = $ENV{PATH_INFO} if $ENV{PATH_INFO};

my $content = `wget -O - -q http://repository.apache.org/snapshots/org/apache/openejb/$a`;

$content = join(" ", split("[ \r\n]+", $content));
$content =~ s/(<tr>)/\n$1/g;
$content =~ s,(</tr>),$1\n,g;

foreach my $line (split("\n", $content)) {
    next if $line =~ /\.(sha1|md5|jar|pom|xml)|Parent/;
    print $line . "\n";
}
