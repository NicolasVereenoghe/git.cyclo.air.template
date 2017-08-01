package net.cyclo.mysprite {
	import flash.geom.Rectangle;
	import net.cyclo.shell.MySystem;
	
	public class MySpFrame extends MySprite {
		protected var tmpClipRect					: Rectangle						= null;
		
		/**
		 * méthode d'itération à la frame
		 */
		public function doFrame() : void { }
		
		override public function init( pMgr : MySpriteMgr, pDesc : MyCellDesc = null) : void {
			super.init( pMgr, pDesc);
			
			pMgr.regSpFrame( this);
		}
		
		override public function destroy() : void {
			mgr.remSpFrame( this);
			
			super.destroy();
		}
		
		protected function doClip() : void { if ( isClipable() && ! isInClip()) mgr.remSpriteDisplay( this); }
		
		protected function getClipRect() : Rectangle { return tmpClipRect; }
		
		protected function isInClip() : Boolean {
			var lRect	: Rectangle		= getClipRect().clone();
			
			lRect.offset( x, y);
			
			return mgr.camera.clipRect.intersects( lRect);
		}
	}
}