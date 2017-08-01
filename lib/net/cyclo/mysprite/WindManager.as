package net.cyclo.mysprite {
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import net.cyclo.shell.MySystem;
	
	public class WindManager {
		protected var SCROLL_MAX_SPEED						: Number							= 1;
		
		protected var grounds								: Dictionary						= null;
		protected var groundsStack							: Array								= null;
		
		protected var lastX									: Number							= 0;
		protected var lastY									: Number							= 0;
		
		protected var angle									: Number							= 0;
		protected var cos									: Number							= 0;
		protected var sin									: Number							= 0;
		
		protected var INERT_DELAY							: int								= 20;
		protected var FADE_DELAY							: int								= 15;
		protected var SPEED									: Number							= 1;
		
		protected var ctrFade								: int								= 0;
		protected var ctrInert								: int								= 0;
		
		public function WindManager( pARad : Number = -1, pMaxSpeed : Number = -1) {
			grounds			= new Dictionary();
			groundsStack	= new Array();
			
			angle			= pARad != -1 ? pARad : Math.random() * Math.PI * 2;
			cos				= Math.cos( angle);
			sin				= Math.sin( angle);
			
			if ( pMaxSpeed != -1) SPEED = pMaxSpeed;
		}
		
		public function destroy() : void {
			grounds			= null;
			groundsStack	= null;
		}
		
		public function pushGround( pGnd : GroundMgr) : void {
			grounds[ pGnd] = groundsStack.length;
			groundsStack.push( new Point());
		}
		
		public function initView( pX : Number, pY : Number) : void {
			lastX	= pX;
			lastY	= pY;
		}
		
		public function slideView( pX : Number, pY : Number) : void {
			if ( ( pX - lastX) * ( pX - lastX) + ( pY - lastY) * ( pY - lastY) < SCROLL_MAX_SPEED * SCROLL_MAX_SPEED) {
				if( ( ctrFade != 0 || ctrInert-- <= 0) && ctrFade < FADE_DELAY) ctrFade++;
			}else if ( ctrFade > 0) {
				ctrFade--;
			}else {
				ctrInert = INERT_DELAY;
			}
			
			lastX	= pX;
			lastY	= pY;
		}
		
		public function getGroundOffset( pGnd : GroundMgr) : Point {
			if ( grounds[ pGnd] != null) return groundsStack[ grounds[ pGnd]];
			else return new Point();
		}
		
		public function getNUpdateView( pGnd : GroundMgr) : Point {
			var lSpeed	: Number;
			var lPt		: Point;
			var lI		: int;
			
			if ( grounds[ pGnd] != null) {
				lI		= grounds[ pGnd];
				lPt		= groundsStack[ lI];
				
				if ( ctrFade > 0) {
					lSpeed	= SPEED * ctrFade / FADE_DELAY;
					lPt.x	+= cos * lSpeed;
					lPt.y	+= sin * lSpeed;
				}
				
				return lPt;
			}else return new Point();
		}
		
		public function isWindy() : Boolean { return ctrFade > 0; }
		
		public function tmpForceLock() : void {
			ctrFade = 0;
			ctrInert = INERT_DELAY;
		}
	}
}