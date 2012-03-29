package ch.mollusca.benchmarking;

import java.lang.annotation.ElementType;
import java.lang.annotation.Inherited;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;


/**
 * Benchmark the code inside the annotated method.
 * 
 * @author kungfoo
 * 
 */
@Retention(RetentionPolicy.RUNTIME)
@Inherited
@Target(ElementType.METHOD)
public @interface Benchmark {
	/**
	 * How many times do you want the code inside the function executed?
	 * 
	 * @return
	 */
	public int times() default 10;

	/**
	 * BRIEF: outputs a total and the average run time<br>
	 * FULL: will output the wall time for each run and a total/average
	 * 
	 * @return
	 */
	public BenchmarkFormat format() default BenchmarkFormat.BRIEF;

	/**
	 * AUTO: will perform automatic warm-up of the VM, the code that is being
	 * benchmarked will then be executed until the measurement desirably is
	 * accurate<br>
	 * In this mode outliers will automatically be removed by fitting a normal
	 * distribution to the measured timing values.<br>
	 * MANUAL: Fully manual, no
	 * warm-up, no outlier removal<br>
	 * REMOVE_OUTLIERS: Will perform no automatic warm-up, but will remove
	 * outliers after running the number of entries in the statistics will
	 * therefore not be the number of times the code has been run
	 * 
	 * @return
	 */
	public BenchmarkType type() default BenchmarkType.AUTO;
}
