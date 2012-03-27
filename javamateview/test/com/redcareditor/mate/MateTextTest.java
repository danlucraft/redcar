package com.redcareditor.mate;

import org.eclipse.swt.widgets.Shell;
import org.junit.Before;
import org.junit.Test;
import static org.junit.Assert.*;

public class MateTextTest {
	private MateText mt;
	
	@Before
	public void setUp() {
		Bundle.loadBundles("input/");
		Shell shell = new Shell();
		mt = new MateText(shell);
	}
	
	@Test
	public void shouldSetTheGrammarByName() {
		assertTrue(mt.setGrammarByName("Ruby"));
		assertEquals("Ruby", mt.parser.grammar.name);
	}
	
	@Test
	public void shouldSetTheGrammarByFilename() {
		assertEquals("Ruby", mt.setGrammarByFilename("foo.rb"));
		assertEquals("Apache", mt.setGrammarByFilename(".htaccess"));
		assertEquals("Ruby", mt.setGrammarByFilename("Rakefile"));
	}
	
	@Test
	public void shouldSetTheGrammarByFirstLine() {
		assertEquals("Ruby", mt.setGrammarByFirstLine("#!/usr/bin/ruby\n"));
	}
}
