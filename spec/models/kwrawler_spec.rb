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
    it "should export a Sitemap as an image" do
      VCR.use_cassette('example.com') do
        FileUtils.rm('sitemap.png') if File.exists?( 'sitemap.png' )
        Kwrawler.crawl( 'http://example.com' )
        File.exists?( 'sitemap.png' ).should be true
      end
    end
  end

end
