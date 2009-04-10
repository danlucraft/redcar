
module Redcar    
  class SnippetCommand < Redcar::Command
    # range Redcar::EditView
    
    class << self
      attr_accessor :name, :content, :bundle, :tab_trigger
    end
    
    def execute
      tab.view.snippet_inserter.insert_snippet(self.class)
    end
  end
end
