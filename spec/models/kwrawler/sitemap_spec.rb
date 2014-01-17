require 'spec_helper'
require 'kwrawler/sitemap'

describe Sitemap do
  it { should respond_to( :from_uri ) }
  it { should respond_to( :render_sitemap ) }
  it { should respond_to( :retrieve ) }
  it { should respond_to( :traverse_site ) }

  describe "#from_uri" do
    it "should require a uri" do
      expect{ subject.from_uri }.to raise_error
      expect{ subject.from_uri('http://www.google.com') }.not_to raise_error
    end
  end
  describe "#render_sitemap" do
    let(:sitemap) { subject.render_sitemap.inspect }
    it "should output the site hash" do
      expect( sitemap ).to match(/pages/)
      expect( sitemap ).to match(/assets/)
      expect( sitemap ).to match(/links/)
    end
  end
  describe "#retrieve" do
    it "should set current_contents to the data of a URI" do
      subject.retrieve( 'http://www.google.com' )
      subject.current_contents.should =~ /html.*google.*/
    end
    it "should return #{Sitemap::URI_FAILURE} for bad URIs" do
      subject.retrieve( 'invalid URI' ).should == Sitemap::URI_FAILURE
    end
  end
  describe "#traverse_site" do
    before do
      subject.stub(:retrieve) { nil }
      subject.stub(:current_contents) { <<-EOS 
      <html>
        <head>
          <script src="local.js"></script>
          <link rel="stylesheet" href="local.css"/>
        </head>
        <body>
          <a href="/internal">internal</a>
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
      expect{ subject.traverse_site( :any_uri ) }.to change{ subject.site_hash[:links].size }.from(0).to(1)
      expect( subject.site_hash.inspect ).to match(%r|/internal|)
      expect( subject.site_hash.inspect ).not_to match(%r|/external|)
    end
    it "should add a page for the initial URI to the site hash" do
      expect{ subject.traverse_site( :any_uri ) }.to change{ subject.site_hash[:pages].size }.from(0).to(1)
    end
    it "should process each internal link like the root URI"
  end
end
