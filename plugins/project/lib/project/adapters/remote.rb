
module Redcar
  class Project
    module Adapters
      class Remote
        class PathDoesNotExist < StandardError; end
        
        PROTOCOLS = {
          :ftp  => RemoteProtocols::FTP,
          :sftp => RemoteProtocols::SFTP
        }
          
        attr_accessor :protocol, :host, :user, :password, :private_key_files
        
        def initialize(protocol, host, user, password, private_key_files)
          @protocol = protocol
          @host = host
          @user = user
          @password = password
          @private_key_files = private_key_files
          target
        end
        
        def target
          @target ||= PROTOCOLS[protocol].new(host, user, password, private_key_files)
        end

        def touch(file)
          target.touch(file)
        end

        def mkdir(new_dir_path)
          target.mkdir(new_dir_path)
        end

        def mv(path, new_path)
          target.mv(path, new_path)
        end
        
        def mtime(file)
          target.mtime(file)
        end

        def file?(path)
          target.file?(path)
        end
        
        def directory?(path)
          target.directory?(path)
        end
        
        def fetch_contents(path)
          target.fetch_contents(path)
        end

        def load(file)
          target.load(file)
        end

        def save(file, contents)
          target.save(file)
        end
        
        def stat(file)
          target.stat(file)
        end
        
        def delete(file)
          target.delete(file)
        end

        def exists?(path)
          target.exists?(path)
        end
        
        def load(file)
          target.load(file)
        end
        
        def save(file, contents)
          target.save(file, contents)
        end
        
        def refresh_operation(tree)
          visible_paths = tree.visible_nodes.map {|n| n.path}
          visible_dirs = visible_paths.map {|path| File.dirname(path) }.uniq
          target.with_cached_directories(visible_dirs) do
            yield
          end
        end
      end
    end
  end
end