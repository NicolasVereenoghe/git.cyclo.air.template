package net.cyclo.mysprite {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.cyclo.effect.MySkewMgr;
	import net.cyclo.utils.UtilsMaths;
	
	/**
	 * clip cisaillé : effet homothétique
	 * la forme cisaillée est placée dans un mcContent, la base à l'origine, orientée en 0°, le point de fuite sur l'axe des x matérialisé par un mcFuite
	 * on oriente le motif en jouant sur la rotation du mcContent
	 * /!\ le scale/skew du mcContent doit rester à 100%
	 * --
	 * on utilise un motif alternatif, si celui-ci est défini, mcContent2, pour les scales extrêmes
	 * --
	 * le code joue sur la matrice de transformation (scaleX, skewY, rotation initiale) du mcContent pour faire l'effet homothétique par rapport au centre de l'écran
	 * 
	 * @author	nico
	 */
	public class MySpSkew extends MySpFrame {
		protected var SKEW_DEPTH_PRECISION					: Number									= 22;
		
		protected var skewMgr								: MySkewMgr									= null;
		
		protected var grndMgr								: GroundMgr									= null;
		protected var lastDHint								: Number									= 0;
		
		override public function init( pMgr : MySpriteMgr, pDesc : MyCellDesc = null) : void {
			super.init( pMgr, pDesc);
			
			grndMgr		= mgr.getSpGround( this);
			lastDHint	= getSpDHint( grndMgr, 0);
			skewMgr		= new MySkewMgr();
			
			skewMgr.init( getSkewContent(), getSkewContent2());
			skewMgr.doSkew( getToCenter());
		}
		
		override public function destroy() : void {
			skewMgr.destroy();
			skewMgr = null;
			grndMgr = null;
			
			super.destroy();
		}
		
		override public function doFrame() : void {
			var lDHint	: Number;
			
			if( mgr != null){
				lDHint = getSpDHint( grndMgr, 0);
				
				if ( lDHint != lastDHint) {
					lastDHint = lDHint;
					
					grndMgr.updateSpDepth( this, lDHint);
				}
				
				skewMgr.doSkew( getToCenter());
			}
		}
		
		override public function getSpDHint( pGrndMgr : GroundMgr, pDHint : Number) : Number {
			var lRect		: Rectangle	= pGrndMgr.getCurCamClipR();
			
			return -Math.floor( ( new Point( ( lRect.left + lRect.right) / 2 - x, ( lRect.top + lRect.bottom) / 2 - y)).length / ( SKEW_DEPTH_PRECISION * pGrndMgr.lvlGround.COEF_PARALLAXE));
		}
		
		protected function getSkewContent() : DisplayObjectContainer { return ( assetSp.content as DisplayObjectContainer).getChildByName( "mcContent") as DisplayObjectContainer; }
		protected function getSkewContent2() : DisplayObjectContainer { return ( assetSp.content as DisplayObjectContainer).getChildByName( "mcContent2") as DisplayObjectContainer; }
		
		protected function getToCenter() : Point {
			var lRect		: Rectangle		= grndMgr.getCurCamClipR();
			
			return new Point( ( lRect.left + lRect.right) / 2 - x, ( lRect.top + lRect.bottom) / 2 - y);
		}
	}
}