require 'net/ssh'
require 'net/sftp'

module Redcar
  class Project
    module Adapters
      module RemoteProtocols
        class Protocol
          attr_accessor :path, :host, :user, :password, :private_key_files
          
          def initialize(host, user, password, private_key_files, path)
            @host     = host
            @user     = user
            @password = password
            @path     = path
            @cache    = {}
            @private_key_files = private_key_files
          end
          
          def exist?
            fetch(@path)
            true
          rescue Adapters::Remote::PathDoesNotExist
            false
          end
          
          def exists?(path)
            entry(path) ? true : false
          end
          
          def directory?(path=@path)
            return check_folder(path) if path == @path
            return false unless entry = entry(path)
            entry[:type] == 'dir'
          end
          
          def file?(path=@path)
            return false unless entry = entry(path)
            entry[:type] == 'file'
          end
          
          def exist?
            is_folder(@path)
          end
          
          def fetch_contents(path)
            fetch(path).map { |f| f[:fullname] }
          end
          
          def load(file)
            local_path, local_file = split_paths(file)

            print "Downloading: #{file} as: #{local_file}... "
            FileUtils.mkdir_p local_path
            download file, local_file
            puts "done"
            File.open(local_file, 'rb') do |f|; f.read; end
          end
          
          def save(file, contents)
            local_path, local_file = split_paths(file)

            ret = File.open(local_file, "wb") {|f| f.print contents }
            print "Uploading: #{local_file} as #{file}... "
            upload local_file, file
            puts "done"
            
            ret
          end

          private
          
          def cache(path)
            @cache[path]
          end

          def check_folder(path)
            parent = File.dirname(path)
            if contents = cache(parent)
              result = contents.find { |f| f[:fullname] == path }
              return false unless result
              result[:type] == 'dir'
            else
              is_folder(path)
            end
          end
          
          def split_paths(file)
            base_temp = '/tmp'
            file_name = File.basename(file)
            path = File.dirname(file)

            local_path = "#{base_temp}/#{host}#{path}"
            local_file = "#{local_path}/#{file_name}"

            [local_path, local_file]
          end

          def entry(file)
            path = File.dirname(file)
            contents = fetch(path)
            contents.find { |f| f[:fullname] == "#{file}" }
          end

          def fetch(path=@path)
            @cache[path] ||= dir_listing(path)
          end
        end
      end
    end
  end
end
