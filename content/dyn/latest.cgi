#!/usr/bin/perl

use strict;
use warnings;

use LWP;

print "Content-Type: text/html\n\n";

my $ua = LWP::UserAgent->new();

my $content = $ua->get("http://repository.apache.org/snapshots/org/apache/openejb/apache-tomee/4.0.0-SNAPSHOT/")->content;

$content = join(" ", split("[ \r\n]+", $content));
$content =~ s/(<tr>)/\n$1/g;
$content =~ s,(</tr>),$1\n,g;

foreach my $line (split("\n", $content)) {
    next if $line =~ /\.(sha1|md5|jar|pom|xml)|Parent/;
    print $line . "\n";
}
