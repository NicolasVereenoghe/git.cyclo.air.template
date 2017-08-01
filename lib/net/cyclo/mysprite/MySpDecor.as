package net.cyclo.mysprite {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	/**
	 * classe de décor ; peut avoir une zone de collision
	 * 
	 * @author	nico
	 */
	public class MySpDecor extends MySprite {
		/** @inheritDoc */
		override public function testBounce( pSp : MySprite, pGXY : Point, pXY : Point = null) : Boolean {
			var lHZone	: DisplayObject	= ( assetSp.content as DisplayObjectContainer).getChildByName( "mcHitZone");
			
			if ( lHZone != null) return lHZone.hitTestPoint( pGXY.x, pGXY.y, true);
			else return false;
		}
	}
}