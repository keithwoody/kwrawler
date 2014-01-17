require 'open-uri'
require 'nokogiri'

class Sitemap
  URI_FAILURE = "failed to read uri"

  attr_accessor :site_hash, :current_contents

  class Page < Struct.new(:uri, :properties); end
  #status can be :new, :processed, :unreachable
  class Link < Struct.new(:href, :status); end

  def initialize
    @site_hash = { pages: [],
                   links: {},
                   assets: { imgs: [],
                             scripts: [],
                             stylesheets: [] }
                 }
  end

  def from_uri( uri )
    if traverse_site( uri )
      render_sitemap
    end
  end

  def render_sitemap
    site_hash
  end

  def retrieve( uri )
    begin
      self.current_contents = open( uri ).read
    rescue #errors 404, 500, etc.
      return URI_FAILURE
    end
  end

  def traverse_site( uri )
    return false if retrieve( uri ).eql?( URI_FAILURE )
    page_hash = { assets: { imgs: [],
                            scripts: [],
                            stylesheets: [] },
                  links: {}
                 }
    html_doc = Nokogiri::HTML( current_contents )
    # get all scripts, stylesheets and images
    srcs = html_doc.css('script').map { |s| src = s.attributes['src']; src.value if src }.compact
    srcs.each do |src|
      page_hash[:assets][:scripts] << src unless page_hash[:assets][:scripts].include?( src )
    end
    site_hash[:assets][:scripts] |= page_hash[:assets][:scripts]

    hrefs = html_doc.css('link[rel="stylesheet"]').map { |l| href = l.attributes['href']; href.value if href }.compact
    hrefs.each do |href|
      page_hash[:assets][:stylesheets] << href unless page_hash[:assets][:stylesheets].include?( href )
    end
    site_hash[:assets][:stylesheets] |= page_hash[:assets][:stylesheets]

    imgs = html_doc.css('img').map { |i| img = i.attributes['src']; img.value if img  }.compact
    imgs.each do |img|
      page_hash[:assets][:imgs] << img unless page_hash[:assets][:imgs].include?( img )
    end
    site_hash[:assets][:imgs] |= page_hash[:assets][:imgs]

    # get all internal links on the page
    links = html_doc.css('a').map { |l| link = l.attributes['href']; link.value if link && (link.value !~ %r{^http(s)?:.*})  }.compact
    links.each do |href|
      link = Link.new( href, :new )
      page_hash[:links][href] = link unless page_hash[:links].keys.include?( link )
    end
    site_hash[:links].merge!( page_hash[:links] )

    site_hash[:pages] << Page.new(uri, :success, page_hash)
    # TODO: process links
    true
  end
end
