package com.redcareditor.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;

public class FileUtility {
	private static final int INITIAL_BUFFER_SIZE = 2048;

	/**
	 * read the file at the given path fully to a byte array.
	 */
	public static byte[] readFully(String filepath)
			throws FileNotFoundException {
		return readFully(new File(filepath));
	}

	/**
	 * read the given file fully into a byte array.
	 * 
	 * @return The files contents as a byte[].
	 * @throws FileNotFoundException
	 */
	public static final byte[] readFully(File file)
			throws FileNotFoundException {
		return readFully(new FileInputStream(file));
	}

	/**
	 * read the given stream fully into a byte array.<br>
	 * This means that the stream has to end at some place, otherwise this
	 * method makes not sense.
	 */
	public static final byte[] readFully(InputStream stream) {
		try {
			int readBytes = 0;
			byte[] buffer = new byte[INITIAL_BUFFER_SIZE];
			int b = 0;
			while ((b = stream.read()) != -1) {
				if (readBytes == buffer.length) {
					buffer = doubleArraySize(buffer);
				}

				buffer[readBytes] = (byte) b;
				readBytes++;
			}

			byte[] result = new byte[readBytes];
			System.arraycopy(buffer, 0, result, 0, readBytes);
			return result;

		} catch (Exception e) {
			e.printStackTrace();
		}
		return new byte[0];
	}

	private static final byte[] doubleArraySize(byte[] array) {
		byte[] temp = new byte[array.length * 2];
		System.arraycopy(array, 0, temp, 0, array.length);
		return temp;
	}
}
