package net.cyclo.mysprite {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	public class MySpBounce extends MySpFrame {
		protected var BOUNCE_COEF								: Number									= 8;
		protected var BOUNCE_MAX_ITER							: int										= 5;
		
		protected var cos										: Number									= 1;
		protected var sin										: Number									= 0;
		
		protected var vXY										: Number									= 0;
		
		protected function get B_TAB() : Array { return null; }
		protected function set B_TAB( pTab : Array) : void { }
		
		protected function get NB_PT() : int { return 0; }
		protected function set NB_PT( pNb : int) : void { }
		
		protected function get G_XY() : Point { return null; }
		protected function set G_XY( pXY : Point) : void { }
		
		public function getVXY() : Number { return vXY; }
		
		public function getSpeed() : Point { return new Point( cos * vXY, sin * vXY); }
		
		public function getCos() : Number { return cos; }
		
		public function getSin() : Number { return sin; }
		
		override public function init( pMgr : MySpriteMgr, pDesc : MyCellDesc = null) : void {
			super.init( pMgr, pDesc);
			
			initBTab();
		}
		
		protected function getHitContainer() : DisplayObjectContainer { return null; }
		
		protected function getHitPt( pHitZone : DisplayObjectContainer, pI : int) : DisplayObject { return pHitZone.getChildByName( "mcHit" + pI); }
		
		protected function getLocalHitCoordDisp() : DisplayObject { return parent; }
		
		protected function getHitLvlGround() : LvlGroundMgr {
			if ( desc != null) return desc.lvlGroundMgr;
			else return null;
		}
		
		protected function procBounce() : void {
			var lBegEnd	: Object	= seekBounce( vXY);
			var lI		: int		= 1;
			
			if ( lBegEnd) {
				doBounceSpeedControl( lBegEnd);
				
				lBegEnd = seekBounce();
				
				while( lBegEnd != null) {
					doBounce( lBegEnd);
					
					if ( ++lI > BOUNCE_MAX_ITER) break;
					
					lBegEnd = seekBounce();
				}
			}
		}
		
		protected function doBounceSpeedControl( pBegEnd : Object) : void {
			var lBounce	: Object	= B_TAB[ pBegEnd.beg][ pBegEnd.end];
			var lReac	: Point		= getLocalHitCoordDisp().globalToLocal( getHitContainer().localToGlobal( new Point( lBounce.x, lBounce.y))).subtract( new Point( x, y));
			var lVX		: Number;
			var lVY		: Number;
			
			if ( lReac.x * cos + lReac.y * sin < 0) {
				lVX	= cos * vXY;
				lVY	= sin * vXY;
				vXY	= new Point(
					lReac.y * ( lReac.y * lVX - lReac.x * lVY) / lBounce.d,
					lReac.x * ( lReac.x * lVY - lReac.y * lVX) / lBounce.d
				).length;
			}
		}
		
		protected function doBounce( pBegEnd : Object) : void {
			var lBounce	: Object	= B_TAB[ pBegEnd.beg][ pBegEnd.end];
			var lReac	: Point		= getLocalHitCoordDisp().globalToLocal( getHitContainer().localToGlobal( new Point( lBounce.x, lBounce.y))).subtract( new Point( x, y));
			
			x	+= lReac.x / BOUNCE_COEF;
			y	+= lReac.y / BOUNCE_COEF;
		}
		
		protected function testBounceOnHitPt( pHitPt : DisplayObject, pDFront : Number = 0) : Boolean {
			var lCoordG		: Point			= pHitPt.parent.localToGlobal( new Point( pHitPt.x + pDFront, pHitPt.y));
			var lCoordL		: Point			= getLocalHitCoordDisp().globalToLocal( lCoordG);
			var lLvlGrnd	: LvlGroundMgr	= getHitLvlGround();
			var lI			: int			= lLvlGrnd.x2i( lCoordL.x);
			var lJ			: int			= lLvlGrnd.y2j( lCoordL.y);
			var lModI		: int			= lLvlGrnd.i2ModI( lI);
			var lModJ		: int			= lLvlGrnd.j2ModJ( lJ);
			var lCells		: Object		= lLvlGrnd.getCellsAt( lModI, lModJ);
			var lCell		: MyCellDesc;
			var lSps		: Array;
			var lISp		: int;
			var lSp			: MySprite;
			
			for each( lCell in lCells) {
				lSps	= mgr.getSpriteCell( lCell, new Point( lI, lJ));
				
				for ( lISp = 0 ; lISp < lSps.length ; lISp++) {
					lSp	= lSps[ lISp];
					
					if ( lSp != this && lSp.testBounce( this, lCoordG, lCoordL)) return true;
				}
			}
			
			return false;
		}
		
		protected function seekBounce( pDFront : Number = 0) : Object {
			var lHitZone	: DisplayObjectContainer	= getHitContainer();
			var lNbPt		: int						= NB_PT;
			var lI0Len		: int						= 0;
			var lIndPt		: int						= 1;
			var lPrev		: int						= -1;
			var lIBeg		: int						= -1;
			var lLen		: int						= 0;
			var lRes		: Object					= new Object();
			
			if ( ! testBounceOnHitPt( getHitPt( lHitZone, 0), pDFront)) {
				while ( ! testBounceOnHitPt( getHitPt( lHitZone, lIndPt++), pDFront)) {
					if ( lIndPt == lNbPt) return null;
				}
				
				lI0Len	= lIndPt - 1;
			}
			
			while( lIndPt < lNbPt){
				if( testBounceOnHitPt( getHitPt( lHitZone, lIndPt), pDFront)){
					if( lIndPt - lPrev == 1 && lLen < lIndPt - lIBeg){
						lRes.beg	= lIBeg;
						lLen		= lIndPt - lIBeg;
					}
					
					lIndPt++;
					continue;
				}
				
				if( lIndPt - lPrev != 1) lIBeg = lIndPt;
				
				lPrev = lIndPt;
				
				lIndPt++;
			}
			
			if( lIndPt - lPrev == 1 && lI0Len + lNbPt - lIBeg > lLen){
				lRes.beg = lIBeg;
				
				if( lI0Len > 0){
					lRes.end = lI0Len - 1;
					return lRes;
				}
				
				lRes.end = lNbPt - 1;
				return lRes;
			}
			
			if( lI0Len > lLen){
				lRes.beg	= 0;
				lRes.end	= lI0Len - 1;
				
				return lRes;
			}
			
			if( lLen > 0){
				lRes.end = lRes.beg + lLen - 1;
				
				return lRes;
			}
			
			return null;
		}
		
		protected function initBTab() : void {
			if ( B_TAB != null) return;
			
			initHitPt();
			buildBTab();
		}
		
		protected function initHitPt() : void {
			var lHitZone	: DisplayObjectContainer	= getHitContainer();
			var lInd		: int						= 0;
			var lTmpX		: Number					= 0;
			var lTmpY		: Number					= 0;
			var lPt			: DisplayObject				= getHitPt( lHitZone, 0);
			
			while( lPt != null){
				lTmpX	+= lPt.x;
				lTmpY	+= lPt.y;
				
				lPt		= getHitPt( lHitZone, ++lInd);
			}
			
			G_XY	= new Point( lTmpX / lInd, lTmpY / lInd);
			NB_PT	= lInd;
		}
		
		protected function buildBTab() : void {
			var lHitZone	: DisplayObjectContainer	= getHitContainer();
			var lNbPt		: int						= NB_PT;
			var lBTab		: Array						= new Array();
			var lRad		: Number					= Math.PI / 180;
			var lGX			: Number					= G_XY.x;
			var lGY			: Number					= G_XY.y;
			var lPtA		: DisplayObject;
			var lPtB		: DisplayObject;
			var lIndA		: int;
			var lIndB		: int;
			var lBTabA		: Array;
			var lA			: Number;
			var lA1			: Number;
			var lA2			: Number;
			var lVX			: Number;
			var lVY			: Number;
			var lD			: Number;
			
			for ( lIndA = 0 ; lIndA < lNbPt ; lIndA++) {
				lBTab[ lIndA]	= new Array();
				lBTabA			= lBTab[ lIndA];
				
				for ( lIndB = 0 ; lIndB < lNbPt ; lIndB++) {
					if ( lIndA == lIndB) {
						lPtA			= getHitPt( lHitZone, lIndA);
						lA				= Math.atan2( lPtA.y - lGY, lPtA.x - lGX);
						lVX				= Math.cos( lA);
						lVY				= Math.sin( lA);
						lD				= getMaxDist( lVX, lVY, lPtA.x, lPtA.y, lIndA, lIndA);
						
						lBTabA[ lIndB]	= {
							x:	lVX * lD,
							y:	lVY * lD,
							c:	lVX,
							s:	lVY,
							d:	lD * lD
						};
					}else {
						lPtA			= getHitPt( lHitZone, lIndA);
						lPtB			= getHitPt( lHitZone, lIndB);
						lA1				= Math.atan2( lPtA.y - lGY, lPtA.x - lGX);
						lA2				= Math.atan2( lPtB.y - lGY, lPtB.x - lGX);
						
						if( lA2 < lA1) lA2 += 2 * Math.PI;
						
						lA				= ( lA1 + lA2) / 2;
						lVX				= Math.cos( lA);
						lVY				= Math.sin( lA);
						lD				= Math.max( getMaxDist( lVX, lVY, lPtA.x, lPtA.y, lIndA, lIndB), getMaxDist( lVX, lVY, lPtB.x, lPtB.y, lIndA, lIndB));
						
						lBTabA[ lIndB] = {
							x:	lVX * lD,
							y:	lVY * lD,
							c:	lVX,
							s:	lVY,
							d:	lD * lD
						};
					}
				}
			}
			
			B_TAB	= lBTab;
		}
		
		protected function getMaxDist( pFX : Number, pFY : Number, pX : Number, pY : Number, pIndA : Number, pIndB : Number) : Number {
			var lHitZone	: DisplayObjectContainer	= getHitContainer();
			var lNbPt		: int						= NB_PT;
			var lMax		: Number					= 0;
			var lPt			: DisplayObject;
			var lPtX		: Number;
			var lPtY		: Number;
			var lX			: Number;
			var lY			: Number;
			var lDist		: Number;
			var lInd		: int;
			
			for( lInd = ( pIndB + 1 == lNbPt ? 0 : pIndB + 1) ; lInd != pIndA ; lInd = ( lInd + 1 == lNbPt ? 0 : lInd + 1)){
				lPt		= getHitPt( lHitZone, lInd);
				lPtX	= lPt.x;
				lPtY	= lPt.y;
				lX		= lPtX - pX + pFY * ( pFX * ( lPtY - pY) - pFY * ( lPtX - pX));
				lY		= lPtY - pY + pFX * ( pFY * ( lPtX - pX) - pFX * ( lPtY - pY));
				lDist	= lX * lX + lY * lY;
				
				if( lDist > lMax) lMax = lDist;
			}
			
			return Math.sqrt( lMax);
		}
	}
}