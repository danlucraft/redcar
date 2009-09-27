
module Redcar    
  class SnippetCommand
    include Redcar::Sensitive
    include Redcar::CommandActivation
    
    attr_accessor(:name, :content, :bundle, :tab_trigger, :key, 
                  :range, :scope, :menu, :menu_item, :tm_uuid)
    
    def range=(val)
      @range = val
      Range.register_command(val, self)
      update_operative
    end
    
    def new
      Instance.new(self)
    end
    
    def child_commands
      []
    end
    
    def inspect
      "#<SnippetCommand: #{@name}>"
    end
    
    def get(iv)
      instance_variable_get(:"@#{iv.to_s}")
    end
    
    class Instance
      def initialize(snippet_command)
        @snippet_command = snippet_command
      end
      
      def input_type
        nil
      end
      
      def fallback_input_type
        nil
      end
      
      def output_type
        nil
      end
      
      def pass?
        false
      end
      
      def record?
        true
      end
      
      def do(opts={})
        @executor = Executor.new(self, opts)
        @executor.execute
      end
      
      def execute
        @executor.view.snippet_inserter.insert_snippet(@snippet_command)
      end
    end
  end
end
