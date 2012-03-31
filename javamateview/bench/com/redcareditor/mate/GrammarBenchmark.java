package com.redcareditor.mate;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.List;

import ch.mollusca.benchmarking.BeforeClass;
import ch.mollusca.benchmarking.Benchmark;

import com.redcareditor.onig.Match;
import com.redcareditor.onig.Rx;
import com.redcareditor.plist.Dict;
import com.redcareditor.util.FileUtility;

public class GrammarBenchmark {

	private String autocompleter;
	private List<String> lines;

	private Grammar grammar;
	private List<SinglePattern> singlePatterns;

	@BeforeClass
	public void setupForAll() {
		singlePatterns = new ArrayList<SinglePattern>();
		readFile();
		
		grammar = new Grammar("input/Ruby.plist");
		grammar.initForUse();

		for (Pattern p : grammar.allPatterns) {
			if (p instanceof SinglePattern) {
				singlePatterns.add((SinglePattern) p);
			}
		}

		System.out.println("Number of patterns: " + singlePatterns.size());
	}

	private void readFile() {
		try {
			autocompleter = new String(FileUtility
					.readFully("input/autocompleter.rb"));
			BufferedReader reader = new BufferedReader(new StringReader(
					autocompleter));
			lines = new ArrayList<String>();

			String str = "";
			while ((str = reader.readLine()) != null) {
				lines.add(str);
			}

		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Benchmark(times = 1000)
	public void benchmarkAllPatternsOnSingleLine() {
		String line = lines.get(8); // this line has a class definition on it
		for (SinglePattern p : singlePatterns) {
			Rx regex = p.match;
			Match m = regex.search(line);
            // if(m != null){
            //  System.out.println(p.name);
            //  System.out.println(m);
            // }
		}
	}

	@Benchmark(times = 500)
	public void benchmarkAllPatternsOnFile() {
		for(String line : lines){
			for (SinglePattern p : singlePatterns) {
				Rx regex = p.match;
				Match m = regex.search(line);
			}
		}
	}
}
