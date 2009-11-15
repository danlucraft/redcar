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
      def sensitize(*sensitivity_names)
        @sensitivity_names ||= []
        @sensitivity_names += sensitivity_names
        sensitivity_names.each do |sensitivity_name|
          Sensitivity.add_listener(Sensitivity.event_name(sensitivity_name)) do
            old_sensitivity = @current_sensitivity
            @current_sensitivity = active?
            if old_sensitivity != @current_sensitivity
              @on_active_changed.call
            end
          end
        end
      end
      
      def sensitivity_names
        @sensitivity_names || []
      end
      
      def sensitivities
        sensitivity_names.map {|n| Sensitivity.get(n) }
      end
      
      # Whether all the sensitivities of this object are active.
      def active?
        sensitivities.all? {|s| s.active? }
      end
      
      # Use this to run a block only when the value of active? changes.
      def on_active_changed(&block)
        @on_active_changed = block
      end
    end
  end
end
