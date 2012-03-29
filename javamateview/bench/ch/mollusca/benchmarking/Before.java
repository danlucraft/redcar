package ch.mollusca.benchmarking;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * This annotation marks methods that will be executed before any benchmark run.<br>
 * Use this for setup methods that need to be run before each test.
 * 
 * @author kungfoo
 * 
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Before {
	
}
