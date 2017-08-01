package net.cyclo.mysprite {
	import flash.display.DisplayObjectContainer;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * plan de sprites sans gestion de profondeur, optimal pour les plans de zones de hit
	 * 
	 * @author nico
	 */
	public class GroundMgrNoDepth extends GroundMgr {
		/** @inheritDoc */
		public function GroundMgrNoDepth( pContainer : DisplayObjectContainer, pLvlGround : LvlGroundMgr, pSpMgr : MySpriteMgr, pVisible : Boolean = true) {
			super( pContainer, pLvlGround, pSpMgr, pVisible);
		}
		
		/** @inheritDoc */
		override public function updateSpDepth( pSp : MySprite, pDHint : Number) : void { }
		
		/** @inheritDoc */
		override protected function buildContainer( pContainer : DisplayObjectContainer) : void {
			container = pContainer;
		}
		
		/** @inheritDoc */
		override protected function freeContainer() : void {
			UtilsMovieClip.clearFromParent( container);
			container	= null;
		}
		
		/** @inheritDoc */
		override protected function addSpToContainer( pSp : MySprite, pDHint : Number) : void {
			container.addChild( pSp);
		}
		
		/** @inheritDoc */
		override protected function remSpFromContainer( pSp : MySprite) : void {
			UtilsMovieClip.clearFromParent( pSp);
		}
	}
}