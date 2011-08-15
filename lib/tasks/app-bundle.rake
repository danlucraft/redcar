desc "Build a MacOS X App bundle"
task :app_bundle do
  require 'erb'

  redcar_icon = "redcar-icon-beta.png"

  bundle_contents = File.join("pkg", "Redcar.app", "Contents")
  FileUtils.rm_rf bundle_contents if File.exist? bundle_contents
  macos_dir = File.join(bundle_contents, "MacOS")
  resources_dir = File.join(bundle_contents, "Resources")
  FileUtils.mkdir_p macos_dir
  FileUtils.mkdir_p resources_dir

  info_plist_template = ERB.new <<-PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>redcar</string>
	<key>CFBundleIconFile</key>
	<string><%= redcar_icon %></string>
	<key>CFBundleIdentifier</key>
	<string>com.redcareditor.Redcar</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string><%= Spec.version %></string>
	<key>LSMinimumSystemVersion</key>
	<string>10.5</string>
</dict>
</plist>
  PLIST
  File.open(File.join(bundle_contents, "Info.plist"), "w") do |f|
    f << info_plist_template.result(binding)
  end

  File.open(File.join(macos_dir, "redcar"), "w") do |f|
    f << '#!/bin/sh
          MACOS=$(cd "$(dirname "$0")"; pwd)
          RESOURCES="$(cd "${MACOS}/../Resources/"; pwd)"
          BIN="${RESOURCES}/bin/redcar"
          JRUBY="${RESOURCES}/.redcar/assets/jruby-complete-*.jar"
          java -cp $JRUBY -Djruby.fork.enabled=true org.jruby.Main "$BIN" --home-dir="${RESOURCES}" --ignore-stdin $@'
  end
  File.chmod 0777, File.join(macos_dir, "redcar")

  Spec.files.each do |f|
    unless File.directory?(f)
      FileUtils.mkdir_p File.join(resources_dir, File.dirname(f))
      FileUtils.cp f, File.join(resources_dir, f)
    end
  end

  FileUtils.cp_r File.join(resources_dir, "share", "icons", redcar_icon), resources_dir

  puts(install_cmd = "#{File.expand_path("../../bin/redcar", __FILE__)} --home-dir=#{resources_dir} install")
  system(install_cmd)
end
