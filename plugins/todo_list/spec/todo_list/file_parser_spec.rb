require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Redcar::TodoList::FileParser do
  before do
    @parser   = Redcar::TodoList::FileParser.new
    @fixtures = File.expand_path("../../fixtures", __FILE__)

    TodoList.storage['tags'] = ["FIXME", "OPTIMIZE", "NOTE", "TODO"]
    TodoList.storage['excluded_files'] = ["NOTE.ignored.file"]
    TodoList.storage['require_colon'] = false
    TodoList.storage['excluded_dirs'] = ["ignored_directory"]
    TodoList.storage['included_suffixes'] = [".file"]

    @tags = @parser.parse_files(@fixtures)
  end

  it "should find tags that are in the tag list" do
    @tags.keys.should include "FIXME"
    @tags.keys.should include "OPTIMIZE"
  end

  it "should find only colon'ed tags if that requirement is set in the settings" do
    TodoList.storage['require_colon'] = true
    @parser   = Redcar::TodoList::FileParser.new
    tags      = @parser.parse_files(@fixtures)
    tags.keys.should include "OPTIMIZE"
    tags.keys.should_not include "FIXME"
    TodoList.storage['require_colon'] = false
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