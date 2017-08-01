package net.cyclo.mysprite {
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import net.cyclo.display.DepthMgr;
	import net.cyclo.utils.UtilsMovieClip;
	
	public class GroundMgrFront extends GroundMgr {
		protected var frontContainer						: DisplayObjectContainer					= null;
		protected var frontDepthMgr							: DepthMgr									= null;
		
		protected var backContainer							: DisplayObjectContainer					= null;
		protected var backDepthMgr							: DepthMgr									= null;
		
		public function GroundMgrFront( pContainer : DisplayObjectContainer, pLvlGround : LvlGroundMgr, pSpMgr : MySpriteMgr, pVisible : Boolean = true) {
			super( pContainer, pLvlGround, pSpMgr, pVisible);
		}
		
		override public function updateSpDepth( pSp : MySprite, pDHint : Number) : void {
			if ( pSp is ISpriteFront) frontDepthMgr.updateDepth( pSp, pDHint);
			else backDepthMgr.updateDepth( pSp, pDHint);
		}
		
		override protected function buildContainer( pContainer : DisplayObjectContainer) : void {
			container		= pContainer;
			
			backContainer	= pContainer.addChild( new Sprite()) as DisplayObjectContainer;
			backDepthMgr	= new DepthMgr( backContainer);
			
			frontContainer	= pContainer.addChild( new Sprite()) as DisplayObjectContainer;
			frontDepthMgr	= new DepthMgr( frontContainer);
		}
		
		override protected function freeContainer() : void {
			UtilsMovieClip.clearFromParent( backContainer);
			backContainer	= null;
			backDepthMgr	= null;
			
			UtilsMovieClip.clearFromParent( frontContainer);
			frontContainer	= null;
			frontDepthMgr	= null;
			
			super.freeContainer();
		}
		
		override protected function addSpToContainer( pSp : MySprite, pDHint : Number) : void {
			if ( pSp is ISpriteFront) {
				frontContainer.addChild( pSp);
				frontDepthMgr.setDepth( pSp, pSp.getSpDHint( this, pDHint));
			}else {
				backContainer.addChild( pSp);
				backDepthMgr.setDepth( pSp, pSp.getSpDHint( this, pDHint));
			}
		}
		
		override protected function remSpFromContainer( pSp : MySprite) : void {
			if ( pSp is ISpriteFront) {
				frontDepthMgr.freeDepth( pSp);
				UtilsMovieClip.clearFromParent( pSp);
			}else {
				backDepthMgr.freeDepth( pSp);
				UtilsMovieClip.clearFromParent( pSp);
			}
		}
	}
}