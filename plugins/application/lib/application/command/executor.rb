
module Redcar
  class Command
    class Executor
      
      attr_reader :options, :command_instance
      
      def self.current_environment
        if Redcar.app
          win = Redcar.app.focussed_window        
          tab = Redcar.app.focussed_notebook_tab
          { :win => win,
            :tab => tab }
        end
      end
      
      def initialize(command_instance, options={})
        @command_instance = command_instance
        @options          = options
      end
      
      def execute
        set_environment
        begin
          if not @options.empty?
            result = @command_instance.execute(@options) 
          else
            result = @command_instance.execute
          end
          finish
          clear_environment
        rescue Object => e
          set_error(e)
          print_command_error(e)
        rescue java.lang.StackOverflowError => e
          set_error(e)
          print_command_error(e)
        end
        record
        result
      ensure
        clear_environment
      end
      
      private
      
      def set_environment
        env = Executor.current_environment || {}
        env = env.merge(options.delete(:env) || {})
        @command_instance.environment(env)
      end
      
      def clear_environment
        @command_instance.environment(nil)
      end
      
      def set_error(e)
        @command_instance.error = e
      end
      
      def finish
        if @command_instance.respond_to?(:_finished)
          @command_instance._finished
        end
      end

      def print_command_error(e)
        puts "Error in command #{@command_instance.class}"
        puts e.class.to_s + ": " + e.message.to_s
        puts e.backtrace
      end
      
      def record
        if Redcar.app.andand.history
          Redcar.app.history.record(@command_instance)
        end
      end
    end
  end
end
