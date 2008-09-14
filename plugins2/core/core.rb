
# load 'lib/app.rb'
# load 'lib/command.rb'
# load 'lib/dialog.rb'
# load 'lib/document.rb'
load File.dirname(__FILE__) + '/lib/sensitive.rb'

Dir[File.dirname(__FILE__) + "/lib/*"].each {|fn| load fn}

module Redcar
  class CorePlugin < Redcar::Plugin
  end
end
