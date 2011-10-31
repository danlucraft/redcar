puts "loading edit_view env.rb"

require File.expand_path("../../../../application/features/support/env", __FILE__)

module SwtTabHelpers
  def hide_toolbar
    Redcar.app.show_toolbar = false
    Redcar.app.refresh_toolbar!
  end
end
