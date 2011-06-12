
module Redcar
  class Project
    module Adapters
      module RemoteProtocols
        class FTP < Protocol
          class << self
            def handle_error(e, host, user)
              return "Authentication failed for user #{user} in ftp://#{host}" if e.is_a?(Net::FTPPermError)
            end
          end
          
          def connection
            require 'net/ftp'
            gem "net-ftp-list"
            require 'net/ftp/list'
            @connection ||= Net::FTP.open(host, user, password)
          end
          
          def touch(file)
            local_path, local_file = split_paths(file)

            FileUtils.mkdir_p local_path
            FileUtils.touch local_file

            upload local_file, file
          end

          def mkdir(new_dir_path)
            exec :mkdir, new_dir_path
          end

          def mv(path, new_path)
            target = "#{new_path}/#{File.basename(path)}"
            exec :rename, path, target
          end
          
          def mtime(file)
            if e = entry(file)
              e[:mtime]
            end
          end
          
          def download(remote, local)
            exec :get, remote, local
          end
          
          def upload(local, remote)
            exec :put, local, remote
          end

          def dir_listing(path)
            contents = []
            exec(:list, path) do |e|
              entry = Net::FTP::List.parse(e)
              name = entry.basename
              type = "unknown"
              type = "file" if entry.file?
              type = "dir" if entry.dir?
              
              unless ['.', '..'].include?(name)
                contents << { :fullname => "#{path}/#{name}", :name => "#{name}", :type => type, :mtime => entry.mtime }
              end
            end
            
            contents
          end
          
          def is_folder(path)
            exec(:chdir, path)
            exec(:pwd) == path
          end
          
          def with_cached_directories
            yield
          end
          
          private
          
          def exec(method, *args, &block)
            begin
              Redcar.timeout(10) do
                connection.send(method, *args, &block)
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