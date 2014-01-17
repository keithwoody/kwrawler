require "kwrawler/version"
require "kwrawler/sitemap"
require "uri"
require "open-uri"

module Kwrawler
  def self.crawl( uri )
    return "Invalid URI: #{uri}" unless uri.to_s =~ URI::regexp
    Sitemap.new.from_uri( uri )
  end
end
