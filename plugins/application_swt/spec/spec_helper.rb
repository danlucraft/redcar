$:.push File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')
require 'redcar'

unless Redcar.respond_to?(:gui)
  Redcar.load
  Redcar.gui = Redcar::ApplicationSWT.gui
end