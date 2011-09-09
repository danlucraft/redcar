$:.push File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')
require 'redcar'
Redcar.environment = :test
Redcar.no_gui_mode!
Redcar.load_unthreaded

def textmate_fixtures
  File.join File.dirname(__FILE__), "fixtures"
end

def plist_file
  File.join(textmate_fixtures,'plist.xml')
end

def create_fixtures
  File.open(plist_file, 'w') do |f|
    f.puts <<-XML
      <plist>
        <dict>
          <key>fruit</key>
          <array>
            <string>apple</string>
            <string>orange</string>
            <string>pear</string>
          </array>
          <key>type</key>
          <string>food</string>
        </dict>
      </plist>
    XML
  end
end

def delete_fixtures
  File.delete(plist_file)
end