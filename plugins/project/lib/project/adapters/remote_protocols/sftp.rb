require 'net/ssh'
require 'net/sftp'

module Redcar
  class Project
    module Adapters
      module RemoteProtocols
        class SFTP < Protocol
          def connection
            @connection ||= Net::SSH.start(host, user, :password => password)
          end
          
          def stat(file)
            connection.sftp.stat!(file)
          end
          
          def download(remote, local)
            connection.sftp.download! remote, local
          end
          
          def upload(local, remote)
            connection.sftp.upload! local, remote
          end
          
          def dir_listing(path)
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