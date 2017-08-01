package net.cyclo.mysprite {
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	/**
	 * une anim pilotée par itération (asset contient un movie clip) ; attention, animation sur 1 level, pas de sous anim !
	 * 
	 * @author nico
	 */
	public class MySpFrameAnim extends MySpFrame {
		/**
		 * on récupère l'anim pilotée
		 * @return	anim à piloter ; doit être "applatie" sur cette time line, pas de sous anim
		 */
		protected function getAnimMC() : MovieClip { return ( assetSp.content as DisplayObjectContainer).getChildByName( "mcAnim") as MovieClip; }
		
		/** @inheritDoc */
		override public function doFrame() : void {
			var lAnim : MovieClip;
			
			if( mgr.getSpGround( this).gContainer.visible){
				lAnim = getAnimMC();
				if ( lAnim.currentFrame == lAnim.totalFrames) lAnim.gotoAndStop( 1);
				else lAnim.nextFrame();
			}
		}
		
		/** @inheritDoc */
		override protected function initAssetSp() : void {
			super.initAssetSp();
			
			getAnimMC().gotoAndStop( 1 + Math.round( Math.random() * ( getAnimMC().totalFrames - 1)));
		}
	}
}