package ch.mollusca.benchmarking;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Annotation marking methods that will be executed once for each class that
 * contains Benchmark annotations.<br>
 * Use for methods that only need to be run once and that are quite costly, i.e.
 * setting up a huge array, connecting to a database
 * 
 * @author kungfoo
 * 
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface AfterClass {

}
