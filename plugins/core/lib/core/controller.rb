module Redcar
  module Controller
    attr_accessor :model
    
    def self.included(klass)
      klass.class_eval <<-RUBY
        def self.model_listeners
          @model_listeners ||= []
        end
      
        def self.model_listener(name)
          model_listeners << name
        end
        
        def create_model_listeners
          self.class.model_listeners.each do |name|
            @model.add_listener(name, &method(name))
          end
        end
      RUBY
    end
  end
end