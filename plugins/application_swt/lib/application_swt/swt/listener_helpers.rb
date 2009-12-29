module Redcar
  class ApplicationSWT
    module ListenerHelpers
      def ignore_within_self
        name = __calling_method__
        unless singly_hash[name]
          singly_hash[name] = true
          yield
          singly_hash.delete(name)
        end
      end
      
      private
      
      def singly_hash
        @singly_hash ||= {}
      end
    end
  end
end