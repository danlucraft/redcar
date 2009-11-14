
module Kernel
  alias fn lambda
end

class Object
  def meta_class
    class << self; self; end
  end
end
