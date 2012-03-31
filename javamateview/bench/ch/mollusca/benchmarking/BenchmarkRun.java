package ch.mollusca.benchmarking;

/**
 * One run of a benchmarked method. Used for stats.
 * @author kungfoo
 *
 */
public class BenchmarkRun {
	private long runtime;
	private int run_number;
	
	public BenchmarkRun(long runtime, int run_number){
		this.runtime = runtime;
		this.run_number = run_number;
	}
	
	public long runtime(){
		return runtime;
	}
	
	public int runNumber(){
		return run_number;
	}
}
