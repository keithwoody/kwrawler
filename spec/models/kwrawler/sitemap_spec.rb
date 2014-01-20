require 'spec_helper'
require 'kwrawler/sitemap'

describe Sitemap do
  it { should respond_to( :from_uri ) }
  it { should respond_to( :render_sitemap ) }
  it { should respond_to( :retrieve ) }
  it { should respond_to( :traverse_site ) }
  it { should respond_to( :build_site_graph ) }

  describe "#from_uri" do
    it "should require a URI" do
      expect{ subject.from_uri }.to raise_error
    end
    it "should exit gracefully for a bad URI" do
      subject.from_uri( "http://not.valid" ).should eql( "failed to read uri http://not.valid/" )
    end
    it "should take an options hash to customize rendering" do
      FileUtils.rm('example-sitemap.png') if File.exists?('example-sitemap.png')
      VCR.use_cassette('example.com') do
        subject.from_uri('http://example.com', filename: 'example-sitemap.png')
      end
      File.exists?('example-sitemap.png').should be_true
    end
    it "should be able to traverse joingrouper.com" do
      VCR.use_cassette('joingrouper.com') do
        expect{ subject.from_uri( "https://joingrouper.com", format: :svg, filename: 'jg-sitemap.svg' ) }.not_to raise_error
      end
    end
  end
  describe "#render_sitemap" do
    it "should output the sitemap as a png" do
      FileUtils.rm("sitemap.png") if File.exists?( 'sitemap.png' )
      subject.render_sitemap
      File.exists?( 'sitemap.png' ).should be true
    end
    it "should take a format argument" do
      subject.render_sitemap( :jpg )
      File.exists?( 'sitemap.jpg' ).should be true
      FileUtils.rm( 'sitemap.jpg' ) if File.exists?( 'sitemap.jpg' )
    end
    it "should take an options hash" do
      subject.render_sitemap( :jpg, filename: "custom.JPEG" )
      File.exists?( 'custom.JPEG' ).should be true
      FileUtils.rm( 'custom.JPEG' ) if File.exists?( 'custom.JPEG' )
    end
    it "should build the site_graph only once" do
      VCR.use_cassette('example.com') do
        subject.traverse_site( 'http://example.com/' )
      end
      subject.render_sitemap
      graph1_id = subject.site_graph.object_id
      subject.render_sitemap
      subject.site_graph.object_id.should == graph1_id
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
  describe "#build_site_graph" do
    before(:each) do
      VCR.use_cassette('dnsimple.com') do
        subject.traverse_site( 'https://dnsimple.com/' )
      end
    end
    it "should initialize the site_graph attribute" do
      subject.site_graph.should be_nil
      subject.build_site_graph
      subject.site_graph.should be_a( GraphViz )
    end
    it "should add a label for the image" do
      subject.build_site_graph
      subject.site_graph[:label].to_s.should eql('"Sitemap"')
    end
    it "should coalesce duplicated edges" do
      # i.e. we don't need both A->B and B->A, instead A<->B
      subject.build_site_graph
      subject.site_graph[:concentrate].should be_true
    end
    it "should add a node to the graph for each page of the site" do
      subject.build_site_graph
      subject.site_graph.node_count.should == 21
    end
    it "should add an edge to the graph for each link between pages" do
      subject.build_site_graph
      subject.site_graph.edge_count.should == 271
    end
  end
end
