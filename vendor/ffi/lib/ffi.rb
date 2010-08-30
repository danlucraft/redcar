require 'ffi/ffi'

# Patch any missing methods

module FFI
  class Pointer

    def write_pointer(ptr)
      put_pointer(0, ptr)
    end unless method_defined?(:write_pointer)

    def read_array_of_pointer(length)
      read_array_of_type(:pointer, :read_pointer, length)
    end unless method_defined?(:read_array_of_pointer)

    def write_array_of_pointer(ary)
      write_array_of_type(:pointer, :write_pointer, ary)
    end unless method_defined?(:write_array_of_pointer)

  end

  # Fix for RUBY-3527
  if JRUBY_VERSION >= "1.2.0" && JRUBY_VERSION < "1.3.0"
    module Library
      def ffi_lib(*names)
        ffi_libs = []
        names.each do |name|
          [ name, FFI.map_library_name(name) ].each do |libname|
            begin
              lib = FFI::DynamicLibrary.open(libname, FFI::DynamicLibrary::RTLD_LAZY | FFI::DynamicLibrary::RTLD_GLOBAL)
              if lib
                ffi_libs << lib
                break
              end
            rescue LoadError => ex
            end
          end
        end
        raise LoadError, "Could not open any of [#{names.join(", ")}]" if ffi_libs.empty?
        @ffi_libs = ffi_libs
      end
    end
  end
end
