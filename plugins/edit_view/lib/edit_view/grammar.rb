module Redcar
  class Grammar
    
    def initialize(doc)
      @doc = doc
      doc.edit_view.add_listener(:grammar_changed, &method(:change_grammar))
      Grammar.loaded_files ||= []
    end
      
    def change_grammar(name)
      grammar_name = singleton.sanitize_grammar_name(name)
      Grammar.load_grammar
      if Grammar.const_defined?(grammar_name)
        grammar = Grammar.const_get(grammar_name)
      else
        grammar = Grammar.const_get(:Default)
      end
      grammar.instance_methods.each do |method|
        singleton.send(:undef_method, method)
        singleton.send(:define_method, method, grammar.instance_method(method))
      end
      self.extend grammar
      puts word_chars
    end
    
    def word_chars
      /\w|_/
    end
    
    def singleton
      class << self; self; end
    end
	
	  class << self
      attr_accessor :loaded_files
      
      def load_grammar
        grammar_dir = File.expand_path(File.dirname(__FILE__) + "/grammars")
        Dir.new(grammar_dir).entries.reject {|item| item[-3..-1] != ".rb"}.each do |grammar|
          unless loaded_files.include? grammar
            if require grammar_dir + "/" + grammar[0..-4]
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
