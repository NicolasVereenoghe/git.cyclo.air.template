package net.cyclo.paddle {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.PerspectiveProjection;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * capture la notification de changement de référentiel du composant de gestion d'accéléromètre (AcceleroMultiMode)
	 * @author nico
	 */
	public class AcceleroModeSwitcher implements IAcceleroModeSwitcher {
		/** conteneur où faire le rendu du switch de mode ; visible que si itération d'animation de switch */
		protected var fxContainer				: Sprite					= null;
		/** bg du rendu du switch */
		protected var fxBg						: DisplayObject				= null;
		/** conteneur du rendu bitmap de l'effet de switch ; centre de transformation confondu avec le centre de l'écran */
		protected var fxBmpContainer			: DisplayObjectContainer	= null;
		
		/** contenu à prendre en photo et éteindre lors du fx de swicth */
		protected var content					: DisplayObject				= null;
		
		/** couleur ARGB du fond pris en photo */
		protected var contentBGColor			: uint						= 0;
		
		/** durée d'un cycle d'anim de rendu d'effet en nombre de frames */
		protected var ANIM_TOTAL_FRAMES			: int						= 20;
		/** grain de l'anim de rendu en nombre de frames persistantes pour donner un effet de saccade(min = 1) */
		protected var RENDER_GRIT				: Number					= 2.5;
		/** amplitude d'effet de rotation en degrés de l'anim de switch sur les axes x, y */
		protected var ANIM_XY_ROT_MAX			: Number					= 30;
		/** amplitude d'effet de rotation en degrés de l'anim de switch sur l'axe z */
		protected var ANIM_Z_ROT_MAX			: Number					= 20;
		/** angle de vue dans la projection 3d de rotation en degrés */
		protected var FIELD_OF_VIEW				: Number					= 20;
		/** qualité de raster de contenu */
		protected var RASTER_Q					: String					= StageQuality.LOW;
		/** scale de qualité du bitmap "print screen" */
		protected var SCALE_Q					: Number					= 1;
		
		/** compteur d'itérations de l'anim de rendu d'effet */
		protected var ctrAnim					: int						= 0;
		/** inclinaison de départ de l'anim de rendu de switch, des axes x, y, z en degrés */
		protected var animFromXYZ				: Object					= null;
		
		/** flag indiquant si le composant est en pause (true) ou pas (false) */
		protected var isPause					: Boolean					= false;
		
		/** écouteur de changement de position, début / fin d'anim, null si aucun */
		protected var switchListener			: ISwitchModeListener		= null;
		
		/**
		 * donne l'orientation d'un contenu fenêtré en fonction de l'orientation de réf de device spécifiée
		 * @param	pXYZ	{ x, y, z} du nouveau référentiel ( inclinaison des axes x, y, z sur [ -PI/2 .. PI/2])
		 * @return	orientation de contenu fenêtré en degrés sur { -90, 0, 90, 180}
		 */
		public static function getPopRot( pXYZ : Object) : int {
			if ( pXYZ.x == 0) {
				if ( pXYZ.y >= 0) return 0;
				else return 180;
			}else {
				if ( pXYZ.x >= 0) return 90;
				else return -90;
			}
		}
		
		/**
		 * construction
		 * @param	pFXContainer	conteneur où faire le rendu du switch de mode
		 * @param	pContent		contenu à prendre en photo et éteindre lors du fx de swicth
		 * @param	pContentBGColor	couleur ARGB du fond pris en photo
		 * @param	pSwitchBGColor	couleur RGB du fond de rendu de switch
		 * @param	pSwitchListener	écouteur de changement de position, début / fin d'anim, null si aucun
		 */
		public function AcceleroModeSwitcher( pFXContainer : Sprite, pContent : DisplayObject, pContentBGColor : uint, pSwitchBGColor : uint, pSwitchListener : ISwitchModeListener = null) {
			var lRect	: Rectangle				= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			var lPersp	: PerspectiveProjection	= new PerspectiveProjection();
			var	lGraph	: Graphics;
			
			fxContainer				= pFXContainer;
			fxBg					= pFXContainer.addChild( new Sprite());
			fxBmpContainer			= pFXContainer.addChild( new Sprite()) as DisplayObjectContainer;
			content					= pContent;
			contentBGColor			= pContentBGColor;
			switchListener			= pSwitchListener;
			
			fxBmpContainer.x		= ( lRect.left + lRect.right) / 2;
			fxBmpContainer.y		= ( lRect.top + lRect.bottom) / 2;
			lPersp.projectionCenter							= fxBmpContainer.localToGlobal( new Point());
			lPersp.fieldOfView								= FIELD_OF_VIEW;
			fxBmpContainer.transform.perspectiveProjection	= lPersp;
			
			lGraph					= ( fxBg as Sprite).graphics;
			lGraph.beginFill( pSwitchBGColor);
			lGraph.drawRect( lRect.left, lRect.top, lRect.width, lRect.height);
			lGraph.endFill();
			
			fxContainer.visible		= false;
		}
		
		/**
		 * on pause l'anim de transition
		 * @param	pIsPause	true pour pauser, false pour relancer
		 */
		public function switchPause( pIsPause : Boolean) : void { isPause = pIsPause;}
		
		/** @inheritDoc */
		public function onRefChange( pFrom : Object, pTo : Object) : void {
			var lZone	: Rectangle		= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			var lQOrig	: String		= MySystem.stage.quality;
			var lMtrx	: Matrix;//		= new Matrix( 1, 0, 0, 1, Math.floor( -lZone.left), Math.floor( -lZone.top));
			var lW		: int			= Math.ceil( lZone.width) + 1;
			var lH		: int			= Math.ceil( lZone.height) + 1;
			var lDraw	: BitmapData;
			var lBmp	: Bitmap;
			
			if ( switchListener != null) {
				switchListener.onRefChange( pFrom, pTo);
				switchListener.onSwitchModeAnim( true);
			}
			
			if( pFrom != null){
				if ( isFraming() && fxBmpContainer.numChildren > 0) {
					lDraw	= ( fxBmpContainer.getChildAt( 0) as Bitmap).bitmapData;
					
					resetFxBmpContainer( false);
				}else{
					MySystem.stage.quality	= RASTER_Q;
					content.scaleX			= content.scaleY = SCALE_Q;
					lMtrx					= content.transform.matrix;
					lMtrx.tx				= Math.floor( -lZone.left * SCALE_Q);
					lMtrx.ty				= Math.floor( -lZone.top * SCALE_Q);
					
					lDraw	= new BitmapData( Math.ceil( lW * SCALE_Q), Math.ceil( lH * SCALE_Q), true, contentBGColor);
					lDraw.draw( content, lMtrx/*, null, null, null, _isSmooth*/);
					
					content.scaleX			= content.scaleY = 1;
					MySystem.stage.quality	= lQOrig;
				}
				
				lBmp		= new Bitmap( lDraw, "never", true);
				lBmp.scaleX	= lBmp.scaleY = 1 / SCALE_Q;
				lBmp.x		= -lW / 2;
				lBmp.y		= -lH / 2;
				
				fxBmpContainer.addChild( lBmp);
			}else if ( isFraming()) resetFxBmpContainer();
			
			initEffect( pFrom, pTo);
		}
		
		/**
		 * indique si l'anim de transition est itérée
		 * @return	true si itérée, false sinon
		 */
		protected function isFraming() : Boolean { return fxContainer.visible; }
		
		/**
		 * on reset les paramètres de déformation 3d du conteneur du rendu bitmap de switch, on libère son contenu
		 * @param	true pour libérer la mémoire du bitmap (par défaut), false sinon
		 */
		protected function resetFxBmpContainer( pDispose : Boolean = true) : void {
			var lDisp	: DisplayObject;
			var lData	: BitmapData;
			
			if ( fxBmpContainer.numChildren > 0) {
				lDisp	= fxBmpContainer.getChildAt( 0);
				lData	= ( lDisp as Bitmap).bitmapData;
				
				UtilsMovieClip.clearFromParent( lDisp);
				
				if ( pDispose && lData != null && lData.width != 0) lData.dispose();
			}
			
			fxBmpContainer.rotationX	= 0;
			fxBmpContainer.rotationY	= 0;
			fxBmpContainer.rotationZ	= 0;
		}
		
		/**
		 * on initialise le processus d'effet de switch
		 * @param	pFrom	{ x, y, z} de l'ancien référentiel ( inclinaison des axes x, y, z sur [ -PI/2 .. PI/2]) ; null si pas d'antécédent
		 * @param	pTo		{ x, y, z} du nouveau référentiel ( inclinaison des axes x, y, z sur [ -PI/2 .. PI/2])
		 */
		protected function initEffect( pFrom : Object, pTo : Object) : void {
			var lRect	: Rectangle				= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			var lPersp	: PerspectiveProjection	= new PerspectiveProjection();
			var lDif	: Number;
			
			if( ! isFraming()){
				fxContainer.addEventListener( Event.ENTER_FRAME, doFrame);
				
				fxContainer.visible	= true;
			}
			
			if( pFrom != null){
				ctrAnim			= 0;
				fxBg.visible	= true;
				content.visible	= false;
				
				if ( pFrom.x == 0 && pTo.x == 0) {
					if ( pFrom.z * pTo.z <= 0) {
						if ( pTo.y >= 0 && pFrom.y >= 0) lDif = pFrom.z - pTo.z;
						else lDif = pTo.z - pFrom.z;
					}else {
						if ( pTo.z > 0) lDif = pTo.y - pFrom.y;
						else lDif = pFrom.y - pTo.y;
					}
					
					fxBmpContainer.rotationX	= lDif < 0 ? ANIM_XY_ROT_MAX : -ANIM_XY_ROT_MAX;
					animFromXYZ					= { x: fxBmpContainer.rotationX, y: 0, z: 0 };
				}else if ( pFrom.y == 0 && pTo.y == 0) {
					if ( pFrom.z * pTo.z <= 0) {
						if ( pTo.x >= 0 && pFrom.x >= 0) lDif = pFrom.z - pTo.z;
						else lDif = pTo.z - pFrom.z;
					}else {
						if ( pTo.z > 0) lDif = pTo.x - pFrom.x;
						else lDif = pFrom.x - pTo.x;
					}
					
					fxBmpContainer.rotationY	= lDif < 0 ? ANIM_XY_ROT_MAX : -ANIM_XY_ROT_MAX;
					animFromXYZ					= { x: 0, y: fxBmpContainer.rotationY, z: 0 };
				}else {
					if ( pFrom.x == 0) {
						if ( pFrom.y > 0) lDif = pTo.x;
						else lDif = -pTo.x;
					}else {
						if ( pFrom.x > 0) lDif = -pTo.y;
						else lDif = pTo.y;
					}
					
					fxBmpContainer.rotationZ	= lDif > 0 ? ANIM_Z_ROT_MAX : -ANIM_Z_ROT_MAX;
					animFromXYZ					= { x: 0, y: 0, z: fxBmpContainer.rotationZ };
				}
			}else {
				ctrAnim			= ANIM_TOTAL_FRAMES;
				content.visible	= true;
				fxBg.visible	= false;
			}
		}
		
		/**
		 * méthode d'itération de mode du processus d'effet de switch
		 * @param	pE	event de framing
		 */
		protected function doFrame( pE : Event) : void {
			var lRate	: Number;
			
			if( ! isPause) {
				if ( ctrAnim < ANIM_TOTAL_FRAMES) {
					ctrAnim++;
					
					lRate	= 1 - Math.floor( ctrAnim / RENDER_GRIT) * RENDER_GRIT / ANIM_TOTAL_FRAMES;
					
					fxBmpContainer.rotationX	= lRate * animFromXYZ.x;
					fxBmpContainer.rotationY	= lRate * animFromXYZ.y;
					fxBmpContainer.rotationZ	= lRate * animFromXYZ.z;
				}else onEffectEnd();
			}
		}
		
		/**
		 * processus de traitement de fin d'anim de switch
		 */
		protected function onEffectEnd() : void {
			fxContainer.removeEventListener( Event.ENTER_FRAME, doFrame);
			
			fxContainer.visible	= false;
			content.visible		= true;
			
			resetFxBmpContainer();
			
			if ( switchListener != null) switchListener.onSwitchModeAnim( false);
		}
	}
}