require 'open-uri'

class Sitemap
  URI_FAILURE = "failed to read uri"

  @site_hash = { pages: [],
                 links: [],
                 static_assets: []
  }
  attr_accessor :site_hash

  def from_uri( uri )
    contents = retrieve( uri )
    unless contents.eq?( URI_FAILURE )
      traverse_site( contents )
      render_sitemap
    end
  end

  def render_sitemap
    "sitemap"
  end

  def retrieve( uri )
    contents = ""
    # begin
      contents = open( uri ).read
    # rescue #errors 404, 500, etc.
    #   return URI_FAILURE
    # end
    contents
  end

  def traverse_site( html )
  end
end
