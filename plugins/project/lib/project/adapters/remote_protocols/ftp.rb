require 'net/ftp'
require 'net/ftp/list'

module Redcar
  class Project
    module Adapters
      module RemoteProtocols
        class FTP < Protocol
          def connection
            @connection ||= Net::FTP.open(host, user, password)
          end
          
          def stat(file)
            connection.status(file)
          end
          
          def download(remote, local)
            connection.get remote, local
          end
          
          def upload(local, remote)
            connection.put local, remote
          end

          def dir_listing(path)
            result = []
            connection.list(path) do |e|
              entry = Net::FTP::List.parse(e)
              result << "dir|#{entry.basename}" if entry.dir?
              result << "file|#{entry.basename}" if entry.file?
            end
            result
          end
          
          def is_folder(path)
            connection.chdir(path)
            connection.pwd == path
          end
        end
      end
    end
  end
end