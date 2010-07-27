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
            if @connection
              begin
                @connection.exec! 'pwd'
              rescue
                @connection = nil
              end
            end
            @connection ||= Net::SSH.start(host, user, :password => password, :keys => private_key_files)
          end
          
          def touch(file)
            connection.exec "touch #{file}"
          end

          def mkdir(new_dir_path)
            connection.exec "mkdir -p #{new_dir_path}"
          end

          def mv(path, new_path)
            connection.exec "mv #{path} #{new_path}"
          end
          
          def mtime(file)
            connection.sftp.stat!(file).mtime
          end
          
          def download(remote, local)
            connection.sftp.download! remote, local
          end
          
          def upload(local, remote)
            connection.sftp.upload! local, remote
          end
          
          def dir_listing(path)
            return [] unless result = retrieve_dir_listing(path) rescue []

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
          
          def exec(what)
            connection.exec!(what)
          end

          def is_folder(path)
            result = exec(%Q(
              test -d "#{path}" && echo y
            )) 

            result =~ /^y/ ? true : false
          end
        end
      end
    end
  end
end