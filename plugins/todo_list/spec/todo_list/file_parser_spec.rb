require File.expand_path("../../spec_helper", __FILE__)

describe Redcar::TodoList::FileParser do
  before do
    TodoListSpecHelper.set_fixture_settings
    @parser = Redcar::TodoList::FileParser.new
    @tags   = @parser.parse_files(TodoListSpecHelper::Fixtures)
  end

  it "should find tags that are in the tag list" do
    @tags.keys.should include "FIXME"
    @tags.keys.should include "OPTIMIZE"
  end

  it "should find only colon'ed tags if that requirement is set in the settings" do
    Redcar::TodoList.storage['require_colon'] = true
    @parser = Redcar::TodoList::FileParser.new
    tags    = @parser.parse_files(TodoListSpecHelper::Fixtures)
    tags.keys.should include "OPTIMIZE"
    tags.keys.should_not include "FIXME"
    Redcar::TodoList.storage['require_colon'] = false
  end

  it "should not search files without included suffixes" do
    @tags.keys.should_not include "XXX"
  end

  it "should not search excluded files" do
    @tags.keys.should_not include "NOTE"
  end

  it "should ignore files in excluded dirs" do
    @tags.keys.should_not include "TODO"
  end
end