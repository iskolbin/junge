package junge;

class TimerPool extends BinaryHeap<Timer> {
	public var stamp(default,null): Float = 0;
	public var cumulative = false;

	public function updateTimers( stamp: Float ) {
		this.stamp = stamp;
		while ( !empty() && peek().stamp <= stamp ) {
			var timer = dequeue();
			if ((timer.count >= 1 || timer.count == Timer.INFINITE) && timer.interval > 0 ) {
				if ( !cumulative ) {
					 timer.stamp = stamp;
				}
				timer.nextStep();
				enqueue( timer );
			}
			timer.onStop( timer );
		}
	}

	public inline function dcall( onStop: Timer->Void, interval: Float, count: Int ) {
		var timer = new Timer( this );
		timer.interval = interval;
		timer.onStop = onStop;
		timer.count = count;
		timer.nextStep();
		enqueue( timer );
		return timer;
	}
}

class Timer implements BinaryHeap.Heapable<Timer> {
	static var NULL_TIMER: Timer = null;
	public static var NULL(get,null): Timer;
	public static inline var INFINITE: Int = -1;
	public static var defaultPool(default,null) = new TimerPool();	
	public var pool: TimerPool;
	public var stamp: Float = 0;
	public var interval: Float = 0;
	public var count: Int = 0;
	public var onStop: Timer->Void = doNothing;
	public var heapIndex: Int = 0;

	public inline function higherPriority( other: Timer ): Bool {
		return this.stamp < other.stamp;
	}

	public static function doNothing( self: Timer ) {}

	public static function get_NULL() { 
		if ( NULL_TIMER == null ) NULL_TIMER = new Timer( defaultPool );
		return NULL_TIMER;
	}

	public function new( pool: TimerPool ) {
		this.pool = pool;
		this.stamp = pool.stamp;
	}

	public inline function nextStep() { 
		if ( count != INFINITE && count > 0 ) {
			count -= 1;
		}
		stamp += interval;
	}

	public function stop() {
		pool.remove( this );
		this.stamp -= pool.stamp;	
	}

	public function start() {
		this.stamp += pool.stamp;
		pool.enqueue( this );
	}

	public static inline function updateDefaultPool( stamp: Float ) { defaultPool.updateTimers( stamp ); };
	public static inline function dcall( onStop: Timer->Void, interval: Float, count: Int ) return defaultPool.dcall( onStop, interval, count );
}
