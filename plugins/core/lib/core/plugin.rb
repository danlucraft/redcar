
module Redcar
  class Plugin
    def self.call(obj, method, default, *args, &block)
      if obj.respond_to?(method)
        obj.send(method, *args, &block)
      else
        default
      end
    end
  end
end