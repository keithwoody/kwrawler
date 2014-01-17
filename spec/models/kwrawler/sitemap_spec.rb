require 'spec_helper'
require 'kwrawler/sitemap'

describe Sitemap, focus: true do
  it { should respond_to( :from_uri ) }
  it { should respond_to( :render_sitemap ) }
  it { should respond_to( :retrieve ) }
  it { should respond_to( :traverse_site ) }

  describe "#from_uri" do
    it "should require a uri" do
      expect{ subject.from_uri }.to raise_error( ArgumentError )
    end
  end
  describe "#render_sitemap" do
  end
  describe "#retrieve" do
    it "should return the contents of a URI" do
      expect( subject.retrieve( 'http://www.google.com' ) ).to match(%r{html})
    end
  end
  describe "#traverse_site" do
  end
end
