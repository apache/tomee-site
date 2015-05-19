package path;
use strict;
use warnings;
use ASF::Value;


# The @patterns array is used to map filepaths to page treatments.  Each
# element must be an arrayref with 3 elements of its own: a regex pattern for
# selecting filepaths, the name of the subroutine from view.pm which will be
# invoked to generate the page, and a hashref of named parameters which will
# be passed to the view subroutine.


our @patterns = (

    [qr!^/index\.html$!, news_page => {
        tomeeBlog     => ASF::Value::Blogs->new(blog => "tomee", limit=> 1),
        openejbBlog     => ASF::Value::Blogs->new(blog => "openejb", limit=> 3),
    }],

    [qr!^/logo\.html$!, news_page => { }],
    [qr!^/downloads.html$!, news_page => { }],
    [qr!^/download/.*.html$!, news_page => { }],

    [qr!^/download/tomee-1.*-snapshot.mdtext$!, basic => {
        template => "snapshot.html"
    }],
    [qr!^/download/tomee-2.*-snapshot.mdtext$!, basic => {
        template => "snapshot7.html"
    }],
    [qr!^/download/tomee-7.*-snapshot.mdtext$!, basic => {
        template => "snapshot7.html"
    }],

    [qr!README\.md(text)?$!, example => {
        template => "example.html"
    }],

    [qr!\.md(text)?$!, basic => {
        template => "doc.html"
    }],

    [qr!\.swjira?$!, swizzle_jira => {
        template => "doc.html"
    }],

    [qr!sitemap\.html$!, sitemap => {
        headers => { title => "Sitemap" }
    }],

    [qr!dev/index\.html$!, sitemap => {
        headers => { title => "Project Resources" }
    }],
    [qr!dev/jira/index\.html$!, sitemap => {
        headers => { title => "Project Resources" }
    }],

    [qr!sitemap.xml$!, sitemapxml => {
        headers => { }
    }],


);

# The %dependecies hash is used when building pages that reference or depend
# upon other pages -- e.g. a sitemap, which depends upon the pages that it
# links to.  The keys for %dependencies are filepaths, and the values are
# arrayrefs containing other filepaths.
our %dependencies = (
    "/sitemap.html" => [ grep s!^content!!, glob "content/*.mdtext" ],
    "/sitemap.xml" => [ grep s!^content!!, glob "content/*.mdtext" ],
    "/dev/index.html" => [ grep s!^content!!, glob "content/dev/*.mdtext" ],
);

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

