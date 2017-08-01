package net.cyclo.mysprite {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	/**
	 * un sprite dont la zone de clip est la zone de hit
	 * @author nico
	 */
	public class MySpWall extends MySprite {
		/** @inheritDoc */
		override public function testBounce( pSp : MySprite, pGXY : Point, pXY : Point = null) : Boolean {
			var lHZone	: DisplayObject	= ( assetSp.content as DisplayObjectContainer).getChildByName( "mcClip");
			
			if ( lHZone != null) return lHZone.hitTestPoint( pGXY.x, pGXY.y, true);
			else return false;
		}
	}
}