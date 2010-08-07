require 'net/ssh'
require 'net/sftp'

module Redcar
  class Project
    module Adapters
      module RemoteProtocols
        class SFTP < Protocol
          class << self
            def handle_error(e, host, user)
              return "Authentication failed for user #{user} in sftp://#{host}" if e.is_a?(Net::SSH::AuthenticationFailed)
            end
          end

          def connection
            @connection ||= Net::SSH.start(host, user, :password => password, :keys => private_key_files)
          rescue OpenSSL::PKey::DSAError => error
            puts "*** Warning, DSA keys not supported."
            # Error with DSA key. Throw us back to a password input. Think this is because jopenssl bugs
            # out on valid dsa keys.
            raise Net::SSH::AuthenticationFailed, "DSA key-based authentication failed."
          end
          
          def touch(file)
            exec "touch \"#{escape(file)}\""
          end

          def mkdir(new_dir_path)
            exec "mkdir -p \"#{escape(new_dir_path)}\""
          end

          def mv(path, new_path)
            exec "mv \"#{escape(path)}\" \"#{escape(new_path)}\""
          end
          
          def mtime(file)
            sftp_exec(:stat!, file).mtime
          end
          
          def download(remote, local)
            sftp_exec(:download!, remote, local)
          end
          
          def upload(local, remote)
            sftp_exec(:upload!, local, remote)
          end
          
          def delete(file)
            sftp_exec(:remove, file)
          end
          
          def dir_listing(path)
            return [] unless result = retrieve_dir_listing(path)
            contents = []
            result.each do |line|
              next unless line.include?('|')
              type, empty_flag, name = line.chomp.split('|')
              unless ['.', '..'].include?(name)
                hash = { :fullname => name, :name => File.basename(name), :type => type.to_sym }
                if type == "dir"
                  hash[:empty] = (empty_flag == "0")
                end
                contents << hash
              end
            end
            contents
          end
          
          def retrieve_dir_listing(path)
            raise Adapters::Remote::PathDoesNotExist, "Path #{path} does not exist" unless check_folder(path)

            exec %Q(
              for file in #{path}/*; do 
                test -f "$file" && echo "file|na|$file"
                test -d "$file" && test $(find $file -maxdepth 1 | wc -l) == 1 && echo "dir|0|$file"
                test -d "$file" && test $(find $file -maxdepth 1 | wc -l) > 1 && echo "dir|1|$file"
              done
            )
          end
          
          def is_folder(path)
            result = exec(%Q(
              test -d "#{path}" && echo y
            )) 

            result =~ /^y/ ? true : false
          end
          
          private
          
          def escape(path)
            path.gsub("\\", "\\\\").gsub("\"", "\\\"")
          end
          
          def exec(what)
            puts "exec: #{what.inspect}"
            begin
              Redcar.timeout(10) do
                connection.exec!(what)
              end
            rescue Redcar::TimeoutError => e
              puts "#{host} connection timed out"
              puts caller
              raise "#{host} connection timed out"
            end
          end
          
          def sftp_exec(method, *args)
            puts "sftp_exec: #{method}, #{args.inspect}"
            begin
              Redcar.timeout(10) do
                connection.sftp.send(method, *args)
              end
            rescue Redcar::TimeoutError
              raise "#{host} connection timed out"
            end
          end
        end
      end
    end
  end
end
