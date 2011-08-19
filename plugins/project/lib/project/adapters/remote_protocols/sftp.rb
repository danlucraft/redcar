
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
            gem "net-ssh"
            gem "net-sftp"
            require 'net/ssh'
            require 'net/sftp'
            Redcar.timeout(10) do
              @connection ||= Net::SSH.start(host, user, :password => password, :keys => private_key_files)
            end
          rescue OpenSSL::PKey::DSAError => error
            puts "*** Warning, DSA keys not supported."
            # Error with DSA key. Throw us back to a password input. Think this is because jopenssl bugs
            # out on valid dsa keys.
            raise Net::SSH::AuthenticationFailed, "DSA key-based authentication failed."
          rescue Redcar::TimeoutError
            raise "connection to #{host} timed out"
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
          
          def use_cache?
            @use_cache
          end
          
          def dir_listing(path)
            if use_cache?
              if @cached_dirs[path]
                return @cached_dirs[path]
              end
            end
            
            return [] unless result = retrieve_dir_listing(path)
            process_dir_listing_response(result)
          end
          
          def retrieve_dir_listing(path)
            raise Adapters::Remote::PathDoesNotExist, "Path #{path} does not exist" unless check_folder(path)

            exec %Q(
              for file in #{path}/*; do 
                test -f "$file" && echo "file|na|$file"
                test -d "$file" && test $(find $file -maxdepth 1 | wc -l) -eq 1 && echo "dir|0|$file"
                test -d "$file" && test $(find $file -maxdepth 1 | wc -l) -gt 1 && echo "dir|1|$file"
              done
            )
          end
          
          def process_dir_listing_response(response)
            contents = []
            response.each do |line|
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
          
          def exists?(path)
            is_file(path) or is_folder(path)
          end
          
          def is_folder(path)
            result = exec(%Q(
              test -d "#{path}" && echo y
            )) 

            result =~ /^y/ ? true : false
          end
          
          def is_file(path)
            result = exec(%Q(
              test -f "#{path}" && echo y
            )) 

            result =~ /^y/ ? true : false
          end
          
          def with_cached_directories(dirs)
            @cached_dirs = list_dirs(dirs)
            @use_cache = true
            yield
          ensure
            @use_cache = false
          end
          
          def list_dirs(dirs)
            cmd = ""
            dirs.each do |dir|
              cmd << <<-SH
                for file in #{dir}/*; do 
                  test -f "$file" && echo "file|na|$file"
                  test -d "$file" && test $(find "$file" -maxdepth 1 | wc -l) -eq 1 && echo "dir|0|$file"
                  test -d "$file" && test $(find "$file" -maxdepth 1 | wc -l) -gt 1 && echo "dir|1|$file"
                done
              SH
            end
            response = exec(cmd)
            listings = process_dir_listing_response(response)
            hash = {}
            listings.each do |listing|
              (hash[File.dirname(listing[:fullname])] ||= []) << listing
            end
            hash
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
              connection.shutdown!
              raise "#{host} connection timed out"
            end
          end
          
          def sftp_exec(method, *args)
            begin
              Redcar.timeout(10) do
                connection.sftp.send(method, *args)
              end
            rescue Redcar::TimeoutError
              connection.shutdown!
              raise "#{host} connection timed out"
            end
          end
        end
      end
    end
  end
end
