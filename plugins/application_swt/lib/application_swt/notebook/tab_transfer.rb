module Redcar
  class ApplicationSWT
    class Notebook
      class TabTransfer < Swt::DND::ByteArrayTransfer
        
        class TabType
          # Empty class for now, until we figure out which
          # information we want to attach to the transfer.
          # This _will_ be needed to DnD tabs between windows
        end
        
        TAB_TYPE = "TabType"
        TAB_TYPE_ID = register_type(TAB_TYPE)
        @@instance = nil
        
        def self.get_instance
          @@instance || TabTransfer.new
        end
        
        def javaToNative(types, transfer_data)
          return if (types.nil? || types.empty? || (types.first.class != TabType))
          
          begin
            # write data to a byte array and then ask super to convert to
            out = java.io.ByteArrayOutputStream.new
            write_out = java.io.DataOutputStream.new(out)
            types.length.times do |i|
              buffer = TAB_TYPE.to_java_bytes
              write_out.write_int(buffer.length)
              write_out.write(buffer)
            end
            buffer = out.to_byte_array
            write_out.close
            super(buffer, transfer_data)
          rescue java.io.IOException => e
          end
        end
        
        def nativeToJava(transfer_data)
          if (is_supported_type(transfer_data))
            buffer = super
            return nil unless buffer
            
            data = []
            begin
              input = java.io.ByteArrayInputStream.new(buffer)
              read_in = java.io.DataInputStream.new(input)
              while (read_in.available > 20) do
                datum = TabType.new
                int size = read_in.read_int
                name = Java::byte[size].new
                read_in.read(name)
                tab_type_name = String.from_java_bytes(name);
                data << datum
              end
              read_in.close
            rescue java.io.IOException => e
              return null;
            end
            return data.to_java
          end
          return nil
        end
        
        def get_type_names
          [TAB_TYPE].to_java(:string)
        end
        
        def get_type_ids
          [TAB_TYPE_ID].to_java(:int)
        end
        
        def getTypeIds
          get_type_ids
        end
        
        def getTypeNames
          get_type_names
        end
      end
    end
  end
end
