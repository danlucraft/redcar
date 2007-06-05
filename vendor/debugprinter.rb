
$debugging = {}

module DebugPrinter
  def self.included(klass)
    def klass.debug=(val)
      $debugging[self] = val
    end
    def klass.debug
      $debugging[self]
    end
  end
  
  def with_debugging
    pre = $debugging[self.class]
    $debugging[self.class] = true
    yield
    $debugging[self.class] = pre
  end
  
  def debug_puts(*args)
    if @debugging or $debugging[self.class]
      Kernel.puts *args
    end
  end
end

