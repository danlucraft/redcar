package ch.mollusca.benchmarking;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * This annotation marks methods that will be executed after any benchmark run.<br>
 * Use this for setup methods that need to be run after each test.
 * 
 * @author kungfoo
 * 
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface After {

}
