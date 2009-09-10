
module Redcar
  class Application
    class Window
      class << self
        def all
          # All instantiated windows
          def all
            @all ||= []
          end
        end
        
        def initialize
          Window.all << self
        end
      end
    end
  end
end
