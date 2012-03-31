package test
import java.util.Map
import static java.util.Map

/**
 * @author Luke Daley
 */
class Test extends Object implements Serializable {
    
    static String s = null
    private n = -3459
    def l = [1,2,3]
    def c = [blah: new Integer(5), ghe: testMethod(false, "bah")]
    def p = /sdasd/
    def m = [key1: "value1", key2: "value2", (l): "value3"]

    Test(args) {
    	
    }

	def testMethod(arg1, String typed) {
        return 6
    }

	def methodName(args = String) {
		{ String asdasd = "asdasd", Integer xx = 2 -> }
	}
    
    static main(args) {
        def n = -234e12
        def t = true ? n : new Integer(1)
        assert t : "Failure message"
        def m = new HashMap(key1: "123", key2: "123")
        m?.equals key1: "123"
        thing.default.return // <-- don't scope keywords like default in this context

        
        switch(t) {
            case m:
                
            break
            case "CASE_NAME":
                
            break
            default:
                
            break
        }
        
        println "OK!"
    }
}

private class PrivateTest {
    
    

}

public enum Blah {
	THING1,
	THING2(1,3),
	THING3
}

	

