# Kwrawler

Pronounced "crawler" but I shoe-horned my initials in there, how clever.

Requires nokogiri and ruby-graphviz during runtime.

Crawls a single domain without traversing external links and outputs a sitemap
showing:

1. which static assets each page depends on (imgs, script srcs, and stylesheets)
2. the links between pages

Sitemap can be exported as :png, :jpg, :dot or any GraphViz supported format

## Installation

Build the gem

    git clone https://github.com/keithwoody/kwrawler.git
    cd kwrawler
    rake build && rake install

Add this line to your application's Gemfile:

    gem 'kwrawler'

And then execute:

    $ bundle


## Usage

    require 'kwrawler'
    Kwrawler.crawl( site_url )

  or

    $ irb
    > require 'kwrawler'

    > sm = Kwrawler::Sitemap.new
    > sm.from_uri( <some domain>, format: :svg, filename: 'custom-sitemap.svg' )
    > exit
    $ open custom-sitemap.svg


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
