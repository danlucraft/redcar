
module Redcar    
  class SnippetCommand < Redcar::Command
    # range Redcar::EditView
    
    class << self
      attr_accessor :name, :content, :bundle, :tab_trigger
    end
  end
end
