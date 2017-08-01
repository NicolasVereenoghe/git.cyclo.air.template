package net.cyclo.paddle {
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	
	/**
	 * un conrôleur à la souris de type joystick : inclinaison autour d'un axe de référence
	 * on gère la temporisation de position de down pour simuler le gameplay point'n click (si contrôle détecté par souris down)
	 * @author	nico
	 */
	public class MouseJoystick {
		/** indique si le contrôle n'est détecté que si la souris est down (true) ou tout le temps (false) */
		protected var IS_ONLY_MOUSE_DOWN_ACTIVE					: Boolean							= true;
		
		/** true pour activer la temporisation de position de souris si on relâche après une activation down */
		protected var IS_DOWN_TEMPO								: Boolean							= false;
		
		/** délai de temporisation de position de souris en ms */
		protected var DOWN_TEMPO_DELAY							: int								= 2000;
		/** rayon de proximité qui déclenche la fin de temporisation de position */
		protected var DOWN_TEMPO_RAY							: Number							= 50;
		
		/** distance de réf : rayon max du joystick ; -1 tant que non définie */
		protected var JOYSTICK_RAY_MAX							: Number							= -1;
		/** rayon minimum de déclenchement d'inclinaison de joystick */
		protected var JOYSTICK_RAY_MIN							: Number							= 0;
		
		/** échelle utilisée pour le vecteur d'inclinaison du joystick ; 1 pour un vecteur unitaire */
		protected var SCALE										: Number							= 1;
		
		/** moment de temporisation de position (getTimer) */
		protected var downTempoTime								: int								= -1;
		/** position down temporisée ; null si aucune ou finie */
		protected var downTempoPos								: Point								= null;
		
		/**
		 * constructeur : permet de modifier les propriétés par défaut du joystick
		 * @param	pIsOnlyMouseDownActive	true pour joystick actif uniquement si mouse down, false pour tout le temps actif
		 * @param	pCoefScreen				fraction de dimension d'écran à utiliser comme distance de ref (rayon max) du joystick
		 * @param	pRayMax					-1 pour utiliser la dimension min de l'écran comme distance de ref, ou donner une valeur de distance ici
		 * @param	pRayMin					rayon minimum de déclenchement du joystick
		 * @param	pScale					échelle utilisée pour le vecteur d'inclinaison du joystick ; 1 pour un vecteur unitaire
		 * @param	pIsDownTempo			true pour activer la temporisation de position de souris si on relâche après une activation down
		 * @param	pDownTempoDelay			délai max de temporisation de position en ms ; laisser -1 pour valeur par défaut
		 * @param	pDownTempoRay			rayon de proximité qui déclenche la fin de temporisation de position ; laisser -1 pour valeur par défaut
		 */
		public function MouseJoystick( pIsOnlyMouseDownActive : Boolean = true, pCoefScreen : Number = .5, pRayMax : Number = -1, pRayMin : Number = 0, pScale : Number = 1, pIsDownTempo : Boolean = false, pDownTempoDelay : int = -1, pDownTempoRay : Number = -1) {
			var lRect	: Rectangle;
			
			if( pIsOnlyMouseDownActive){
				if( pIsDownTempo){
					IS_DOWN_TEMPO = true;
					
					if ( pDownTempoDelay > 0) DOWN_TEMPO_DELAY = pDownTempoDelay;
					if ( pDownTempoRay > 0) DOWN_TEMPO_RAY = pDownTempoRay;
				}
			}else IS_ONLY_MOUSE_DOWN_ACTIVE	= false;
			
			JOYSTICK_RAY_MIN			= pRayMin;
			SCALE						= pScale;
			
			if ( pRayMax >= 0) JOYSTICK_RAY_MAX = pRayMax;
			else {
				lRect	= MobileDeviceMgr.getInstance().mobileFullscreenRect;
				
				JOYSTICK_RAY_MAX = Math.min( lRect.width, lRect.height) * pCoefScreen;
			}
		}
		
		/**
		 * on récupère l'écart d'inclinaisons en x, y mesuré depuis la position de référence (centre d'écran ou objet alternatif à spécifier)
		 * @param	pMouseAlt			objet alternatif de référence pour mesurer la distance du curseur de souris ; si non défini, on utilise le stage et son centre
		 * @return	{ x, y} les écarts d'inclinaisons des axes x, y du joystick mises à l'échelle 
		 */
		public function getInclinaison( pMouseAlt : DisplayObject = null) : Point {
			var lDest	: Point;
			var lRes	: Point;
			
			if ( IS_ONLY_MOUSE_DOWN_ACTIVE) {
				if ( IS_DOWN_TEMPO) {
					if( MySystem.isMouseDown) {
						downTempoTime = getTimer();
						
						if ( pMouseAlt) {
							downTempoPos	= new Point( pMouseAlt.parent.mouseX, pMouseAlt.parent.mouseY);
							lRes			= new Point( downTempoPos.x - pMouseAlt.x, downTempoPos.y - pMouseAlt.y);
						}else {
							downTempoPos	= new Point( MySystem.stage.mouseX, MySystem.stage.mouseY);
							lRes			= new Point( downTempoPos.x - MobileDeviceMgr.getInstance().screenWidth / 2, downTempoPos.x - MobileDeviceMgr.getInstance().screenHeight / 2);
						}
					}else if ( downTempoPos) {
						if ( getTimer() - downTempoTime >= DOWN_TEMPO_DELAY) {
							downTempoPos = null;
							return new Point();
						}
						
						if ( pMouseAlt) {
							if ( ( new Point( downTempoPos.x - pMouseAlt.x, downTempoPos.y - pMouseAlt.y)).length <= DOWN_TEMPO_RAY) {
								downTempoPos = null;
								return new Point();
							}else lRes = new Point( downTempoPos.x - pMouseAlt.x, downTempoPos.y - pMouseAlt.y);
						}else lRes = new Point( downTempoPos.x - MobileDeviceMgr.getInstance().screenWidth / 2, downTempoPos.x - MobileDeviceMgr.getInstance().screenHeight / 2);
					}else return new Point();
				}else if ( MySystem.isMouseDown) {
					if ( pMouseAlt) lRes = new Point( pMouseAlt.parent.mouseX - pMouseAlt.x, pMouseAlt.parent.mouseY - pMouseAlt.y);
					else lRes = new Point( MySystem.stage.mouseX - MobileDeviceMgr.getInstance().screenWidth / 2, MySystem.stage.mouseY - MobileDeviceMgr.getInstance().screenHeight / 2);
				}else return new Point();
			}else {
				if( ( ! MobileDeviceMgr.getInstance().isMobile()) || MySystem.isMouseDown){
					if ( pMouseAlt) lRes = new Point( pMouseAlt.parent.mouseX - pMouseAlt.x, pMouseAlt.parent.mouseY - pMouseAlt.y);
					else lRes = new Point( MySystem.stage.mouseX - MobileDeviceMgr.getInstance().screenWidth / 2, MySystem.stage.mouseY - MobileDeviceMgr.getInstance().screenHeight / 2);
				}else return new Point();
			}
			
			if ( lRes.length <= JOYSTICK_RAY_MIN) return new Point();
			else {
				lRes.normalize( Math.min( 1, ( lRes.length - JOYSTICK_RAY_MIN) / ( JOYSTICK_RAY_MAX - JOYSTICK_RAY_MIN)) * SCALE);
				
				return lRes;
			}
		}
	}
}