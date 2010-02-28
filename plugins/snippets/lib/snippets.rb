
require 'snippets/document_controller'
require 'snippets/tab_handler'

module Redcar
  class Snippets
    
    def self.tab_handlers
      [Snippets::TabHandler]
    end
    
    def self.document_controller_types
      [Snippets::DocumentController]
    end
    
    def self.registry
      @registry ||= begin
        registry = Registry.new
        s = Time.now
        tm_snippets = Textmate.all_bundles.map {|b| b.snippets}.flatten 
        puts "took #{Time.now - s}s to load snippets"
        registry.add(tm_snippets)
        registry
      end
    end
    
    class Registry
      attr_reader :snippets
    
      def initialize
        @snippets = []
      end
      
      def add(s)
        if s.is_a?(Array)
          @snippets += s
        else
          @snippets << s
        end
        @global = nil
      end
      
      def remove(s)
        @snippets.delete(s)
        @global = nil
      end
      
      def global
        @global ||= @snippets.select {|s| [nil, ""].include?(s.scope) }
      end
      
      def global_with_tab(tab_trigger)
        global.select {|s| s.tab_trigger == tab_trigger}
      end
      
      def find_by_scope_and_tab_trigger(current_scope, tab_trigger)
        matches_tab = @snippets.select {|s| s.tab_trigger == tab_trigger}
        matches = matches_tab.map do |snippet|
          next unless snippet.scope
          if match = JavaMateView::ScopeMatcher.get_match(snippet.scope, current_scope)
            [match, snippet]
          end
        end
        matches = matches.compact
        best_match = matches.sort { |a, b|
          JavaMateView::ScopeMatcher.compare_match(current_scope, a[0], b[0])
        }.last
        if best_match
          best_match.last
        end
      end
    end
    
    class Snippet
      attr_reader :name
      attr_reader :content
    
      def initialize(name, content, options=nil)
        @name = name
        @content = content
        @options = options || {}
      end
      
      def tab_trigger
        @options[:tab]
      end
      
      def scope
        @options[:scope]
      end
      
      def key
        @options[:key]
      end
    end
  end
end