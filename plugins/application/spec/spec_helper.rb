$:.push File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')
require 'redcar'

unless Redcar.respond_to?(:gui)
  Redcar.load
  Redcar.gui = Redcar::ApplicationSWT.gui
  Dir[File.dirname(__FILE__) + "/application/controllers/*.rb"].each do |fn|
    require fn
  end
end  