
$:.push(
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor grit lib})),
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor mime-types lib}))
)

require 'grit'

module Redcar
  module SCM
    module Git
      class Manager

      end
    end
  end
end
