package net.cyclo.mysprite {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.cyclo.effect.MySkewMgr;
	
	/**
	 * effet homothétique : 
	 * 4 clips cisaillés en forme de boite, dont les x,y sont utilisés pour le traitement de masquage
	 * mcContentLeft[2], mcContentRight[2], mcContentTop[2], mcContentBot[2]
	 * ... avec un mcContent dont le rotate donne l'orientation, et dont les scaleX et skewX sont manipulés
	 * 
	 * @author nico
	 */
	public class MySpSkewBox extends MySpFrame {
		protected var SKEW_DEPTH_PRECISION					: Number									= 22;
		
		protected var skewMgrLeft							: MySkewMgr									= null;
		protected var skewMgrRight							: MySkewMgr									= null;
		protected var skewMgrTop							: MySkewMgr									= null;
		protected var skewMgrBot							: MySkewMgr									= null;
		
		protected var grndMgr								: GroundMgr									= null;
		protected var lastDHint								: Number									= 0;
		
		override public function init( pMgr : MySpriteMgr, pDesc : MyCellDesc = null) : void {
			super.init( pMgr, pDesc);
			
			grndMgr			= mgr.getSpGround( this);
			lastDHint		= getSpDHint( grndMgr, 0);
			skewMgrLeft		= new MySkewMgr();
			skewMgrRight	= new MySkewMgr();
			skewMgrTop		= new MySkewMgr();
			skewMgrBot		= new MySkewMgr();
			
			skewMgrLeft.init( getSkewContentLeft().getChildByName( "mcContent") as DisplayObjectContainer, getSkewContentLeft2().getChildByName( "mcContent") as DisplayObjectContainer);
			skewMgrRight.init( getSkewContentRight().getChildByName( "mcContent") as DisplayObjectContainer, getSkewContentRight2().getChildByName( "mcContent") as DisplayObjectContainer);
			skewMgrTop.init( getSkewContentTop().getChildByName( "mcContent") as DisplayObjectContainer, getSkewContentTop2().getChildByName( "mcContent") as DisplayObjectContainer);
			skewMgrBot.init( getSkewContentBot().getChildByName( "mcContent") as DisplayObjectContainer, getSkewContentBot2().getChildByName( "mcContent") as DisplayObjectContainer);
			
			doSkew();
		}
		
		override public function destroy() : void {
			skewMgrLeft.destroy();
			skewMgrRight.destroy();
			skewMgrTop.destroy();
			skewMgrBot.destroy();
			
			skewMgrLeft		= null;
			skewMgrRight	= null;
			skewMgrTop		= null;
			skewMgrBot		= null;
			
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
				
				doSkew();
			}
		}
		
		override public function getSpDHint( pGrndMgr : GroundMgr, pDHint : Number) : Number {
			var lRect		: Rectangle	= pGrndMgr.getCurCamClipR();
			
			return -Math.floor( ( new Point( ( lRect.left + lRect.right) / 2 - x, ( lRect.top + lRect.bottom) / 2 - y)).length / ( SKEW_DEPTH_PRECISION * pGrndMgr.lvlGround.COEF_PARALLAXE));
		}
		
		protected function doSkew() : void {
			var lRect		: Rectangle		= grndMgr.getCurCamClipR();
			var lToCenter	: Point			= new Point( ( lRect.left + lRect.right) / 2 - x, ( lRect.top + lRect.bottom) / 2 - y);
			var lContent	: DisplayObject;
			
			lContent = getSkewContentLeft();
			if ( lContent.x > lToCenter.x) skewMgrLeft.doSkew( new Point( lToCenter.x - lContent.x, lToCenter.y));
			else skewMgrLeft.hide();
			
			lContent = getSkewContentRight();
			if ( lContent.x < lToCenter.x) skewMgrRight.doSkew( new Point( lToCenter.x - lContent.x, lToCenter.y));
			else skewMgrRight.hide();
			
			lContent = getSkewContentTop();
			if ( lContent.y > lToCenter.y) skewMgrTop.doSkew( new Point( lToCenter.x, lToCenter.y - lContent.y));
			else skewMgrTop.hide();
			
			lContent = getSkewContentBot();
			if ( lContent.y < lToCenter.y) skewMgrBot.doSkew( new Point( lToCenter.x, lToCenter.y - lContent.y));
			else skewMgrBot.hide();
		}
		
		protected function getSkewContentLeft() : DisplayObjectContainer { return ( assetSp.content as DisplayObjectContainer).getChildByName( "mcContentLeft") as DisplayObjectContainer; }
		protected function getSkewContentLeft2() : DisplayObjectContainer { return ( assetSp.content as DisplayObjectContainer).getChildByName( "mcContentLeft2") as DisplayObjectContainer; }
		protected function getSkewContentRight() : DisplayObjectContainer { return ( assetSp.content as DisplayObjectContainer).getChildByName( "mcContentRight") as DisplayObjectContainer; }
		protected function getSkewContentRight2() : DisplayObjectContainer { return ( assetSp.content as DisplayObjectContainer).getChildByName( "mcContentRight2") as DisplayObjectContainer; }
		protected function getSkewContentTop() : DisplayObjectContainer { return ( assetSp.content as DisplayObjectContainer).getChildByName( "mcContentTop") as DisplayObjectContainer; }
		protected function getSkewContentTop2() : DisplayObjectContainer { return ( assetSp.content as DisplayObjectContainer).getChildByName( "mcContentTop2") as DisplayObjectContainer; }
		protected function getSkewContentBot() : DisplayObjectContainer { return ( assetSp.content as DisplayObjectContainer).getChildByName( "mcContentBot") as DisplayObjectContainer; }
		protected function getSkewContentBot2() : DisplayObjectContainer { return ( assetSp.content as DisplayObjectContainer).getChildByName( "mcContentBot2") as DisplayObjectContainer; }
	}
}