$:.push File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')
require 'redcar'
Redcar.boot
Redcar.require_files
Dir[File.dirname(__FILE__) + "/application/controllers/*.rb"].each do |fn|
  require fn
end
  
