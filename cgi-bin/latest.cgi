#!/usr/bin/perl

use strict;
use warnings;

print "Content-Type: text/html\n\n";

my $artifact = $ENV{PATH_INFO};

$artifact = "/apache-tomee/1.0.1-SNAPSHOT" unless $artifact;
$artifact =~ s,^([^/]),/$1,;

my $content = `wget -d -O - http://repository.apache.org/snapshots/org/apache/openejb/apache-tomee/1.0.1-SNAPSHOT`;

$content = join(" ", split("[ \r\n]+", $content));
$content =~ s/(<tr>)/\n$1/g;
$content =~ s,(</tr>),$1\n,g;

foreach my $line (split("\n", $content)) {
    next if $line =~ /\.(sha1|md5|jar|pom|xml)|Parent/;
    print $line . "\n";
}
print "<pre>";
foreach (keys %ENV) {
    print $_;
    print " = ";
    print $ENV{$_};
    print "\n";
}
print "</pre>";
