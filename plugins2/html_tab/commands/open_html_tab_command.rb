
module Redcar
  class OpenHtmlTabCommand < Redcar::Command
    menu "Debug/Test HTML Tab"
    output :show_as_html
    
    def execute
      "<h1>Hi MOO</h1>"
    end
  end
end
