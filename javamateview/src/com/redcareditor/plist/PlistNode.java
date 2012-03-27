package com.redcareditor.plist;

import java.util.ArrayList;
import java.util.List;

import org.jdom.Element;

/**
 * generic class that holds the various elements of the property tree in a plist
 * file.
 * 
 * @author kungfoo
 * 
 * @param <T>
 */
public class PlistNode<T> {
	public T value;

	public PlistNode(T value) {
		this.value = value;
	}

	public PlistNode() {
	}

	@SuppressWarnings("unchecked")
	public static PlistNode<?> parseElement(Element element) {
		if (elementNameIs(element, "string")) {
			return new PlistNode<String>(element.getValue());
		}
		if (elementNameIs(element, "integer")) {
			return new PlistNode<Integer>(Integer.parseInt(element.getValue()));
		}
		if (elementNameIs(element, "array")) {
			List<PlistNode<?>> array = new ArrayList<PlistNode<?>>();
			List<Element> children = element.getChildren();
			for (Element e : children) {
				array.add(PlistNode.parseElement(e));
			}
			return new PlistNode<List<PlistNode<?>>>(array);
		}
		if (elementNameIs(element, "dict")) {
			return new Dict(element);
		}

		return null;
	}

	private static boolean elementNameIs(Element element, String name) {
		return element.getName().equals(name);
	}
}
