package junge;

class TweenPool {
	public var stamp(default,null): Float = 0;
	public var head(default,null) = new Tween( null );
	public var tail(default,null) = new Tween( null );

	public function new() {
		Tween.clearPool( this );
	}	

	public inline function clear() {
		Tween.clearPool( this );
	}

	public inline function update( stamp: Float ) {
		var dt = stamp - this.stamp;
		this.stamp = stamp;
	
		var tween = head.next;

		while( tween != tail ) {
			var next = tween.next;
			if ( !tween.update( dt )) {
				tween.pause();
			}
			tween = next;
		}
	}
}

interface Tweenable {
	public function getAttr( attr: Int ): Float;
	public function setAttr( attr: Int, v: Float ): Void;
}

class TweenDummy implements Tweenable {
	public var v: Float;
	public static function dummyDoNothing( v: Float ): Void {}
	public var onSetAttr: Float->Void;
	public function getAttr( attr ) return v;
	public function setAttr( attr, v ) {
		this.v = v;
		onSetAttr( v );
	}
	public function move( target, length, ease, after ) return Tween.move( this, 0, target, length, ease, after ); 
	public function move2( target, ease, after ) return Tween.move2( this, 0, target, ease, after ); 
	public function move3( target, after ) return Tween.move3( this, 0, target, after ); 
	public function new( v, onSetAttr ) {
		this.v = v;
		this.onSetAttr = onSetAttr;
	}
}

class Tween {
	public static inline var Step: Int = 0;
	public static inline var Linear: Int = 1;
	public static inline var EaseIn: Int = 2;
	public static inline var EaseOut: Int = 3;
	public static inline var EaseInOut: Int = 4;

	public static inline var Stop: Int = 0;
	public static inline var Reset: Int = 1;
	public static inline var Loop: Int = 2;
	public static inline var Pong: Int = 3;

	public static inline var BATCH_SIZE = 2;
	public static inline var BATCH_SIZE2 = 3;

	public static function doNothing( w: Tween ) return true;
	public static var defaultPool(default,null) = new TweenPool();

	public static function clearPool( p: TweenPool ) {
		p.head.next = p.tail;
		p.tail.pred = p.head;
	}

	static var NULL_TWEEN: Tween;
	public static var NULL(get,null): Tween;
	public static function get_NULL() {
		if ( NULL_TWEEN == null ) NULL_TWEEN = Tween.dummy( 0, TweenDummy.dummyDoNothing ).move(0,0,0,0);
		return NULL_TWEEN;
	}

	public var onStop: Tween->Bool = doNothing;
	public var onLoop: Tween->Bool = doNothing;
	public var onBatch: Tween->Bool = doNothing;

	public var start: Float;

	public var t: Float;
	public var b: Float;
	public var c: Float;
	public var d: Float;
	
	public var b0: Float;
	
	public var next(default,null): Tween = null;
	public var pred(default,null): Tween = null;

	public var batchList(default,null): Array<Float> = null;
	public var batchIdx(default,null):Int = 0;
	public var batchDir(default,null):Int = BATCH_SIZE;

	public var pool(default,null): TweenPool;
	public var object(default,null): Tweenable;
	public var ease: Int;
	public var after: Int;
	public var attr(default,null): Int;

	public inline function isLastBatchFrame(): Bool return ( batchIdx + batchDir < 0 )||( batchIdx + batchDir >= batchList.length);

	public inline function update( dt: Float ) {
		var save: Bool;
		t += dt;
		if ( t >= d ) {
			if ( batchList == null || isLastBatchFrame() ) {
				save = switch ( after ) {
					case Stop: 
						updateAttr( b + c ); 
						onStop( this ); 
						false;

					case Reset:
						updateAttr( b0 ); 
						onStop( this ); 
						false;
						
					case Loop:
						updateAttr( b + c ); 
						if ( onLoop( this )) {
							if ( batchList != null ) {
								batchIdx = 0;
								t = 0;
								b = b0;
								c = batchList[batchIdx] - start;
								d = batchList[batchIdx+1];
								if ( batchDir == BATCH_SIZE2 || batchDir == -BATCH_SIZE2 ) ease = Std.int( batchList[batchIdx+2] );
							} else {
								t = 0;
							}
							true;
						} else {
							false;
						}

					case Pong: 
						updateAttr( b + c );
						if ( onLoop( this )) {
							if ( batchList != null ) {	
								batchDir = -batchDir;
								t = 0;
								b = b + c;
								c = batchList[batchIdx] - start;
								if ( batchDir < 0 ) c = -c;
								d = batchList[batchIdx+1];
								if ( batchDir == BATCH_SIZE2 || batchDir == -BATCH_SIZE2 ) ease = Std.int( batchList[batchIdx+2] );
							} else {
								t = 0;
								var b_ = b;
								b = b + c;
								c *= -1;
							}
							true;
						} else {
							false;
						}

					default: false;
				}
			} else {
				updateAttr( b + c ); 
				save = if ( onBatch( this )) {
					batchIdx += batchDir;
					t = 0;
					b = b + c;
					c = batchList[batchIdx] - start;
					if ( batchDir < 0 ) c = -c;
					d = batchList[batchIdx+1];
					if ( batchDir == BATCH_SIZE2 || batchDir == -BATCH_SIZE2 ) ease = Std.int( batchList[batchIdx+2] );
					true;
				} else {
					false;
				}
			}
		} else {
			updateAttr( easeAttr());	
			save = true;
		}
		return save;
	}

