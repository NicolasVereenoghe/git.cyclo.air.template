package net.cyclo.mysprite {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.cyclo.effect.MySkewMgr;
	
	/**
	 * forme homothétique sans traitement de profondeur, et sans clip de rendu alternatif ; fait pour de petits objets ne se superposant pas
	 * 
	 * effet homothétique : 
	 * n clips cisaillés, dont les x,y sont utilisés pour le traitement de masquage
	 * mcContent<i:int de 0 à n-1>
	 * ... avec un mcContent dont le rotate donne l'orientation, et dont les scaleX et skewX sont manipulés
	 * 
	 * 1 clip front avec jeu sur x, y pour simuler le plan en front ; ::FRONT_PARALLAX_COEF donne le scale théorique, redéfinir si besoin
	 * mcContentFront
	 * 
	 * @author	nico
	 */
	public class MySpSkewFrontBox extends MySpFrame implements ISpriteFront {
		protected var FRONT_PARALLAX_COEF					: Number									= -.08;
		
		protected var skewMgrs								: Array										= null;
		protected var frontContent							: DisplayObject								= null;
		protected var grndMgr								: GroundMgr									= null;
		
		override public function init( pMgr : MySpriteMgr, pDesc : MyCellDesc = null) : void {
			var lI			: int;
			var lContent	: DisplayObjectContainer;
			var lSkew		: MySkewMgr;
			
			super.init( pMgr, pDesc);
			
			frontContent	= ( assetSp.content as DisplayObjectContainer).getChildByName( "mcContentFront");
			grndMgr			= mgr.getSpGround( this);
			skewMgrs		= new Array();
			
			lI			= 0;
			lContent	= getSkewContent( 0);
			
			while ( lContent != null) {
				lSkew = new MySkewMgr();
				
				lSkew.init( lContent.getChildByName( "mcContent") as DisplayObjectContainer);
				
				skewMgrs.push(
					{
						skew: lSkew,
						d2: lContent.x * lContent.x + lContent.y * lContent.y
					}
				);
				
				lContent = getSkewContent( ++lI);
			}
			
			doSkew();
		}
		
		override public function destroy() : void {
			var lI : int;
			
			for ( lI = 0 ; lI < skewMgrs.length ; lI++) ( skewMgrs[ lI].skew as MySkewMgr).destroy();
			
			skewMgrs		= null;
			grndMgr			= null;
			frontContent	= null;
			
			super.destroy();
		}
		
		override public function doFrame() : void {
			if( mgr != null) doSkew();
		}
		
		protected function doSkew() : void {
			var lRect		: Rectangle		= grndMgr.getCurCamClipR();
			var lToCenter	: Point			= new Point( ( lRect.left + lRect.right) / 2 - x, ( lRect.top + lRect.bottom) / 2 - y);
			var lSkew		: MySkewMgr;
			var lContent	: DisplayObject;
			var lI			: int;
			
			for ( lI = 0 ; lI < skewMgrs.length ; lI++) {
				lSkew		= skewMgrs[ lI].skew as MySkewMgr;
				lContent	= getSkewContent( lI);
				
				if ( lToCenter.x * lContent.x + lToCenter.y * lContent.y > skewMgrs[ lI].d2) lSkew.doSkew( new Point( lToCenter.x - lContent.x, lToCenter.y - lContent.y));
				else lSkew.hide();
			}
			
			if ( frontContent != null) {
				frontContent.x = FRONT_PARALLAX_COEF * lToCenter.x;
				frontContent.y = FRONT_PARALLAX_COEF * lToCenter.y;
			}
		}
		
		protected function getSkewContent( pI : int) : DisplayObjectContainer { return ( assetSp.content as DisplayObjectContainer).getChildByName( "mcContent" + pI) as DisplayObjectContainer; }
	}
}