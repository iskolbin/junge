// Priority queue implemetned as indirect binary max heap

// Implementation details:
//   - efficient inplace heap creation from array: "new" with argument -- array ( Floyd's algorithm );
//   - safe call "enqueue"( "fastEnqueue" for unsafe call ), which ensure that the element not in the heap;  
//   - safe efficient "enqueueAll" operation ( O(n), Floyd's algorithm ). Note that "fastEnqueueAll" doesn't ensure that element not in heap, so use it with care;
//   - optimized "dequeue" operation ( Floyd's sifting algorithm );
//   - efficient "remove" operation ( indirect heap ), and fastRemove with no contain check;
//   - efficient "update" operation if somehow elements priority changed ( indirect heap );
//   - unstable inplace O(nlogn) heapsort ( about 5 times slower than Array.sort ): 
//       var data: Array<...> = [...];
//       var heap = new BinaryHeap<...>( data );
//       for ( i in 0...data.length ) data[data.length-i-1] = heap.dequeue();

package junge;

interface Heapable<T> {
	var heapIndex: Int;
	function higherPriority( other: T ): Bool;
}

class BinaryHeap<T: Heapable<T>> {
	public var data(default,null): Array<T> = null;
	public var length(default, null): Int = 0;
	
	inline function swap( index1, index2 ): Void {
		var tmp = data[index1];
		data[index1] = data[index2];
		data[index2] = tmp;
		data[index1].heapIndex = index1;
		data[index2].heapIndex = index2;
	}

	inline function siftUp( index: Int ): Int {
		var parentIndex = (index-1) >> 1;
		while ( index > 0 && data[index].higherPriority( data[parentIndex] )) {
			swap( index, parentIndex );
			index = parentIndex;
			parentIndex = (index-1) >> 1;	
		}
		return index;
	}

	inline function siftDownFloyd( index: Int ) {
		var leftIndex = (index << 1) + 1;
		var rightIndex = leftIndex + 1;
		while ( leftIndex < length ) {
			var higherPriorityIndex = ( rightIndex < length && data[rightIndex].higherPriority( data[leftIndex] )) ? rightIndex : leftIndex;
			swap( index, higherPriorityIndex );
			index = higherPriorityIndex;
			leftIndex = (index << 1) + 1;
			rightIndex = leftIndex + 1;
		}
		siftUp( index );
	}
	
	inline function siftDown( index: Int ) {
		var leftIndex = (index << 1) + 1;
		var rightIndex = leftIndex + 1;
		while ( leftIndex < length ) {
			var higherPriorityIndex = ( rightIndex < length && data[rightIndex].higherPriority( data[leftIndex] )) ? rightIndex : leftIndex;
			if ( data[index].higherPriority( data[higherPriorityIndex] )) break;
			swap( index, higherPriorityIndex );
			index = higherPriorityIndex;
			leftIndex = (index << 1) + 1;
			rightIndex = leftIndex + 1;
		}
	}

	inline function algorithmFloyd() {
		var n = length >> 1;
		for ( i_ in 0...n ) {
			siftDown( n - i_ - 1 );
		}
	}

	public function new( ?inplaceArray: Array<T> ) {
		if ( inplaceArray != null ) {
			data = inplaceArray;
			for ( i in 0...data.length ) data[i].heapIndex = i;
			length = data.length;
			algorithmFloyd();
		} else {
			data = new Array<T>();	
			data[0] = null;
		}
	}

	public inline function peek(): T return data[0];
	public inline function empty(): Bool return length <= 0;
	public inline function contains( v: T ): Bool return ( v.heapIndex >= 0 && v.heapIndex < length && data[v.heapIndex] == v );

	public function trim() {
		data.splice( length, data.length-length );
	}

	public inline function remove( v: T ) {
		if ( v.heapIndex >= 0 && v.heapIndex < length ) {
			fastRemove( v );
		}
	}

	public inline function enqueue( v: T ) {
		if ( !contains( v )) {
		 	fastEnqueue( v );
		}
	}

	public function dequeue(): T {
		var v = data[0];
		
		switch ( length ) {
			case 0: 
			case 1: 
				data[0] = null;
				length = 0;
			case 2: 
				data[0] = data[1];
				data[1] = null;
				data[0].heapIndex = 0;
				length = 1;
			default: 
				length -= 1;
				data[0] = data[length];
				data[length] = null;
				data[0].heapIndex = 0;
				siftDownFloyd( 0 );
		}

		return v;
	}
	
	public function enqueueAll( collection: Iterable<T> ) {
		for ( v in collection ) if ( !contains( v )) {
			data[length] = v;
			data[length].heapIndex = length;
			length += 1;
		}
		algorithmFloyd();
	}
	
	public function fastEnqueueAll( collection: Iterable<T> ) {
		for ( v in collection ) {
			data[length] = v;
			data[length].heapIndex = length;
			length += 1;
		}
		algorithmFloyd();
	}
	
	public inline function update( v: T ) {
		if ( contains( v )) {
			fastUpdate( v );
		}
	}
	
	public function fastEnqueue( v: T ) {
		data[length] = v;
		v.heapIndex = length;
		length += 1;
		siftUp( length - 1 );
	}

	public function fastRemove( v: T ) {
		switch ( length ) {
			case 0:
			case 1: if ( data[v.heapIndex] == v ) { 
				data[0] = null;
				length = 0;
			}
			default: if ( data[v.heapIndex] == v ) {
				length -= 1;
				if ( v.heapIndex != length ) {
					data[v.heapIndex] = data[length];
					data[v.heapIndex].heapIndex = v.heapIndex;
					fastUpdate( v );	
				} 
				data[length] = null;
			}
		}
	}

	public function fastUpdate( v: T ) {
		siftDown( siftUp( v.heapIndex ));
	}
}
