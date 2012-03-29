package ch.mollusca.benchmarking;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Annotation marking methods that will be executed once for each class that
 * contains Benchmark annotations.<br>
 * Use for methods that only need to be run once to clean up the dishes after
 * running the benchmark.<br>
 * The benchmarking framework will call System.gc() after running these methods,
 * so marking objects not needed anymore with null might be a good idea.
 * 
 * @author kungfoo
 * 
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface BeforeClass {

}
