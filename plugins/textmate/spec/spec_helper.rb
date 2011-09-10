$:.push File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')
require 'redcar'
Redcar.environment = :test
Redcar.no_gui_mode!
Redcar.load_unthreaded

def fixtures
  @fixtures ||= []
end

def write_file name, extension, contents
  file = java.io.File.createTempFile(name,extension)
  File.open(file.path, 'w') {|f| f.puts(contents)}
  fixtures << file.path
  file
end

def write_temp_bundle name, plist
  temp = java.lang.System.get_property('java.io.tmpdir')
  temp_dir = File.join(temp,name+'.tmbundle')
  FileUtils.mkdir(temp_dir) unless File.exists? temp_dir
  File.open(File.join(temp_dir,'info.plist'), 'w') do |f|
    f.puts plist
  end
  fixtures << temp_dir
  temp_dir
end

def textmate_fixtures
  File.join File.dirname(__FILE__), "fixtures"
end

def plist_file
  File.join(textmate_fixtures,'plist.xml')
end

def fake_bundle
  File.join(textmate_fixtures, 'FakeBundle.tmbundle')
end

def snippet_dir
  File.join(fake_bundle, "Snippets")
end

def test_snippet
  File.join(snippet_dir, 'test.tmSnippet')
end

def create_fixtures
  FileUtils.mkdir(textmate_fixtures) unless File.exists?(textmate_fixtures)
  FileUtils.mkdir(fake_bundle)
  FileUtils.mkdir(snippet_dir)
  File.open(test_snippet, 'w') do |f|
    f.puts <<-SNIPPET
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>content</key>
	<string>smile</string>
	<key>name</key>
	<string>Happiness</string>
	<key>scope</key>
	<string>text.fake</string>
	<key>uuid</key>
	<string>6070C13D-A416-46DB-B0E9-C07553400E88</string>
</dict>
</plist>
    SNIPPET
  end

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
  File.open(File.join(fake_bundle,'info.plist'), 'w') do |f|
    f.puts <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
  	<key>contactEmailRot13</key>
  	<string>wbua@rknzcyr.pbz</string>
  	<key>contactName</key>
  	<string>John Doe</string>
  	<key>name</key>
  	<string>Fake Bundle</string>
  	<key>mainMenu</key>
  	<dict>
  		<key>items</key>
  		<array>
        <string>6070C13D-A416-46DB-B0E9-C07553400E88</string>
      </array>
    </dict>
    <key>uuid</key>
    <string>E1179E3E-9F7F-412D-8B9E-7390D1DC26D5</string>
  </dict>
</plist>
    XML
  end
end

def delete_fixtures
  FileUtils.rm_r(textmate_fixtures)
  fixtures.each {|p| FileUtils.rm_rf(p)}
  @fixtures = nil
end
