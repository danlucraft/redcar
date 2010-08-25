
module Redcar
  class Toolbar
    class Builder
      # An extension to the Builder to allow groups of toolbar object to inherit options.
      #
      # This is supported for all options, even options that don't exist yet!
      #
      # Currently, this is only useful in a practical sense to apply a :priority to a 
      # set of objects
      class Group
        
        def initialize(builder, options={}, &block)
          @builder = builder
          @defaults = options
          
          if block.arity == 1
            block.call(self)
          else
            instance_eval(&block)
          end
        end
        
        def item(text, options={}, &block)
          options = {:command => options} if not options.respond_to?('[]')
          @builder.item(text, @defaults.merge(options), &block)
        end
        
        def separator(options={})
          @builder.separator(@defaults.merge(options))
        end
        
        def sub_toolbar(text, options={}, &block)
          @builder.sub_toolbar(text, @defaults.merge(options), &block)
        end
        
        def lazy_sub_toolbar(text, options={}, &block)
          @builder.lazy_sub_toolbar(text, @defaults.merge(options), &block)
        end

        def append(item)
          @builder.append(item)
        end
      end
    end
  end
end
