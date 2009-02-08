
module Redcar    
  class SnippetCommand < Redcar::Command
    # range Redcar::EditView
    
    class << self
      attr_accessor :name, :content, :bundle
    end
  end
end
