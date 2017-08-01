package net.cyclo.mycam {
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class MyCamera {
		protected var _MIN_DIST					: Number							= .5;
		
		protected var _INERT_DIST_X				: Number							= 100;
		protected var _MAX_INERTIA_DELT_X		: Number							= 220;
		protected var MAX_INERTIA_X				: Number							= 1 / 6;
		
		protected var _INERT_DIST_Y				: Number							= 100;
		protected var _MAX_INERTIA_DELT_Y		: Number							= 220;
		protected var MAX_INERTIA_Y				: Number							= 1 / 6;
		
		protected var INERTIA_DELT_I			: Number							= 1 / 26;//1 / 18;
		
		protected var inertiaLeft				: Number							= 0;
		protected var inertiaRight				: Number							= 0;
		protected var inertiaTop				: Number							= 0;
		protected var inertiaBottom				: Number							= 0;
		
		protected var _OFFSET_X					: Number							= 0;
		protected var _OFFSET_Y					: Number							= 0;
		
		protected var _SCREEN_W					: Number							= -1;
		protected var _SCREEN_H					: Number							= -1;
		
		protected var _x						: Number							= 0;
		protected var _y						: Number							= 0;
		
		protected var _clipRect					: Rectangle							= null;
		
		/** scale de zoom appliqué à la caméra */
		protected var _zoomScale				: Number							= 1;
		
		/** temporisation du dernier point de vue appliqué à la caméra */
		protected var lastView					: Point								= null;
		
		protected var isLimitLeft				: Boolean							= false;
		protected var isLimitRight				: Boolean							= false;
		protected var isLimitTop				: Boolean							= false;
		protected var isLimitBot				: Boolean							= false;
		
		protected var limitLeft					: Number							= 0;
		protected var limitRight				: Number							= 0;
		protected var limitTop					: Number							= 0;
		protected var limitBot					: Number							= 0;
		
		public function MyCamera() {}
		
		public function init( pInitX : Number, pInitY : Number, pOffsetX : Number, pOffsetY : Number, pScreenW : Number, pScreenH : Number) : void {
			_OFFSET_X	= pOffsetX;
			_OFFSET_Y	= pOffsetY;
			_SCREEN_W	= pScreenW;
			_SCREEN_H	= pScreenH;
			_x			= pInitX;
			_y			= pInitY;
			
			updateClipRect();
		}
		
		public function get zoomScale() : Number { return _zoomScale; }
		public function get screenMidX() : Number { return _x; }
		public function get screenMidY() : Number { return _y;}
		public function get x() : Number { return OFFSET_X - _x; }
		public function get y() : Number { return OFFSET_Y - _y; }
		public function get clipRect() : Rectangle { return _clipRect; }
		public function get SCREEN_W() : Number { return _SCREEN_W / _zoomScale; }
		public function get SCREEN_H() : Number { return _SCREEN_H  / _zoomScale; }
		
		public function flush() : void {
			inertiaLeft		= 0;
			inertiaRight	= 0;
			inertiaTop		= 0;
			inertiaBottom	= 0;
		}
		
		public function setLimitLeft( pLimit : Number) : void {
			isLimitLeft		= true;
			limitLeft		= pLimit;
		}
		
		public function setLimitRight( pLimit : Number) : void {
			isLimitRight	= true;
			limitRight		= pLimit;
		}
		
		public function setLimitTop( pLimit : Number) : void {
			isLimitTop		= true;
			limitTop		= pLimit;
		}
		
		public function setLimitBot( pLimit : Number) : void {
			isLimitBot		= true;
			limitBot		= pLimit;
		}
		
		public function freeLimitLeft() : void { isLimitLeft = false; }
		public function freeLimitRight() : void { isLimitRight = false; }
		public function freeLimitTop() : void { isLimitTop = false; }
		public function freeLimitBot() : void { isLimitBot = false; }
		
		/**
		 * on effectue un saut sans inertie de la caméra vers le nouveau point de vue
		 * @param	pView	point de vue dans repère caméra, visé par rapport au centre de caméra ; réf temporisée et modifiée en interne si on tappe une limite
		 */
		public function jumpTo( pView : Point) : void {
			inertiaLeft		= MAX_INERTIA_X;
			inertiaRight	= MAX_INERTIA_X;
			inertiaTop		= MAX_INERTIA_Y;
			inertiaBottom	= MAX_INERTIA_Y;
			
			lastView = pView;
			
			_x	= pView.x;
			_y	= pView.y;
			
			checkLimits();
			
			updateClipRect();
		}
		
		/**
		 * on fait glisser la caméra vers le point de vue précisé
		 * @param	pView		point de vue dans repère caméra, visé par rapport au centre de caméra ; réf temporisée et modifiée en interne si on tappe une limite
		 * @param	pZoomScale	forcer un scale de zoom sur la caméra ; laisser -1 pour garder celui en cours
		 */
		public function slideTo( pView : Point, pZoomScale : Number = -1) : void {
			var lDeltX	: Number	= pView.x - _x;
			var lDeltY	: Number	= pView.y - _y;
			var lRate	: Number;
			var lDelt	: Number;
			
			lastView = pView;
			
			if ( pZoomScale > 0) _zoomScale = pZoomScale;
			
			if ( lDeltX > INERT_DIST_X) {
				lRate			= Math.min( 1, ( lDeltX - INERT_DIST_X) / MAX_INERTIA_DELT_X);
				inertiaLeft		= 0;
				inertiaRight	+= ( lRate * MAX_INERTIA_X - inertiaRight) * INERTIA_DELT_I;
			}else if ( lDeltX < -INERT_DIST_X) {
				lRate			= Math.min( 1, -( lDeltX + INERT_DIST_X) / MAX_INERTIA_DELT_X);
				inertiaLeft		+= ( lRate * MAX_INERTIA_X - inertiaLeft) * INERTIA_DELT_I;
				inertiaRight	= 0;
			}else {
				inertiaLeft		-= inertiaLeft * INERTIA_DELT_I;
				inertiaRight	-= inertiaRight * INERTIA_DELT_I;
			}
			
			lDelt = Math.max( inertiaLeft, inertiaRight) * lDeltX;
			if ( Math.abs( lDelt) > MIN_DIST) _x += lDelt;
			
			if ( lDeltY > INERT_DIST_Y) {
				lRate			= Math.min( 1, ( lDeltY - INERT_DIST_Y) / MAX_INERTIA_DELT_Y);
				inertiaTop		= 0;
				inertiaBottom	+= ( lRate * MAX_INERTIA_Y - inertiaBottom) * INERTIA_DELT_I;
			}else if ( lDeltY < -INERT_DIST_Y) {
				lRate			= Math.min( 1, -( lDeltY + INERT_DIST_Y) / MAX_INERTIA_DELT_Y);
				inertiaTop		+= ( lRate * MAX_INERTIA_Y - inertiaTop) * INERTIA_DELT_I;
				inertiaBottom	= 0;
			}else {
				inertiaTop		-= inertiaTop * INERTIA_DELT_I;
				inertiaBottom	-= inertiaBottom * INERTIA_DELT_I;
			}
			
			lDelt = Math.max( inertiaTop, inertiaBottom) * lDeltY;
			if ( Math.abs( lDelt) > MIN_DIST) _y += lDelt;
			
			checkLimits();
			
			updateClipRect();
		}
		
		/**
		 * on demande une mise à jour des limites, si besoin on change le cadre rectangle de la caméra
		 * @return	true si tout reste en limite, false si on a au moins un cas de hors limite
		 */
		public function refreshLimits() : Boolean {
			if ( ! checkLimits()) {
				updateClipRect();
				
				return false
			}else return true;
		}
		
		protected function get OFFSET_X() : Number { return _OFFSET_X / _zoomScale; }
		protected function get OFFSET_Y() : Number { return _OFFSET_Y / _zoomScale; }
		protected function get MIN_DIST() : Number { return _MIN_DIST / _zoomScale; }
		protected function get INERT_DIST_X() : Number { return _INERT_DIST_X / _zoomScale; }
		protected function get INERT_DIST_Y() : Number { return _INERT_DIST_Y / _zoomScale; }
		protected function get MAX_INERTIA_DELT_X() : Number { return _MAX_INERTIA_DELT_X / _zoomScale; }
		protected function get MAX_INERTIA_DELT_Y() : Number { return _MAX_INERTIA_DELT_Y / _zoomScale; }
		
		/**
		 * on vérifie et on applique les limites de caméra
		 * @return	true si tout reste en limite, false si on a au moins un cas de hors limite
		 */
		protected function checkLimits() : Boolean {
			var lNoChange	: Boolean	= true;
			
			if ( isLimitLeft && _x < limitLeft + SCREEN_W / 2) {
				_x				= limitLeft  + SCREEN_W / 2;
				inertiaLeft		= 0;
				lNoChange		= false;
				lastView.x		= _x;
			}
			
			if ( isLimitRight && _x > limitRight - SCREEN_W / 2) {
				_x				= limitRight - SCREEN_W / 2;
				inertiaRight	= 0;
				lNoChange		= false;
				lastView.x		= _x;
			}
			
			if ( isLimitTop && _y < limitTop + SCREEN_H / 2) {
				_y				= limitTop + SCREEN_H / 2;
				inertiaTop		= 0;
				lNoChange		= false;
				lastView.y		= _y;
			}
			
			if ( isLimitBot && _y > limitBot - SCREEN_H / 2) {
				_y				= limitBot - SCREEN_H / 2;
				inertiaBottom	= 0;
				lNoChange		= false;
				lastView.y		= _y;
			}
			
			return lNoChange;
		}
		
		protected function updateClipRect() : void { _clipRect = new Rectangle( _x - SCREEN_W / 2, _y - SCREEN_H / 2, SCREEN_W, SCREEN_H); }
	}
}