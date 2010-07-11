require 'net/ssh'
require 'net/sftp'

module Redcar
  class Project
    module Adapters
      class Remote
        class PathDoesNotExist < StandardError; end
          
        class << self
          attr_accessor :connections

          def init_connection(host, user, password)
            Net::SSH.start(host, user, :password => password)
          end
          
          def connect(host, user, password)
            self.connections||={}
            self.connections["#{host}-#{user}"] ||= init_connection(host, user, password)
          end
        end
        
        attr_accessor :path, :host, :user, :password

        def initialize(host, user, password)
          @host = host
          @user = user
          @password = password
          @cache = {}
        end
        
        def connection
          @connection ||= Remote.connect(@host, @user, @password)
        end
        
        def exec(what)
          connection.exec!(what)
        end
        
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
            result = exec(%Q(
              test -d "#{path}" && echo y
            )) 
          
            result =~ /^y/ ? true : false
          end
        end
        
        def dir_listing(path)
          raise PathDoesNotExist, "Path #{path} does not exist" unless check_folder(path)
          
          exec %Q(
            for file in #{path}/*; do 
              test -f "$file" && echo "file|$file"
              test -d "$file" && echo "dir|$file"
            done
          )
        end
        
        def retrieve_dir_contents(path=@path)
          return [] unless result = dir_listing(path) rescue []
          
          contents = []
          result.each do |line|
            type, name = line.chomp.split('|')
            unless ['.', '..'].include?(name)
              contents << { :fullname => "#{name}", :name => File.basename(name), :type => type }
            end
          end

          contents
        end
        
        def fetch(path=@path)
          @cache[path] ||= retrieve_dir_contents(path)
        end
        
        def fetch_contents(path)
          fetch(path).map { |f| f[:fullname] }
        end
        
        def real_path
          path
        end
        
        def exists?(path)
          begin
            if entry(path)
              true
            else
              false
            end
          rescue PathDoesNotExist
            false
          end
        end
        
        def exist?
          fetch(@path)
          true
        rescue PathDoesNotExist
          false
        end
        
        def entry(file)
          path = File.dirname(file)
          contents = fetch(path)
          contents.find { |f| f[:fullname] == "#{file}" }
        end
        
        def file?(path=@path)
          return false unless entry = entry(path)
          entry[:type] == 'file'
        end
        
        def directory?(path=@path)
          puts ":: Remote#directory? #{path}"
          return check_folder(path) if path == @path
          return false unless entry = entry(path)
          entry[:type] == 'dir'
        end
        
        def split_paths(file)
          base_temp = '/tmp'
          file_name = File.basename(file)
          path = File.dirname(file)
          
          local_path = "#{base_temp}/#{host}#{path}"
          local_file = "#{local_path}/#{file_name}"
          
          [local_path, local_file]
        end
        
        def stat(file)
          connection.sftp.stat!(file)
        end
   
        def load(file)
          local_path, local_file = split_paths(file)

          print "Downloading: #{file} as: #{local_file}... "
          FileUtils.mkdir_p local_path
          connection.sftp.download! file, local_file
          puts "done"
          File.open(local_file, 'rb') do |f|; f.read; end
        end
        
        def save(file, contents)
          local_path, local_file = split_paths(file)
          
          ret = File.open(local_file, "wb") {|f| f.print contents }
          print "Uploading: #{local_file} as #{file}... "
          connection.sftp.upload! local_file, file
          puts "done"
          ret
        end
      end
    end
  end
end