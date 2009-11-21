module Redcar
  # Sensitive abstracts the concept of an object having an enabled/disabled
  # property that is 'sensitive' to whether a number of other things
  # are true. The "things that can be true" are Redcar::Sensitivitys,
  # and the disabled, enabled property is only enabled when all the 
  # Sensitivitys are active.
  #
  # For instance, if :is_tuesday is the name of a 
  # Redcar::Sensitivity that is only active when it is Tuesday, 
  # you can make an object sensitive to whether it is Tuesday by including
  # this module and sensitizing the instance.
  #
  #   class MySensitiveClass
  #     include Redcar::Sensitive
  #   end
  #
  #   obj = MySensitiveClass.new
  #   obj.sensitize :is_tuesday
  #   obj.active?  # => true|false
  module Sensitive
    # Sensitize the object to a list of sensitivities. May be called with
    # multiple sensitivities multiple times.
    #
    #    obj.sensitize :is_tuesday, :raining
    #    obj.sensitize :month_has_y
    #
    # @param [Array<Symbol>] list of sensitivity_names
    def sensitize(*sensitivity_names)
      @sensitivity_names ||= []
      @sensitivity_names += sensitivity_names
      sensitivity_names.each do |sensitivity_name|
        Sensitivity.add_listener(Sensitivity.event_name(sensitivity_name)) do
          old_sensitivity = @current_sensitivity
          @current_sensitivity = active?
          if old_sensitivity != @current_sensitivity
            active_changed(@current_sensitivity)
          end
        end
      end
    end
    
    # @return [Array<Symbol>] list of senstivity names
    def sensitivity_names
      @sensitivity_names || []
    end
    
    # @return [Array<Sensitivity>] list of senstivitys
    def sensitivities
      sensitivity_names.map {|n| Sensitivity.get(n) }.compact
    end
    
    # Whether all the sensitivities of this object are active.
    def active?
      sensitivities.all? {|s| s.active? }
    end
  end
end
