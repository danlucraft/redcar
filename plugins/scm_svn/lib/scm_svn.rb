$:.push(
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor svn_wc lib})),
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor subversion lib}))
)
begin
  require "svn_wc"
  require "svn/repos"
rescue
  puts "Subversion bindings not found"
end

module Redcar
  module Scm
    module Subversion
      class Manager
        include Redcar::Scm::Model
        include Svn

        def repository_type
          "subversion"
        end

        def self.scm_module
          Redcar::Scm::Subversion::Manager
        end

        def self.supported?
          puts "    Subversion support is currently in progress" if debug
          true
        end

        def load(path)
          @cache = {}
          @path = path if repository?(path)
        end

        def repository?(path)
          File.exist?(File.join(path, %w{.svn}))
        end

        def refresh
          @cache = {}
        end

        def supported_commands
          [:pull, :init]
        end

        def init!(path)
          if not repository?(path)
            Svn::Repos.create(path)
          end
        end

        # Whether to print debugging messages. Default to whatever scm is using.
        def self.debug
          Redcar::Scm::Manager.debug
        end

        def debug
          Redcar::Scm::Subversion::Manager.debug
        end
      end
    end
  end
end

