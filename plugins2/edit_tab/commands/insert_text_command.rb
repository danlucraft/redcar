
module Redcar
  class InsertTextCommand < Redcar::EditTabCommand
    attr_accessor :text
    
    def initialize(text)
      @text = text
    end
    
    def execute
      doc.insert_at_cursor(text)
    end
    
    def merge_right(other_insert_command)
      @text += other_insert_command.text
    end
  end
end
