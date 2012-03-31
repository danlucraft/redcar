package com.redcareditor.util.swt;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.widgets.Display;


public class ColourUtil {

	// Here parent_colour is like '#FFFFFF' and
	// colour is like '#000000DD'.
	static public String mergeColour(String parentColour, String colour) {
		int pre_r, pre_g, pre_b;
		int post_r, post_g, post_b;
		int opacity;
		int new_r, new_g, new_b;
		String new_colour = null;
		if (parentColour == null)
			return null;
		if (colour.length() == 7)
			return colour;
		if (colour.length() == 9) {
			pre_r = ColourUtil.hex_to_int(parentColour.charAt(1), parentColour.charAt(2));
			pre_g = ColourUtil.hex_to_int(parentColour.charAt(3), parentColour.charAt(4));
			pre_b = ColourUtil.hex_to_int(parentColour.charAt(5), parentColour.charAt(6));
	
			post_r = ColourUtil.hex_to_int(colour.charAt(1), colour.charAt(2));
			post_g = ColourUtil.hex_to_int(colour.charAt(3), colour.charAt(4));
			post_b = ColourUtil.hex_to_int(colour.charAt(5), colour.charAt(6));
			opacity = ColourUtil.hex_to_int(colour.charAt(7), colour.charAt(8));
	
			new_r = (pre_r*(255-opacity) + post_r*opacity)/255;
			new_g = (pre_g*(255-opacity) + post_g*opacity)/255;
			new_b = (pre_b*(255-opacity) + post_b*opacity)/255;
			new_colour = String.format("#%02x%02x%02x", new_r, new_g, new_b);
			// stdout.printf("%s/%s/%s - %d,%d,%d\n", parent_colour, colour, new_colour, new_r, new_g, new_b);
			return new_colour;
		}
		return "#000000";
	}

	private static int char_to_hex(Character ch) {
		return Character.digit(ch, 16);
	}

	private static int hex_to_int(char ch1, char ch2) {
		return char_to_hex(ch1)*16 + char_to_hex(ch2);
	}

	public static Color getColour(String colour) {
		return new Color(Display.getCurrent(), 
					Integer.parseInt(colour.substring(1, 3), 16),
					Integer.parseInt(colour.substring(3, 5), 16),
					Integer.parseInt(colour.substring(5, 7), 16));
	}

}
