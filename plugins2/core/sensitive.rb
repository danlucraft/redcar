module Redcar
  module Sensitive
    extend FreeBASE::StandardPlugin
    
    def self.setup_objects
      @blocks  ||= {}
      @hooks   ||= {}
      @objects ||= {}
      @value   ||= {}
    end
    
    def self.register(name, hooks, &block)
      setup_objects
      @blocks[name] = block
      (hooks - @hooks.keys).each do |hook|
        Hook.attach(hook) do
          Redcar::Sensitive.check_hook(hook)
        end
      end
      hooks.each do |hook|
        @hooks[hook] ||= []
        @hooks[hook] << name unless @hooks[hook].include? name
      end
      @value[name] = block.call
    end
    
    def self.check_hook(hook)
      setup_objects
      @hooks[hook].each do |name|
        val = @blocks[name].call
        if val != @value[name]
          @value[name] = val
          @objects[name].each do |obj|
            obj.active = val
          end
        end
      end
    end
    
    def self.sensitize(obj, name)
      setup_objects
      unless @blocks.include? name
        raise "Trying to sensitize to unknown Sensitivity: #{name}."
      end
      obj.active = @value[name].to_bool
      @objects[name] ||= []
      @objects[name] << obj
    end
    
    def self.desensitize(obj)
      setup_objects
      @objects.values.each do |arr|
        arr.delete obj
      end
    end
    
    def active=(val)
      @sensitive_active = val
    end
    
    def active?
      @sensitive_active == nil ? true : @sensitive_active
    end
  end
end

