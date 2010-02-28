
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
      
      def global
        @global ||= @snippets.select {|s| [nil, ""].include?(s.scope) }
      end
      
      def global_with_tab(tab_trigger)
        global.select {|s| s.tab_trigger == tab_trigger}
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