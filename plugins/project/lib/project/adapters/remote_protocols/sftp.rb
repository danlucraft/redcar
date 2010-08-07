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
            exec "touch #{file}"
          end

          def mkdir(new_dir_path)
            exec "mkdir -p #{new_dir_path}"
          end

          def mv(path, new_path)
            exec "mv #{path} #{new_path}"
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
          
          def dir_listing(path)
            return [] unless result = retrieve_dir_listing(path)

            contents = []
            result.each do |line|
              next unless line.include?('|')
              type, name = line.chomp.split('|')
              unless ['.', '..'].include?(name)
                contents << { :fullname => "#{name}", :name => File.basename(name), :type => type }
              end
            end

            contents
          end
          
          def retrieve_dir_listing(path)
            raise Adapters::Remote::PathDoesNotExist, "Path #{path} does not exist" unless check_folder(path)

            exec %Q(
              for file in #{path}/*; do 
                test -f "$file" && echo "file|$file"
                test -d "$file" && echo "dir|$file"
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
          
          def exec(what)
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
