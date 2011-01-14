$:.push File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')
require 'redcar'
Redcar.environment = :test
Redcar.no_gui_mode!
Redcar.load_unthreaded
Dir[File.dirname(__FILE__) + "/application/controllers/*.rb"].each do |fn|
  require fn
end

class MockTree
  attr_reader :title

  def initialize(title)
    @title = title
  end

  def focus; end
end