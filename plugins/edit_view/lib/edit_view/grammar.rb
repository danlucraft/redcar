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
        grammar_klass = Grammar.const_get(grammar_name)
      else
        grammar_klass = Grammar.const_get(:Default)
      end
      @grammar = grammar_klass.instance
    end

    def word
      # No Grammar loaded, but apparently some kind of document present
      change_grammar(@doc.edit_view.grammar)
      @grammar.word
    end

    def singleton
      class << self; self; end
    end

    class << self
      attr_accessor :loaded_files

      def load_grammar
        grammar_dir = File.expand_path(File.dirname(__FILE__) + "/grammars")
        Dir.new(grammar_dir).entries.reject {|item| item[-3..-1] != ".rb"}.sort.each do |grammar|
          unless loaded_files.include? grammar
            if require grammar_dir + "/" + grammar[0..-4]
              loaded_files << grammar
            end
          end
        end
      end

      def sanitize_grammar_name(name)
        name.strip.gsub("+", "Plus").gsub("#", "Sharp").split(" ").map do |word|
          word.camelize
        end.join.gsub(/\W/, "")
      end
    end
  end
end
