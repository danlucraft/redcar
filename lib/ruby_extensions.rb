
module Kernel
  alias fn lambda
end

class Object
  def meta_class
    class << self; self; end
  end
end

def ARGV.option(name)
  ARGV.map {|arg| arg =~/--#{name}=(.*)$/; $1}.compact.first
end