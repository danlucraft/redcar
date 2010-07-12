require 'net/ssh'
require 'net/sftp'

module Redcar
  class Project
    module Adapters
      class Remote
        class PathDoesNotExist < StandardError; end
        
        PROTOCOLS = {
          :ftp  => RemoteProtocols::FTP,
          :sftp => RemoteProtocols::SFTP
        }
          
        class << self
          attr_accessor :connections
          
          def resolve(protocol, host, user, password, path)
            protocol_class = PROTOCOLS[protocol]
            
            self.connections||={}
            self.connections["#{protocol}-#{host}-#{user}"] ||= protocol_class.new(host, user, password, path)
          end
        end
        
        attr_accessor :path, :protocol, :host, :user, :password

        def initialize(protocol, host, user, password)
          @protocol = protocol
          @host = host
          @user = user
          @password = password
        end
        
        def target
          self.class.resolve(protocol, host, user, password, path)
        end
        
        def real_path
          path
        end
        
        def exist?
          target.exist?
        end
        
        def mtime(file)
          target.mtime(file)
        end

        def file?(path)
          target.file?(path)
        end
        
        def directory?(path=path)
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

        def exists?(path)
          target.exists?(path)
        end
        
        def load(file)
          target.load(file)
        end
        
        def save(file, contents)
          target.save(file, contents)
        end
      end
    end
  end
end