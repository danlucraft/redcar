
module Redcar
  module HasSPI
    def assert_interface(object, interface)
      unless object.is_a?(interface)
        raise "#{object.inspect} expected to be a #{interface}"
      end
    end
  end
end