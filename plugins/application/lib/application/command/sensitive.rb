module Redcar
  class Command
    # Include this module in your classes to make them sensitive to 
    # changes in the value of Sensitivities.
    #
    # For instance:
    #
    #   class MySensitiveClass
    #     include Redcar::Command::Sensitive
    #     sensitize :is_tuesday
    #   end
    # 
    # Where :is_tuesday is the name of a Redcar::Command::Sensitivity.
    # Then:
    #
    #   myobj = MySensitiveClass.new
    #   myobj.active? #=> true
    #   # day changes to wednesday
    #   myobj.active? #=> false
    #
    module Sensitive
      module ClassMethods
        def sensitize(*symbols)
          @sensitivity_names = symbols
        end
        
        def sensitivity_names
          (@sensitivity_names || []) + begin
            parent = self.superclass
            if parent.ancestors.include?(Redcar::Command::Sensitive)
              parent.sensitivity_names
            else
              []
            end
          end
        end
        
        def sensitivities
          sensitivity_names.map {|name| Sensitivity.get(name) }
        end
      end
      
      def self.included(klass)
        klass.send(:extend, ClassMethods)
      end
      
      # Whether all the sensitivities of this object are active.
      def active?
        sensitivities.all? {|s| s.active? }
      end
      
      # Use this to run a block only when the value of active? changes.
      def on_active_changed(&block)
        @current_sensitivity = active?
        sensitivities.each do |s|
          s.add_listener(:changed) do
            old_sensitivity = @current_sensitivity
            @current_sensitivity = active?
            if old_sensitivity != @current_sensitivity
              block.call
            end
          end
        end
      end
      
      private
      
      def sensitivities
        self.class.sensitivities
      end
    end
  end
end
