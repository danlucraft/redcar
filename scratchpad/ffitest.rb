require 'ffi'

module Hello
 extend FFI::Library
attach_function 'puts', [ :string ], :int
end

Hello.puts("Hello, World")

