
desc "Build documentation (requires mislav-hanna gem)"
task :doc => plugin_names.map {|name| "rdoc:#{name}"} + ["doc:html"]

namespace :doc do
  desc "Build HTML documentation (needs python-sphinx and python-jinja2)"
  task :html do
  	execute_and_check "sphinx-build -b html doc/source doc/html"
  end
  
  desc "Build Latex documentation (needs python-sphinx, python-jinja2, texlive-latex-base and texlive-latex-extras)"
  task :latex do
   	execute_and_check "sphinx-build -b latex doc/source doc/latex"
  end
end

namespace :rdoc do
  # Generate feature tasks for each plugin.
  Dir["plugins/*"].each do |fn|
    name = fn.split("/").last
    desc "Generate docs for #{name} (requires mislav-hanna gem)"
    task name.intern do
      FileUtils.rm_rf "rdoc/#{name}"
      files = Dir["plugins/#{name}/**/*"].
                select{|f| File.file? f}.
                reject{|fn| fn.include?("commands/") or fn.include?("spec/") or fn.include?("tests/")}
      if name == "core"
        readme = "README.txt INSTALL.txt"
      else
        readme = Dir["plugins/#{name}/*"].find {|fn| fn =~ /readme/i}
      end
      sh "rdoc -o rdoc/#{name} --inline-source --format=html -T hanna #{files.join(" ")} #{readme}"
    end
  end
end
