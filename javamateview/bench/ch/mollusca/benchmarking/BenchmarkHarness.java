package ch.mollusca.benchmarking;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;


/**
 * Invokes the methods needed for benchmarking.
 * @author kungfoo
 *
 */
public class BenchmarkHarness {

	private static final int MINIMUM_WARMUP_RUNS = 2;
	public static final String FULL_LINE = "-------------------------------------------------------------";
	private LinkedList<Object> tasks;
	
	private LinkedList<Method> benchmarked_methods;
	private LinkedList<Method> before_methods;
	private LinkedList<Method> after_methods;
	private LinkedList<Method> before_class_methods;
	private LinkedList<Method> after_class_methods;
	
	/**
	 * create a new benchmark harness and assign the given tasks
	 * 
	 * @param tasks
	 */
	public BenchmarkHarness(LinkedList<Object> tasks) {
		this.tasks = tasks;
		benchmarked_methods = new LinkedList<Method>();
		before_class_methods = new LinkedList<Method>();
		before_methods = new LinkedList<Method>();
		after_class_methods = new LinkedList<Method>();
		after_methods = new LinkedList<Method>();
	}
	

	public void start() throws IllegalArgumentException, SecurityException,
			IllegalAccessException, InvocationTargetException,
			NoSuchMethodException {

		for (Object task : tasks) {
			for (Method m : task.getClass().getMethods()) {
				// grab all annotation types
				
				if (m.isAnnotationPresent(Benchmark.class)) {
					benchmarked_methods.add(m);
				}
				if(m.isAnnotationPresent(Before.class)){
					before_methods.add(m);
				}
				if(m.isAnnotationPresent(After.class)){
					after_methods.add(m);
				}
				if(m.isAnnotationPresent(AfterClass.class)){
					after_class_methods.add(m);
				}
				if(m.isAnnotationPresent(BeforeClass.class)){
					before_class_methods.add(m);
				}
			}

			for (Method benchmarked_method : benchmarked_methods) {
				int passes = benchmarked_method.getAnnotation(Benchmark.class).times();
				BenchmarkStatistics stats = new BenchmarkStatistics(benchmarked_method);
				runListOfMethods(task, before_class_methods);
				
				if(autoTuneIn(benchmarked_method)){
					tuneIn(task, benchmarked_method);
				}
				
				System.out.println("Running benchmark......");
				
				for(int i = 0; i < passes; i++){
					long t1 = 0;
					long t2 = 0;
					
					runListOfMethods(task, before_methods);
					t1 = System.nanoTime();
					benchmarked_method.invoke(task);
					t2 = System.nanoTime();
					stats.add(new BenchmarkRun(t2-t1,i));
					runListOfMethods(task, after_methods);
				}
				
				runListOfMethods(task, after_class_methods);
				
				if(benchmarked_method.getAnnotation(Benchmark.class).format() == BenchmarkFormat.FULL){
					// output full stats
					stats.printFullStats();
				}
				
				stats.printShortStats();
				
				// clean up for next method
				System.gc();
			}
		}
	}


	private boolean autoTuneIn(Method benchmarked_method) {
		return benchmarked_method.getAnnotation(Benchmark.class).type() == BenchmarkType.AUTO;
	}
	
	private void runListOfMethods(Object task, LinkedList<Method> methods){
		if(methods == null){
			return;
		}
		for (Method method : methods) {
			try {
				
				method.invoke(task);
				
			} catch (IllegalArgumentException e) {
				e.printStackTrace();
			} catch (IllegalAccessException e) {
				e.printStackTrace();
			} catch (InvocationTargetException e) {
				e.printStackTrace();
			}
		}
	}

	/**
	 * tune in the hotspot VM
	 * @throws InvocationTargetException 
	 * @throws IllegalAccessException 
	 * @throws IllegalArgumentException 
	 */
	private void tuneIn(Object task, Method benchmarked_method) throws IllegalArgumentException, IllegalAccessException, InvocationTargetException{
		System.out.println("Tuning in VM for "+getFullMethodName(task, benchmarked_method)+".....");
		for(int i = 0; i < MINIMUM_WARMUP_RUNS; i++){
			runListOfMethods(task, before_methods);
			benchmarked_method.invoke(task);
			runListOfMethods(task, before_methods);
		}
	}
	
	private String getFullMethodName(Object task, Method benchmarked_method){
		return task.getClass().toString().replaceFirst("class ", "")+"."+benchmarked_method.getName()+"()";
	}
}
