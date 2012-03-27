package com.redcareditor.theme;

import org.junit.Before;
import org.junit.Test;
import static org.junit.Assert.*;

import com.redcareditor.plist.Dict;


public class RailsCastThemeTest {
	private Theme theme;

	@Before
	public void setup(){
		Dict themeDict = Dict.parseFile("input/Themes/Railscasts.tmTheme");
		theme = new Theme(themeDict);
	}
	
	@Test
	public void testGlobalSettings(){
		String background = theme.globalSettings.get("background");
		assertEquals("#2B2B2B", background);
		
		String invisibles = theme.globalSettings.get("invisibles");
		assertEquals("#404040", invisibles);
	}
	
	@Test
	public void testSingleScopeSetting(){
		
	}
	
	@Test
	public void testMultipleScopeSetting(){
		
	}
}
