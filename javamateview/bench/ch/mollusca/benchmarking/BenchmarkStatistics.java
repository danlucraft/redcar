package ch.mollusca.benchmarking;

import java.lang.reflect.Method;



/**
 * Performs house-keeping and statistics on the various runs of a benchmark.
 * @author kungfoo
 *
 */
public class BenchmarkStatistics {
	private Method benchmarked_method;
	private LinkedList<BenchmarkRun> runs;
	
	private LinkedList<BenchmarkRun> inliers;
	private LinkedList<BenchmarkRun> outliers;
	
	private boolean has_been_filtered = false;
	
	public BenchmarkStatistics(Method m){
		benchmarked_method = m;
		runs = new LinkedList<BenchmarkRun>();
		inliers = new LinkedList<BenchmarkRun>();
		outliers = new LinkedList<BenchmarkRun>();
	}
	
	public void add(BenchmarkRun run){
		runs.add(run);
		// as soon as we add to the set, we need to recalculate the stats
		has_been_filtered = false;
	}
	
	/**
	 * filter the data set that this statistic has collected
	 */
	private void filter(){
		if(!has_been_filtered){
			// calculate mean and standard deviation
			long sum = 0;
			for(BenchmarkRun run : runs){
				sum += run.runtime();
			}
			long mean = sum / runs.size();
			
			double std_dev = 0;
			for(BenchmarkRun run : runs){
				std_dev += (mean-run.runtime())*(mean-run.runtime());
			}
			std_dev *= 1d/(runs.size()-1);
			std_dev = Math.sqrt(std_dev);
			
			// remove outliers from the data set
			for(BenchmarkRun run : runs){
				if(run.runtime() < mean + std_dev && run.runtime() > mean - std_dev){
					inliers.add(run);
				}
				else{
					outliers.add(run);
				}
			}
			
			has_been_filtered = true;
		}
		else{
			// do nothing
		}
	}
	
	public LinkedList<BenchmarkRun> getInliers(){
		filter();
		return inliers;
	}
	
	public LinkedList<BenchmarkRun> getOutLiers(){
		filter();
		return outliers;
	}
	
	
	public void printFullStats(){
		filter();
		System.out.println(BenchmarkHarness.FULL_LINE);
		System.out.println("Full stats for "+benchmarked_method.getName()+"()");
		System.out.println();
		System.out.println("Outliers: ");
		System.out.println("run\t runtime");
		System.out.println(BenchmarkHarness.FULL_LINE);
		for(BenchmarkRun run : outliers){
			System.out.println(run.runNumber() +"\t"+toMilliseconds(run.runtime())+"ms");
		}
		System.out.println();
		System.out.println("Inliers: ");
		System.out.println("run\t runtime");
		System.out.println(BenchmarkHarness.FULL_LINE);
		for(BenchmarkRun run : inliers){
			System.out.println(run.runNumber() +"\t"+toMilliseconds(run.runtime())+"ms");
		}
		System.out.println(BenchmarkHarness.FULL_LINE);
	}
	
	public void printShortStats(){
		filter();
		double runtime = getInlierTime();
		System.out.println(inliers.size()+"x "+benchmarked_method.getName()+"() took: "+runtime+"ms");
		System.out.println("average runtime: " + runtime/inliers.size()+"ms");
		System.out.println(BenchmarkHarness.FULL_LINE);
	}
	
	private double toMilliseconds(long total_time) {
		return total_time*1e-6;
	}
	
	public double getOutlierTime(){
		filter();
		long total = 0;
		for(BenchmarkRun run : outliers){
			total += run.runtime();
		}
		return toMilliseconds(total);
	}
	
	public double getInlierTime(){
		filter();
		long total = 0;
		for(BenchmarkRun run : inliers){
			total += run.runtime();
		}
		return toMilliseconds(total);
	}
}
