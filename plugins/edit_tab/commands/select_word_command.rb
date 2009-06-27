module Redcar
  class SelectWordCommand < Redcar::EditTabCommand
    key "Super+W"
    
    def execute
      start = doc.cursor_iter
      finish = doc.cursor_iter

      unless start.inside_word? or start.starts_word? or start.ends_word?
        return 
      end
      
      start.backward_word_start unless start.starts_word?
      finish.forward_word_end unless finish.ends_word?
      
      doc.select(start, finish)  
    end
  end
end
