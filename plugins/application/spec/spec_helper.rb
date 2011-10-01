
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

Redcar.plugin_manager.load("application")