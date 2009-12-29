
module Kernel
  alias fn lambda
end

class Object
  def meta_class
    class << self; self; end
  end
  
  def __calling_method__
    caller[1][/`(.*)'$/, 1].to_sym
  end
end

def ARGV.option(name)
  ARGV.map {|arg| arg =~/--#{name}=(.*)$/; $1}.compact.first
end