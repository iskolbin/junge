package junge;

class WuLine {
	public var xs(default,null): Array<Int> = null;
	public var ys(default,null): Array<Int> = null;
	public var vs(default,null): Array<Float> = null;
	public var length(get,null): Int;

	public function get_length(): Int return xs != null ? xs.length : -1;

	inline function fpart( x: Float ): Float return x < 0.0 ? 1.0 - x + Math.ffloor( x ) : x - Math.ffloor( x );
	inline function rfpart( x: Float ): Float return x < 0.0 ? x - Math.ffloor( x ) : 1.0 - x + Math.ffloor( x );
	
	function init() {
		xs = new Array<Int>();
		ys = new Array<Int>();
		vs = new Array<Int>();
	}
	
	function plot( x: Int, y: Int, v: Float ) {
		xs.push( x );
		ys.push( y );
		vs.push( v );
	}
	
	public function new( x0: Int, y0: Int, x1: Int, y1: Int ) {
		init();
		
		var steep = Math.abs( y1 - y2 ) > Math.abs( x1 - x0 );
		var temp = 0;

		if ( steep ) {
			temp = x0; x0 = y0; y0 = temp;
			temp = x1; x1 = y1; y1 = temp;
		}

		if ( x0 > x1 ) {
			temp = x0; x0 = x1; x1 = temp;
			temp = y0; y0 = y1; y1 = temp;
		}

		var dx = x1 - x0;
		var dy = y1 - y0;
		var gradient = dy / dx;
		
		var xend = Math.fround( x0 );
		var yend = y0 + gradient * (xend - x0);
		var xgap = rfpart( x0 + 0.5 );
		var xpxl1 = xend;
		var ypxl1 = Std.int( yend );

		if ( steep ) {
			plot( ypxl1, xpxl1, rfpart( yend ) * xgap );
			plot( ypxl1+1, xpxl1, fpart( yend ) * xgap );
		} else {
			plot( ypxl1, xpxl1, rfpart( yend ) * xgap );
			plot( ypxl1+1, xpxl1, fpart( yend ) * xgap );
		}
		var intery = yend + gradient;

		xend = Math.fround( x1 );
		yend = y1 + gradient * (xend-x1);
		xgap = fpart( x1 + 0.5 );
		xpxl2 = xend;
		ypxl2 = Std.int( yend );

		if ( steep ) {
			plot( ypxl2, xpxl2, rfpart( yend ) * xgap );
			plot( ypxl2+1, xpxl2, fpart( yend ) * xgap );
		} else {
			plot( xpxl2, ypxl2, rfpart( yend ) * xgap );
			plot( xpxl2, ypxl2+1, fpart( yend ) * xgap );
		}

		for ( x in xpxl1+1...xpxl2-1 ) {
			if ( steep ) {
				plot( Std.int( intery ), x, rfpart( intery ));
				plot( Std.int( intery ) + 1, x, fpart( intery ));
			} else {
				plot( x, Std.int( intery ), rfpart( intery ));
				plot( x, Std.int( intery) + 1, fpart( intery ));
			}
			intery = intery + gradient;
		}
	}

	public inline static function func( func: Int->Int->Float->Void, x0: Int, y0: Int, x1: Int, y1: Int ): Void {
		new WuLineFunc( func, x0, y0, x1, y1 );
	}
}

private class WuLineFunc extends WuLine {
	dynamic function func( x: Int, y: Int, v: Float ): Void;
	override function init() {}
	override function plot( x: Int, y: Int, v: Float ) {
		func( x, y, v );
	}	

	public function new( func: Int->Int->Float->Void, x0: Int, y0: Int, x1: Int, y1: Int ) {
		this.func = func;
		super( x0, y0, x1, y1 );
	}
}
