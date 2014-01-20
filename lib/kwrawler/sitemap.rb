require 'open-uri'
require 'nokogiri'
require 'graphviz'

class Sitemap
  URI_FAILURE = "failed to read uri"
  NODE_ATTRIBUTES = {
    :shape => "record",
    :fontsize => 10,
    :fontname => "ArialMT",
    :margin => "0.07,0.05",
    :penwidth => 1.0
  }


  attr_accessor :site_graph, :site_hash, :current_contents, :title

  class Page < Struct.new(:uri, :properties)
    def label_for_properties
      "{#{uri} |{ IMGS |{foo.jpg|bar.jpg|baz.jpg} }|{ JS |{main.js|page.js} }|{ CSS |{app.css|page.css} } }"
    end
    def to_node
      {label: label_for_properties}
    end
  end
  #status can be :new, :processed, :unreachable
  class Link < Struct.new(:href, :status); end

  def initialize
    @site_hash = { pages: [],
                   links: {},
                   assets: { imgs: [],
                             scripts: [],
                             stylesheets: [] }
                 }
    @site_graph = GraphViz.new(:S, type: :digraph)
    @site_graph[:label] = "Sitemap"
    NODE_ATTRIBUTES.each  { |attribute, value| @site_graph.node[attribute] = value }
  end

  def from_uri( uri_str )
    if traverse_site( uri_str )
      render_sitemap
    else
      URI_FAILURE + " " + uri_str
    end
  end


  def render_sitemap( format=:png, options={} )
    site_hash[:pages].each do |page|
      node_options = page.to_node
      site_graph.add_nodes( page.uri, node_options )
    end
    site_hash[:pages].each do |page|
      page_node = site_graph.get_node( page.uri )
      link_nodes = page.properties[:links].map { |href| site_graph.get_node(href) }
      link_nodes.each do |node|
        site_graph.add_edges( page_node, node )
      end
    end
    filename = options[:filename]
    filename ||= "sitemap.#{format}"
    site_graph.output( format => filename )
    site_hash
  end

  def retrieve( uri_str )
    begin
      self.current_contents = open( uri_str ).read
    rescue #errors 404, 500, etc.
      return URI_FAILURE
    end
  end

  def traverse_site( uri_str )
    return false if retrieve( uri_str ).eql?( URI_FAILURE )
    puts "#{Time.now.to_i} traversing #{ uri_str }"
    page_hash = { assets: { imgs: [],
                            scripts: [],
                            stylesheets: [] },
                  links: []
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
      if uri_str != href && href !~ /(#|mailto|javascript)/  #exclude anchor, mailto and js function links
        child_uri = URI.join(uri_str, href).to_s
        unless page_hash[:links].include?( child_uri )
          page_hash[:links] << child_uri
        end
        site_hash[:links][ child_uri ] ||= Link.new(child_uri, :new)
      end
    end
    # add the current page and set it as processed
    site_hash[:pages] << Page.new(uri_str, page_hash)
    site_hash[:links][ uri_str ] ||= Link.new(uri_str, :new)
    site_hash[:links][ uri_str ].status = :processed

    site_hash[:links].dup.each do |key, link_obj|
      if link_obj.status.eql?( :new )
        traverse_site( link_obj.href )
      end
    end

    true
  end
end
