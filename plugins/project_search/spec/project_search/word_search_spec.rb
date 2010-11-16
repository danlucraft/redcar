
require File.dirname(__FILE__) + '/../spec_helper'

describe ProjectSearch::WordSearch do
  
  DEFAULT_OPTIONS = {:match_case => true, :with_context => true}
  
  def search(project, query, options=nil)
    options = options || DEFAULT_OPTIONS
    ProjectSearch::WordSearch.new(project, query, options)
  end
  
end