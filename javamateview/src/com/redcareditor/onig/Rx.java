package com.redcareditor.onig;

import java.io.UnsupportedEncodingException;

import org.jcodings.Encoding;
import org.jcodings.specific.UTF8Encoding;
import org.jcodings.specific.UTF16BEEncoding;
import org.joni.Matcher;
import org.joni.Option;
import org.joni.Regex;
import org.joni.Region;
import org.joni.Syntax;
import org.joni.WarnCallback;

import java.text.CharacterIterator;
import java.text.StringCharacterIterator;

/**
 * wrapper class around the Joni Regex library which is a optimized port of
 * Onigurama
 * 
 * @author kungfoo
 * 
 */
public class Rx {
	public String pattern;
	public Regex regex;
	public boolean matchesStartOfLine = false;
	
	public static Rx createRx(String pattern){
//		System.out.printf("createRx(%s)\n", pattern);
		if(pattern == null){
			return NullRx.instance();
		} else {
			return new Rx(pattern);
		}
	}

	/**
	 * this is used implicitly by the null object class.
	 */
	protected Rx(){}
	
	private Rx(String pattern) {
		this.pattern = pattern;
		regex = compileRegex(pattern);
		if (!pattern.equals("")) {
			matchesStartOfLine = pattern.charAt(0) == '^';
		}
	}

	public boolean usable() {
		return (regex != null);
	}

	public Match search(String target, int start, int end) {
		byte[] bytes;
		try {
			bytes = target.getBytes("UTF-8");
			Matcher matcher = regex.matcher(bytes, 0, bytes.length);
			int a = matcher.search(start, end, Option.NONE);
			
			if(a == -1){
				return null;
			}
			
			Region region = matcher.getEagerRegion();
			return new Match(regex, region, target);

		} catch (UnsupportedEncodingException e) {
			e.printStackTrace();
		}
		return null;
	}
	
	public Match search(String line) {
		return search(line, 0, line.length());
	}

	class Warnings implements WarnCallback {
		public void warn(String message) {
			// System.out.printf("got warning from regex: %s\n", message);
		}
	}

	private Regex compileRegex(String pattern) {
		byte[] bytes;
		try {
			bytes = pattern.getBytes("UTF-8");
			return new Regex(bytes, 0, bytes.length, Option.DEFAULT,
					UTF8Encoding.INSTANCE, Syntax.DEFAULT, new Warnings());

		} catch (UnsupportedEncodingException e) {
			e.printStackTrace();
		} catch (org.joni.exception.SyntaxException e) {
			//System.out.printf("** WARNING: SyntaxException when compiling '%s': %s\n", pattern, e.getMessage());
			//e.printStackTrace();
		}
		return null;
	}
	
	@Override
	public String toString() {
		return pattern;
	}
	
    
	public static String escape(String aRegexFragment){
		final StringBuilder result = new StringBuilder();
		
		final StringCharacterIterator iterator = new StringCharacterIterator(aRegexFragment);
		char character =  iterator.current();
		while (character != CharacterIterator.DONE ){
			if (character == '.') {
				result.append("\\.");
			}
			else if (character == '\\') {
				result.append("\\\\");
			}
			else if (character == '?') {
				result.append("\\?");
			}
			else if (character == '*') {
				result.append("\\*");
			}
			else if (character == '+') {
				result.append("\\+");
			}
			else if (character == '&') {
				result.append("\\&");
			}
			else if (character == ':') {
				result.append("\\:");
			}
			else if (character == '{') {
				result.append("\\{");
			}
			else if (character == '}') {
				result.append("\\}");
			}
			else if (character == '[') {
				result.append("\\[");
			}
			else if (character == ']') {
				result.append("\\]");
			}
			else if (character == '(') {
				result.append("\\(");
			}
			else if (character == ')') {
				result.append("\\)");
			}
			else if (character == '^') {
				result.append("\\^");
			}
			else if (character == '$') {
				result.append("\\$");
			}
			else {
				result.append(character);
			}
			character = iterator.next();
		}
		return result.toString();
	}
  
}
