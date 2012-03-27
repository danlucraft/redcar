package com.redcareditor.plist;

import java.io.File;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

import org.jdom.Document;
import org.jdom.Element;
import org.jdom.JDOMException;
import org.jdom.input.SAXBuilder;

import com.redcareditor.onig.Rx;

/**
 * class to load plist files.
 * 
 * @author kungfoo
 * 
 */
public class Dict extends PlistNode<Map<String, PlistNode<?>>> {

	private static SAXBuilder builder;

	// NOTE: this method is not thread safe, if we ever go there, this needs to
	// contain a mutex!
	private static SAXBuilder getSAXBuilderInstance() {
		if (builder == null) {
			builder = new SAXBuilder(false);
			builder.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);

		}
		return builder;
	}

	public static Dict parseFile(String filename) {
		try {
			Document document = getSAXBuilderInstance().build(new File(filename));
			return new Dict(document.getRootElement().getChild("dict"));

		} catch (JDOMException e) {
			e.printStackTrace();
		} catch (IOException e) {
			System.out.println("The file " + filename + " was not found!");
			e.printStackTrace();
		}
		return null;
	}

	@SuppressWarnings("unchecked")
	protected Dict(Element element) {
		value = new HashMap<String, PlistNode<?>>();

		List<Element> children = element.getChildren();
		String key = null;
		for (Element c : children) {
			if (c.getName().equals("key")) {
				key = c.getValue();
			} else {
				value.put(key, PlistNode.parseElement(c));
			}
		}
	}

	public String getString(String key) {
		return tryGettingValue(this, key);
	}

	public Integer getInt(String key) {
		return tryGettingValue(this, key);
	}

	@SuppressWarnings("unchecked")
	public String[] getStrings(String key) {
		List<PlistNode<String>> strings = (List<PlistNode<String>>) value.get(key).value;
		String[] result = new String[strings.size()];
		int i = 0;
		for (PlistNode<String> str : strings) {
			result[i++] = str.value;
		}
		return result;
	}

	@SuppressWarnings("unchecked")
	public Dict[] getDictionaries(String key) {
		List<Dict> dictionaries = (List<Dict>) value.get(key).value;
		return dictionaries.toArray(new Dict[0]);
	}

	public List<PlistNode<?>> getArray(String key) {
		return tryGettingValue(this, key);
	}

	public Dict getDictionary(String key) {
		return (Dict) value.get(key);
	}

	public Rx getRegExp(String key) {
		return Rx.createRx(getString(key));
	}

	public boolean containsElement(String key) {
		return value.containsKey(key);
	}

	public Set<String> keys() {
		return value.keySet();
	}

	@SuppressWarnings("unchecked")
	private static <T> T tryGettingValue(Dict dict, String key) {
		if (dict.value.containsKey(key)) {
			return (T) dict.value.get(key).value;
		} else {
			return null;
		}
	}
}
