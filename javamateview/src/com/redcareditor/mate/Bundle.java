package com.redcareditor.mate;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class Bundle {
	private String name;
	private List<Grammar> grammars;
	private static List<Bundle> bundles;

	public Bundle(String name) {
		this.name = name;
		grammars = new ArrayList<Grammar>();
	}

	public static Bundle getBundleByName(String findName) {
		for (Bundle b : getBundles()) {
			if (b.getName().equals(findName))
				return b;
		}
		return null;
	}

	public String getName() {
		return name;
	}

	public List<Grammar> getGrammars() {
		return grammars;
	}

	public static List<Bundle> getBundles() {
		return bundles;
	}

	/**
	 * Return a list of bundle names like "Ruby.tmbundle"
	 */
	public static List<String> bundleDirs(String textmateDir) {
		List<String> names = new ArrayList<String>();
		File dir = new File(textmateDir + "/Bundles");
		if (dir.exists()) {
			for (String name : dir.list()) {
				if (name.endsWith(".tmbundle")) {
					names.add(name);
				}
			}
		}
		return names;
	}

	public static void loadBundles(String textmateDir) {
		if (getBundles() == null) {
  		bundles = new ArrayList<Bundle>();
		}
		for (String bundleDir : bundleDirs(textmateDir)) {
//			System.out.printf("loading %s\n", bundleDir);
			Bundle bundle = new Bundle(bundleDir.split("\\.")[0]);
			getBundles().add(bundle);
			File grammarDirectory = new File(textmateDir + "/Bundles/" + bundleDir + "/Syntaxes");
			if (grammarDirectory.exists()) {
				loadGrammar(bundle, grammarDirectory);
			}
		}
	}

	private static void loadGrammar(Bundle bundle, File syntaxDir) {
		for (String grammarFileName : syntaxDir.list()) {
			if (isTmBundlefile(grammarFileName)) {
				String grammarFilePath = syntaxDir.getPath() + "/" + grammarFileName;
				Grammar grammar = new Grammar(grammarFilePath);
				bundle.getGrammars().add(grammar);
			}
		}
	}

	private static boolean isTmBundlefile(String syntaxFileName) {
		return (syntaxFileName.endsWith(".tmLanguage") || syntaxFileName.endsWith(".plist"));
	}
}
