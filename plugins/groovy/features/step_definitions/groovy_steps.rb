When /^I add "([^"]*)" to the "([^"]*)" classpath$/ do |dir,plugin|
  File.open(File.expand_path("plugins/#{plugin}/features/fixtures/.redcar/classpath.groovy"), "a") do |f|
    f.puts <<-CONFIG
    def redcar_config = new File(getClass().protectionDomain.codeSource.location.path).parentFile
    def project       = redcar_config.parentFile
    def classpath     = []

    //installed libraries
    def lib = new File(project.path + File.separator + "lib")
    lib.list().each {name -> classpath << lib.path+File.separator+name}

    //compiled classes
    def target_classes = new File(
    	project.path + File.separator +
    	"target"     + File.separator +
    	"classes"
    )

    classpath << target_classes.path

    //other classes
    classpath << project.path + File.separator + "#{dir}"

    return classpath.toArray()
    CONFIG
  end
end