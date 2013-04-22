package view;

=head1 INTERFACE

Each function within view.pm which will be used for page generation must
implement a standard interface.

    sub my_view {
        my %args = @_;
        ...
        return ($content, $extension, @optional);
    }

First, each function must accept labeled parameters.  The only parameter which
will always be present is "path"; see the documentation in path.pm for the
"@patterns" array with regards to invocation with additional parameters.

Second, each function must return a list with at least two elements: the first
element must be the page content, and the second must be a file extention.
Returning additional elements in the list (as some of the functions below do)
is optional.

    return ($content, 'html', \%args);

The constraints imposed by this interface may cause difficulties, for example
when you want to generate both "foo.html" and "foo.pdf".  However, it is
usually possible to work around such issues with symlinks and dependency
management in path.pm.

=cut

use strict;
use warnings;
use Carp;
use Dotiac::DTL;
use ASF::Util qw( read_text_file );
use OpenEJBSiteDotiacFilter;
use Data::Dumper;
use LWP::Simple;

BEGIN { push @Dotiac::DTL::TEMPLATE_DIRS, "templates"; }

# This is most widely used view.  It takes a
# 'template' argument and a 'path' argument.
# Assuming the path ends in foo.mdtext, any files
# like foo.page/bar.mdtext will be parsed and
# passed to the template in the "bar" (hash)
# variable.
# Has the same behavior as the above for foo.page/bar.txt
# files, parsing them into a bar variable for the template.
# Otherwise presumes the template is the path.

sub news_page {
    my %args = @_;
    my $template = "content$args{path}";

    my $page_path = $template;
    $page_path =~ s/\.[^.]+$/.page/;
    if (-d $page_path) {
        for my $f (grep -f, glob "$page_path/*.mdtext") {
            $f =~ m!/([^/]+)\.mdtext$! or die "Bad filename: $f\n";
            $args{$1} = {};
            read_text_file $f, $args{$1};
        }
    }

    $args{base} = _base($args{path});
    my $rendered = Dotiac::DTL->new($template)->render(\%args);
    return ($rendered, 'html', \%args);
}

# A "basic" view, which takes 'template' and 'path' parameters.

sub basic {
    my %args = @_;
    my $filepath = "content$args{path}";

    print "basic $filepath";

    read_text_file($filepath, \%args);

    $args{path} =~ s/\.mdtext$/\.html/;
    $args{base} = _base($args{path});
    $args{breadcrumbs} = _breadcrumbs($args{path}, $args{base});

    my $template_path = "templates/$args{template}";

    my @includes = ($args{content} =~ m/{include:([^ ]+?)}/g);

    foreach my $include (@includes) {
        next unless ( -e "content/$include");

        my %a = ();
        read_text_file("content/$include", \%a);
        my $text = $a{content};
        $args{headers}{title} = $a{headers}{title} unless $args{headers}{title};

        # If the file to be included is in a child directory, resolve all the links
        # in the included content to be relative to this document
        if ($include =~ m,/,) {
            my $ipath = $include;
            $ipath =~ s,/[^/]*$,,;
            $text =~ s,(\[[^[]+])\(([^/][^)]+)\),$1($ipath/$2),g;
        }

        $args{content} =~ s/{include:$include}/$text/g;
    }

    if ($args{headers}{version}) {
        my $url = "http://repository.apache.org/content/groups/snapshots/org/apache/openejb/apache-tomee/$args{headers}{version}-SNAPSHOT/maven-metadata.xml";
        my $_ = get($url);
        s/\n| //g;
        my ($timestamp, $buildNumber) = m,<timestamp>(.*)</timestamp>.*<buildNumber>(.*)</buildNumber>.*,;
        $args{headers}{build} = "$timestamp-$buildNumber";

        $args{changelog} = `java -jar lib/release-tools-1.0-SNAPSHOT-jar-with-dependencies.jar releasenotes -DtomeeVersion=$args{headers}{version} -DopenejbVersion=$args{headers}{oversion}`;
        print $args{changelog};
    }

    if ($args{headers}{oversion}) {
        my $url = "http://repository.apache.org/content/groups/snapshots/org/apache/openejb/openejb-standalone/$args{headers}{oversion}-SNAPSHOT/maven-metadata.xml";
        my $_ = get($url);
        s/\n| //g;
        my ($timestamp, $buildNumber) = m,<timestamp>(.*)</timestamp>.*<buildNumber>(.*)</buildNumber>.*,;
        $args{headers}{obuild} = "$timestamp-$buildNumber";
    }

    print " - rendering";

    my $rendered = Dotiac::DTL->new($template_path)->render(\%args);

    print " - complete\n";

    return ($rendered, 'html', \%args);
}

