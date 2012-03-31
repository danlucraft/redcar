package ch.mollusca.benchmarking;

import java.util.Iterator;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class LinkedList<T> implements Iterable<T> {
	private LinkedNode<T> root;
	private LinkedNode<T> last;
	private int size = 0;
	private Lock mutex = new ReentrantLock(true);

	public int size() {
		return size;
	}

	public LinkedNode<T> getRoot() {
		return root;
	}

	protected LinkedNode<T> getLast() {
		return last;
	}

	public void clear() {
		try {
			mutex.lock();
			root = null;
			last = null;
			size = 0;
		} finally {
			mutex.unlock();
		}
	}

	public void add(T data) {
		try {
			mutex.lock();
			if (size == 0) {
				root = new LinkedNode<T>(data);
				last = root;
			} else {
				LinkedNode<T> node = new LinkedNode<T>(data);
				last.insert(node);
				last = node;
			}
			size++;
		} finally {
			mutex.unlock();
		}
	}

	public void addFirst(T data) {
		try {
			mutex.lock();
			if (size == 0) {
				root = new LinkedNode<T>(data);
				last = root;
			} else {
				LinkedNode<T> node = new LinkedNode<T>(data);
				node.setNext(root);
				root = node;
			}
			size++;
		} finally {
			mutex.unlock();
		}
	}

	public T[] toArray(T[] prepared) {
		if (prepared.length >= size) {
			LinkedNode<T> cur = root;
			for (int i = 0; i < size; i++) {
				prepared[i] = cur.getData();
				cur = cur.getNext();
			}

			return prepared;
		} else {
			throw new RuntimeException("Prepared Array not big enough!\nPrepared: "+prepared.length+", Size: "+size);
		}
	}

	public void addAll(LinkedList<T> list) {
		try {
			mutex.lock();
			if (this.size == 0) {
				this.root = list.root;
				this.last = list.last;
				this.size = list.size;
			} else if (list.size == 0) {
				return;
			} else {
				last.setNext(list.getRoot());
				last = list.getLast();
				size += list.size;
			}
		} finally {
			mutex.unlock();
		}
	}

	public T getData(int index) {
		LinkedNode<T> current = root;
		for (int i = 0; i < index; i++) {
			current = current.getNext();
		}
		return current.getData();
	}

	public Iterator<T> iterator() {
		return new LinkedIterator<T>(this);
	}
}
