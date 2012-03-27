package com.redcareditor.plist;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import org.junit.Before;
import org.junit.Test;

public class DictTest {
	private Dict dict;

	@Before
	public void setup() {
		dict = Dict.parseFile("input/Bundles/Ruby.tmbundle/Syntaxes/Ruby.plist");
		assertNotNull(dict);
	}

	@Test
	public void testSimpleStringItem() {
		String firstLine = dict.getString("firstLineMatch");
		assertEquals("^#!/.*\\bruby\\b", firstLine);
	}

	@Test
	public void testFileTypes() {
		String[] check = { "rb", "rbx", "rjs", "Rakefile", "rake", "cgi",
				"fcgi", "gemspec", "irbrc", "capfile" };
		String[] types = dict.getStrings("fileTypes");

		assertArrayEquals(check, types);
	}
}
