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
      "{#{uri} |{ IMGS |{#{img_labels}} }|{ JS |{#{script_labels}} }|{ CSS |{#{stylesheet_labels}} } }"
    end
    def img_labels
      properties[:assets][:imgs].join('|')
    end
    def script_labels
      properties[:assets][:scripts].join('|')
    end
    def stylesheet_labels
      properties[:assets][:stylesheets].join('|')
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
  end

  def build_site_graph
    self.site_graph = GraphViz.new(:S, type: "strict digraph")
    site_graph[:concentrate] = true  # combine duplicated edges
    site_graph[:label] = "Sitemap"
    NODE_ATTRIBUTES.each  { |attribute, value| site_graph.node[attribute] = value }
    site_graph.edge[:colorscheme] = "dark25"
    puts "adding page nodes..."
    site_hash[:pages].each do |page|
      node_options = page.to_node
      site_graph.add_node( page.uri, node_options )
    end
    puts "adding link edges..."
    site_hash[:pages].each_with_index do |page, idx|
      color = ( idx % 5 )+1
      page_node = site_graph.get_node( page.uri )
      link_nodes = page.properties[:links].map { |luri| site_graph.get_node(luri) }.compact
      site_graph.add_edges( page_node, link_nodes, color: color.to_s )
    end
  end

  def from_uri( uri_str, render_options={} )
    uri_str += '/' if uri_str =~ /\.\w\w+$/
    if traverse_site( uri_str )
      format = render_options.delete(:format) || :png
      render_sitemap( format, render_options )
    else
      URI_FAILURE + " " + uri_str
    end
  end


  def render_sitemap( format=:png, options={} )
    build_site_graph if site_graph.nil?
    filename = options[:filename]
    filename ||= "sitemap.#{format}"
    puts "rendering..."
    site_graph.output( format => filename )
    # site_hash
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
