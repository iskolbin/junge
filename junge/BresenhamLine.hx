package junge;

class BresenhamLine {
	public var xs(default,null): Array<Int>;
	public var ys(default,null): Array<Int>;
	public var length(get,null): Int;

	public inline function get_length(): Int return xs != null ? xs.length : -1;

	function init() {
		xs = new Array<Int>();
		ys = new Array<Int>();
	}
	
	function plot( x: Int, y: Int ) {
		xs.push( x );
		ys.push( y );
	}

	public function new( x0: Int, y0: Int, x1: Int, y1: Int ) {
		init();
		
		if ( x1 == x2 ) {
			for ( y in y1...y2 ) {
				plot( x1, y );
			}
		} else if ( y1 == y2 ) {
			for ( x in x1...x2 ) {
				plot( x, y1 );
			}
		} else{
			var err = 0.0;
			var deltaerr = Math.abs( (y1-y0) / (x1-x0) );
			var signdy = y1 > y0 ? 1 : -1;
			var y = y0;
			for ( x in x0...x1 ) {
				plot( x, y );
				err += deltaerr;
				while ( err > 0.5 ) {
					plot( x, y );
					y += signdy;
					err -= 1.0;
				}
			}
		}
	}

	public inline static function func( func: Int->Int->Void, x0: Int, y0: Int, x1: Int, y1: Int ): Void {
		new BresenhamLineFunc( func, x0, y0, x1, y1 );
	}
}

private class BresenhamLineFunc extends BresenhamLine {
	dynamic function func( x: Int, y: Int ): Void;
	override function init() {}
	override function plot( x: Int, y: Int ) {
		func( x, y );
	}	

	public function new( func: Int->Int->Void, x0: Int, y0: Int, x1: Int, y1: Int ) {
		this.func = func;
		super( x0, y0, x1, y1 );
	}
}
