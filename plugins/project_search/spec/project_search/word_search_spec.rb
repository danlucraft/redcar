
require File.dirname(__FILE__) + "/../spec_helper"

describe ProjectSearch::WordSearch do
  after do
    FileUtils.rm_rf(project_search_fixture_dir + "/.redcar")
  end
  
  describe "options of the search" do
    it "should have a query_string method" do
      make_search("testset").query_string.should == "testset"
    end
    
    it "should construct a regex to match the query string" do
      make_search("asdf", false).regex.should == /asdf/i
      make_search("asdf", true).regex.should == /asdf/
    end
    
    it "should respond whether matching case or not" do
      make_search("asdf", nil).match_case?.should == false
      make_search("asdf", 123).match_case?.should == true
    end
  end
  
  def fixture_project
    Redcar::Project.new(project_search_fixture_dir)
  end
  
  def make_search(query, match_case=true, context=0)
    ProjectSearch::WordSearch.new(fixture_project, query, match_case, context)
  end
  
  it "should find occurrences of full words" do
    results = make_search("Foo").results
    results.length.should == 1
    result = results.first
    result.should be_an_instance_of(ProjectSearch::Hit)
    result.file.should == project_search_fixture_dir + "/foo.txt"
    result.line_num.should == 0
    result.text("<b>", "</b>").should == ["<b>Foo</b> Bar Baz"]
  end
end