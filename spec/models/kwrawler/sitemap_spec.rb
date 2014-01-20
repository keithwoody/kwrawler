require 'spec_helper'
require 'kwrawler/sitemap'

describe Sitemap do
  it { should respond_to( :from_uri ) }
  it { should respond_to( :render_sitemap ) }
  it { should respond_to( :retrieve ) }
  it { should respond_to( :traverse_site ) }

  describe "#from_uri" do
    it "should require a URI" do
      expect{ subject.from_uri }.to raise_error
    end
    it "should exit gracefully for a bad URI" do
      subject.from_uri( "http://not.valid" ).should eql( "failed to read uri http://not.valid" )
    end
  end
  describe "#render_sitemap" do
    before do
      FileUtils.rm("sitemap.png") if File.exists?( 'sitemap.png' )
    end
    it "should output the sitemap as a png" do
      subject.render_sitemap
      File.exists?( 'sitemap.png' ).should be true
    end
    it "should take a format argument" do
      subject.render_sitemap( :jpg )
      File.exists?( 'sitemap.jpg' ).should be true
      FileUtils.rm( 'sitemap.jpg' ) if File.exists?( 'sitemap.jpg' )
    end
    it "should add a node for each page" do
      VCR.use_cassette('example.com') do
        subject.traverse_site( 'http://example.com/' )
      end
      subject.render_sitemap(:jpg)
      subject.site_graph.node_count.should == 1
    end
    it "should add an edge for each page link" do
      VCR.use_cassette('dnsimple.com') do
        subject.traverse_site( 'https://dnsimple.com/' )
      end
      subject.render_sitemap(:jpg, filename: 'dnsimple-sitemap.jpg')
      subject.site_graph.edge_count.should == 271
    end
  end
  describe "#retrieve" do
    it "should set current_contents to the data of a URI" do
      VCR.use_cassette('example.com') do
        subject.retrieve( 'http://example.com/' )
      end
      subject.current_contents.should =~ /html.*Example.*/m
    end
    it "should return #{Sitemap::URI_FAILURE} for bad URIs" do
      subject.retrieve( 'invalid URI' ).should == Sitemap::URI_FAILURE
    end
  end
  describe "#traverse_site" do
    before do
      URI.stub(:join).with( :any_uri, '/internal' ) { 'any_uri/internal' }
      URI.stub(:join).with( 'any_uri/internal', '/internal' ) { 'any_uri/internal' }
      subject.stub(:retrieve) { nil }
      subject.stub(:current_contents) { <<-EOS 
      <html>
        <head>
          <script src="local.js"></script>
          <link rel="stylesheet" href="local.css"/>
        </head>
        <body>
          <a href="/internal">internal</a>
          <a href="/internal#with_anchor">internal</a>
          <a href="http://external.com/about">external</a>
          <img src="local.png"/>
          <hr/>
          <img src="local.png"/>
        </body>
      </html>
      EOS
      }
    end
    it "should add unique js sources to the assets collection" do
      expect{ subject.traverse_site( :any_uri ) }.to change{ subject.site_hash[:assets][:scripts].size }.from(0).to(1)
      expect( subject.site_hash.inspect ).to match(%r|local.js|)
    end
    it "should add unique stylesheets to the assets collection" do
      expect{ subject.traverse_site( :any_uri ) }.to change{ subject.site_hash[:assets][:stylesheets].size }.from(0).to(1)
      expect( subject.site_hash.inspect ).to match(%r|local.css|)
    end
    it "should add unique images to the assets collection" do
      expect{ subject.traverse_site( :any_uri ) }.to change{ subject.site_hash[:assets][:imgs].size }.from(0).to(1)
      expect( subject.site_hash.inspect ).to match(%r|local.png|)
    end
    it "should add internal links to the site hash" do
      expect{ subject.traverse_site( :any_uri ) }.to change{ subject.site_hash[:links].size }.from(0).to(2)
      expect( subject.site_hash.inspect ).to match(%r|/internal|)
      expect( subject.site_hash.inspect ).not_to match(%r|/external|)
    end
    it "should add a page for each unique URI to the site hash" do
      expect{ subject.traverse_site( :any_uri ) }.to change{ subject.site_hash[:pages].size }.from(0).to(2)
    end
  end
end
