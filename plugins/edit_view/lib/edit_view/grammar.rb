module Redcar
  class Grammar
    
    def initialize(doc)
      @doc = doc
      doc.edit_view.add_listener(:grammar_changed, &method(:change_grammar))
      Grammar.loaded_files ||= []
    end
      
    def change_grammar(name)
      grammar_name = Grammar.sanitize_grammar_name(name)
      Grammar.load_grammar
      if Grammar.const_defined?(grammar_name)
        grammar = Grammar.const_get(grammar_name)
      else
        grammar = Grammar.const_get(:Default)
      end
      self.extend grammar
    end
    
    def word_chars
      /\w|_/
    end
	
	class << self
      attr_accessor :loaded_files
      
      def load_grammar
        grammar_dir = File.expand_path(File.dirname(__FILE__) + "/grammars")
        Dir.new(grammar_dir).entries.reject {|item| item[-3..-1] != ".rb"}.each do |grammar|
          unless loaded_files.include? grammar
            if require grammar_dir + "/" + grammar.gsub(/".rb"/, "")
              loaded_files << grammar
            end
          end
        end
      end
    
      def sanitize_grammar_name(name)
        return name.strip.gsub("+", "Plus").gsub("#", "Sharp").gsub(/\W/, "").camelize
      end
    end
  end
end