	inline function updateAttr( v: Float ) object.setAttr( attr, v );
	
	inline function easeAttr(): Float {
		return switch( ease ) {
			case Step: 
				b +( (t >= d) ? c : 0);
			
			case Linear: 
				c * t / d + b; 
			
			case EaseIn: 
				var t = t / d; 
				c*t*t + b;
			
			case EaseOut: 
				var t = t / d; 
				-c*t*(t-2) + b;
			
			case EaseInOut: 
				var t = 2*t/d; 
				if ( t < 1 ) {
					0.5*c*t*t + b;
				} else {
					t -= 1;
					-0.5*c*(t*(t-2)-1) + b;
				}

			default: 0;
		}
	}

	public inline function new( pool: TweenPool ) {
		this.pool = pool;
		this.next = this;
		this.pred = this;
	}

	public inline function init( object: Tweenable, attr: Int, start: Float, target: Float, length: Float, ease: Int, after: Int ) {
		this.object = object;
		this.attr = attr;
		this.start = start;
		this.t = 0;
		this.b = object.getAttr( attr );
		this.c = target - start;
		this.d = length;
		this.ease = ease;
		this.batchList = null;
		this.after = after;
		this.b0 = b;
		this.onStop = doNothing;
		this.onLoop = doNothing;
		this.onBatch = doNothing;
		return this;
	}

	public inline function init2( object: Tweenable, attr: Int, start: Float, target: Array<Float>, ease: Int, after: Int ) {
		init( object, attr, start, target[0], target[1], ease, after );
		this.batchIdx = 0;
		this.batchDir = BATCH_SIZE;
		this.batchList = target;
		return this;
	}
	
	public inline function init3( object: Tweenable, attr: Int, start: Float, target: Array<Float>, after: Int ) {
		init2( object, attr, start, target, Std.int( target[2] ), after );
		this.batchDir = BATCH_SIZE2;
		return this;
	}

	public inline function play() {
		return removeFromPool().appendToPool();
	}

	public inline function pause() {
		return removeFromPool();
	}

	public inline function stop( ?after: Int ) {
		t = d;
		if ( after != null ) {
			this.after = after;
		}
		if ( !update( 0 ) ) {
			removeFromPool();
		}
		return this;
	}

	inline function appendToPool() {
		this.pred = pool.tail.pred;
		this.next = pool.tail;
		pool.tail.pred.next = this;
		pool.tail.pred = this;
		return this;
	}


	inline function removeFromPool() {
		next.pred = this.pred;
		pred.next = this.next;
		next = this;
		pred = this;
		return this;
	}

	public static inline function updateDefaultPool( stamp: Float ) defaultPool.update( stamp );

	public static inline function dummy( v, onSetAttr ) return new TweenDummy( v, onSetAttr ); 

	public static inline function move( obj: Tweenable, attr: Int, target: Float, length: Float, ease:Int, after: Int ) return new Tween( defaultPool ).init( obj, attr, 0, target, length, ease, after ).appendToPool();
	public static inline function move2( obj: Tweenable, attr: Int, target: Array<Float>, ease: Int, after: Int ) return new Tween( defaultPool ).init2( obj, attr, 0, target, ease, after ).appendToPool();
	public static inline function move3( obj: Tweenable, attr: Int, target: Array<Float>, after: Int ) return new Tween( defaultPool ).init3( obj, attr, 0, target, after ).appendToPool();
}
