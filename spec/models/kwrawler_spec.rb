require 'spec_helper'
require 'kwrawler'

describe Kwrawler do
  it { should respond_to( :crawl ) }

  describe '.crawl' do
    it "should take a string argument" do
      expect { Kwrawler.crawl }.to raise_error( ArgumentError )
    end
    it "should exit gracefully if the uri is invalid" do
      expect( Kwrawler.crawl( 'nonono' ) ).to match(/nvalid URI/)
    end
    it "should return a Sitemap as a hash" do
      sitemap = Kwrawler.crawl( 'http://127.0.0.1' )
      expect( sitemap ).to be_a( Hash )
      expect( sitemap.inspect ).to match(/Sitemap/)
    end
  end

end
