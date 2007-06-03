
require "test/unit"

require File.dirname(__FILE__) + "/../lib/plist"

class TestPlist < Test::Unit::TestCase
  def setup
    @xml=<<END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>deleted</key>
	<array>
		<string>3988A501-119E-4C0E-A584-C5E75FC2D6C6</string>
	</array>
	<key>mainMenu</key>
	<dict>
		<key>excludedItems</key>
		<array>
			<string>E5158F94-CC52-4424-A495-14EF9272653F</string>
		</array>
		<key>items</key>
		<array>
			<string>35222962-C50D-4D58-A6AE-71E7AD980BE4</string>
			<string>------------------------------------</string>
			<string>63F3B3B7-CBE2-426B-B551-657733F3868B</string>
		</array>
		<key>submenus</key>
		<dict>
			<key>1BE427C6-0071-4BFF-8CDA-1DC13534E7D8</key>
			<dict>
				<key>items</key>
				<array>
					<string>931DD73E-615E-476E-9B0D-8341023AE730</string>
				</array>
				<key>name</key>
				<string>Format</string>
			</dict>
		</dict>
	</dict>
	<key>name</key>
	<string>Ruby</string>
	<key>ordering</key>
	<array>
		<string>FD010022-E0E7-44DB-827F-33F7D9310DA2</string>
		<string>AEDD6A5F-417F-4177-8589-B07518ACA9DE</string>
		<string>1A7701FA-D866-498C-AD4C-7846538DB535</string>
	</array>
	<key>uuid</key>
	<string>467B298F-6227-11D9-BFB1-000D93589AF6</string>
</dict>
</plist>
END
    @plist = [{
      "deleted" => ["3988A501-119E-4C0E-A584-C5E75FC2D6C6"],
      "mainMenu" => {
        "excludedItems" => ["E5158F94-CC52-4424-A495-14EF9272653F"],
        "items" => ["35222962-C50D-4D58-A6AE-71E7AD980BE4", 
                    "------------------------------------",
                    "63F3B3B7-CBE2-426B-B551-657733F3868B"],
        "submenus" => {
          "1BE427C6-0071-4BFF-8CDA-1DC13534E7D8" => {
            "items" => ["931DD73E-615E-476E-9B0D-8341023AE730"],
            "name" => "Format"
          }
        }
      },
      "name" => "Ruby",
      "ordering" => ["FD010022-E0E7-44DB-827F-33F7D9310DA2",
                     "AEDD6A5F-417F-4177-8589-B07518ACA9DE",
                     "1A7701FA-D866-498C-AD4C-7846538DB535"],
      "uuid" => "467B298F-6227-11D9-BFB1-000D93589AF6"
    }]
  end
  def test_plist_from_xml
    assert_equal @plist, Redcar::Plist.plist_from_xml(@xml)
  end
  def test_plist_to_xml
    assert_equal @xml.gsub(/\s/, ""), Redcar::Plist.plist_to_xml(@plist).gsub(/\s/, "")
  end
end