sub swizzle_jira {
    my %args = @_;
    my $filepath = "content$args{path}";

    print "swizzle_jira $filepath";

    read_text_file($filepath, \%args);

    print " - java";

#    $args{content} = `java -jar lib/swizzle-jirareport-1.6.2-SNAPSHOT-dep.jar $filepath`;
#    $args{content} =~ s,Title:.*\n,,;

    $args{path} =~ s/\.mdtext$/\.html/;
    $args{base} = _base($args{path});

    print " - breadcrumbs";

    $args{breadcrumbs} = _breadcrumbs($args{path}, $args{base});

    my $template_path = "templates/$args{template}";

    print " - rendering";

    my $rendered = Dotiac::DTL->new($template_path)->render(\%args);

    print " - complete\n";

    return ($rendered, 'html', \%args);
}

sub apilinks {
    my $dir = shift;

    my %imports;

    for my $java (listdir($dir, ".*\.java\$")) {

        open J, "<$java" or die "Can't open $java: $!\n";
        while (<J>) {
            next unless /^import.*javax/;
            next if /\*/;
            chomp;
            my $static = m/static/;
            s/.* |;$//g;

            my $link = $_;
            $link =~ s/(.*)\./$1#/ if $static;
            $link =~ s,\.,/,g;
            $link =~ s,(#.*)$,.html$1, if $static;
            $link =~ s,$,.html, unless $static;

            $imports{$_} = $link;
        }
    }

    my $apis = "<ul>";
    for my $i (sort keys %imports) {
        $apis .= "<li><a href=\"http://docs.oracle.com/javaee/6/api/$imports{$i}\">$i</a></li>\n";
    }
    $apis .= "</ul>";

    return $apis;
}

sub example {
    my %args = @_;
    my $filepath = "content$args{path}";

    print "example $filepath";

    read_text_file($filepath, \%args);

    $args{path} =~ s/README\.md(text)?$/index\.html/;
    $args{base} = _base($args{path});

    print " - breadcrumbs";

    $args{breadcrumbs} = _breadcrumbs($args{path}, $args{base});

    print " - zipurl";

    $args{zipurl} = _zipurl($args{path});

    my $dir = $filepath;
    $dir =~ s!/[^/]+$!!;

    print " - apilinks";

    $args{apis} = apilinks($dir);

    my $template_path = "templates/$args{template}";

    my $svndir = $args{path};
    $svndir =~ s,/index.html,,;
    $svndir =~ s,/examples-trunk/,trunk/examples/,;

    $args{repo} = $svndir;

    my $example = $svndir;
    $example =~ s,.*/,,;
    $args{example} = $example;

#    print Dumper( \%args );
    print " - rendering";

    my $rendered = Dotiac::DTL->new($template_path)->render(\%args);

    print " - complete\n";

    return ($rendered, 'html', \%args);
}

sub sitemap {
    my %args = @_;
    my $template = "content/$args{path}";
#    $args{breadcrumbs} .= _breadcrumbs($args{path});
    $args{base} = _base($args{path});

    my $dir = $template;
    $dir =~ s!/[^/]+$!!;
    opendir my $dh, $dir or die "Can't opendir $dir: $!\n";
    my %data;
    for (map "$dir/$_", grep $_ ne "." && $_ ne ".." && $_ ne ".svn", readdir $dh) {
        if (-f and /\.(mdtext|swjira)$/) {
            my $file = $_;
            $file =~ s/^content//;
            no warnings 'once';
            for my $p (@path::patterns) {
                my ($re, $method, $args) = @$p;
                next unless $file =~ $re;
                my $s = view->can($method) or die "Can't locate method: $method\n";
                my ($content, $ext, $vars) = $s->(path => $file, %$args);
                $file =~ s/\.(mdtext|swjira)$/.$ext/;
                $data{$file} = $vars;
                last;
            }
        }
    }

    my $content = "";

    for (sort keys %data) {
        my $link = $_;
        $link =~ s,.*/,,;

        my $title = $data{$_}->{headers}->{title};
        $title = $link unless $title;

        $content .= "- [$title]($link)\n";
        for my $hdr (grep /^#/, split "\n", $data{$_}->{content}) {
            $hdr =~ /^(#+)\s+([^#]+)?\s+\1\s+\{#([^}]+)\}$/ or next;
            my $level = length $1;
            $level *= 4;
            $content .= " " x $level;
            $content .= "- [$2]($_#$3)\n";
        }
    }

    $args{content} = $content;
    my $rendered = Dotiac::DTL->new($template)->render(\%args);

    return ($rendered, 'html', \%args);
#    return Dotiac::DTL::Template($template)->render(\%args), html => \%args;
}

sub sitemapxml {
    my %args = @_;
    my $template = "content/$args{path}";
    $args{base} = _base($args{path});

    my $dir = $template;
    $dir =~ s!/[^/]+$!!;

    my %data = listcontent($dir);

    my $content .= '<?xml version="1.0" encoding="utf-8"?>' . "\n";
    $content .= '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . "\n";

    for (sort keys %data) {
        my $link = $_;
        $link =~ s,^//,,;

        $content .= "    <url>\n";
        $content .= "        <loc>http://tomee.apache.org/$link</loc>\n";

        if ($link =~ m/tomcat/) {
            $content .= "        <priority>0.8</priority>\n";
        } elsif ($link =~ m/example/) {
            $content .= "        <priority>0.9</priority>\n";
        }

        $content .= "    </url>\n";
    }

    $content .= "</urlset>\n";

    $args{content} = $content;

    return ($content, 'xml', \%args);
}

sub listcontent {
    my $dir = shift;
    my %data;

    opendir my $dh, $dir or die "Can't opendir $dir: $!\n";
    for (map "$dir/$_", grep $_ ne "." && $_ ne ".." && $_ ne ".svn", readdir $dh) {
        if (-f and /\.md(text)?$/) {
            my $file = $_;
            $file =~ s/^content//;
            no warnings 'once';
            for my $p (@path::patterns) {
                my ($re, $method, $args) = @$p;
                next unless $file =~ $re;
                my $s = view->can($method) or die "Can't locate method: $method\n";
                my ($content, $ext, $vars) = $s->(path => $file, %$args);
                $file =~ s/\.md(text)?$/.$ext/;

                $data{$file} = $vars;
                last;
            }
        } elsif (-d) {
            my %subdir = listcontent($_);
            %data = (%subdir, %data);
        }
    }

    return %data;
}

sub listdir {
    my $dir = shift;
    my $pattern = shift;

    my @files;

    opendir my $dh, $dir or die "Can't opendir $dir: $!\n";
    for (map "$dir/$_", grep $_ ne "." && $_ ne ".." && $_ ne ".svn", readdir $dh) {
        if (-f and /$pattern/) {
            push @files, $_;
        } elsif (-d) {
            my @subdir = listdir($_, $pattern);
            push @files, @subdir;
        }
    }

    return @files;
}


sub _breadcrumbs {
    my $path        = shift;
    my $base        = shift;

    my $index = "$base/index.html";
    $index =~ s,/+,/,g;

    my @breadcrumbs = (
        qq|<a href="$index">Home</a>|,
    );
    my @path_components = split( m!/!, $path );
    pop @path_components;

    my $relpath = $base;


    for (@path_components) {
        $relpath .= "$_/";
        $relpath =~ s,/+,/,g;
        next unless $_;

        my @names = split("-", $_);
        my $name = "";
        for my $n (@names) {
            $name .= ucfirst($n) . " ";
        }
        $name =~ s/ *$//;
        push @breadcrumbs, qq(<a href="$relpath">\u$name</a>);
    }
    return join "&nbsp;&raquo&nbsp;", @breadcrumbs;
}

sub _base {
    my $path        = shift;

    my @path_components = split( m!/!, $path );
    pop @path_components;
    pop @path_components;

    my $rel = "./";

    for (@path_components) {
        $rel .= "../";
    }

    return $rel;
}

sub _zipurl {
    my $path        = shift;

    my $base = "http://ci.apache.org/projects/openejb/examples-generated/";

    # path:  /examples-trunk/simple-stateless/index.html

    $path =~ s,.*/([^/]+)/index.html,$1/$1.zip,;

    return $base . $path;
}

1;

__END__

=head1 LICENSE

    Licensed to the Apache Software Foundation (ASF) under one or more
    contributor license agreements.  See the NOTICE file distributed with
    this work for additional information regarding copyright ownership.  The
    ASF licenses this file to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance with the
    License.  You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
    License for the specific language governing permissions and limitations
    under the License.

=cut

