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
    
    return classpath.toArray()
