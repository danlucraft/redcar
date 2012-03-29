package ch.mollusca.benchmarking;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.util.Scanner;

/**
 * Dynamically loads a class that contains methods to be benchmarked.
 * @author kungfoo
 *
 */
public class BenchmarkRunner {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		String clazz = null;

		if (args.length == 0) {
			System.out
					.println("enter fully qualified classname of the class to run");
			Scanner in = new Scanner(System.in);
			clazz = in.nextLine();
		} else {
			clazz = args[0];
		}

		runBenchmarks(clazz);
	}

	private static void runBenchmarks(String clazz) {
		try {
			Class<?> task = Class.forName(clazz);
			Constructor<?> ctor = task.getConstructor();
			System.out.println("Benchmarking " + task.getClass());

			Object o = ctor.newInstance();

			LinkedList<Object> foo = new LinkedList<Object>();
			foo.add(o);

			new BenchmarkHarness(foo).start();

		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		} catch (SecurityException e) {
			e.printStackTrace();
		} catch (NoSuchMethodException e) {
			System.out.println("class does not have an empty ctor");
			e.printStackTrace();
		} catch (IllegalArgumentException e) {
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		} catch (InvocationTargetException e) {
			e.printStackTrace();
		} catch (InstantiationException e) {
			e.printStackTrace();
		}
	}
}
