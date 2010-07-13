require 'net/ftp'
require 'net/ftp/list'

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
            @connection = nil if @connection and @connection.closed?
            
            if @connection
              begin
                @connection.noop
              rescue Net::FTPTempError
                puts "Error: #{$!.message}"
                @connection = nil
              end
            end
            
            @connection ||= Net::FTP.open(host, user, password)
          end
          
          def touch(file)
            local_path, local_file = split_paths(file)

            puts "Creating: #{file} as: #{local_file}... "
            FileUtils.mkdir_p local_path
            FileUtils.touch local_file

            print "Uploading: #{local_file} as #{file}... "
            upload local_file, file
            puts "done"
          end

          def mkdir(new_dir_path)
            connection.mkdir new_dir_path
          end

          def mv(path, new_path)
            target = "#{new_path}/#{File.basename(path)}"
            puts "Renaming: #{path} To: #{target}"
            connection.rename path, target
          end
          
          def mtime(file)
            if e = entry(file)
              e[:mtime]
            end
          end
          
          def download(remote, local)
            connection.get remote, local
          end
          
          def upload(local, remote)
            connection.put local, remote
          end

          def dir_listing(path)
            contents = []
            connection.list(path) do |e|
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
            connection.chdir(path)
            connection.pwd == path
          end
        end
      end
    end
  end
end