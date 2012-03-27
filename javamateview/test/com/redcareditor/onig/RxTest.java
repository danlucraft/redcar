package com.redcareditor.onig;

import java.io.BufferedReader;
import java.io.StringReader;

import org.junit.Test;
import static org.junit.Assert.*;

import com.redcareditor.util.FileUtility;

public class RxTest {
	@Test
	public void testSingleFoo() {
		String pattern = "^\\s*(class)\\s+(([.a-zA-Z0-9_:]+(\\s*(&lt;)\\s*[.a-zA-Z0-9_:]+)?)|((&lt;&lt;)\\s*[.a-zA-Z0-9_:]+))+";
		String fileContents = "";
		try {
			fileContents = new String(FileUtility.readFully("input/autocompleter.rb"));

			BufferedReader reader = new BufferedReader(new StringReader(fileContents));

			Rx regex = Rx.createRx(pattern);

			String line;
			while ((line = reader.readLine()) != null) {
				Match m = regex.search(line, 0, line.length());

				if (m != null) {
					System.out.println(line);
					for (Range r : m) {
						System.out.println(r);
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	@Test
	public void testNullObject() {
		String pattern = null;
		Rx rx = Rx.createRx(pattern);
		assertTrue(rx instanceof Rx);
		assertTrue(rx instanceof NullRx);
		
		Match match = rx.search("baz");
		assertTrue(match instanceof NullMatch);
		// now check that the object behaves in a reasonable way.
		
		assertEquals(0, match.numCaptures());
		assertFalse(match.iterator().hasNext());
		assertEquals(0, match.ranges().size());
	}
}
