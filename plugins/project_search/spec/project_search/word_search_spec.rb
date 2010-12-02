
require File.dirname(__FILE__) + "/../spec_helper"

describe ProjectSearch::WordSearch do
  
  def fixture_project
    Redcar::Project.new(project_search_fixture_dir)
  end
  
  def search(query, match_case=true, context=0)
    ProjectSearch::WordSearch.new(fixture_project, query, match_case, context)
  end
  
  it "should find occurrences of full words" do
    results = search("Foo").results
    results.length.should == 1
    result = results.first
    result.should be_an_instance_of(ProjectSearch::Hit)
    result.file.should == project_search_fixture_dir + "/foo.txt"
    result.line.should == 0
    result.text("<b>", "</b>").should == ["<b>Foo</b> Bar Baz"]
  end
end