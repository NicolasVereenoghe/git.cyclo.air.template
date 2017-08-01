package net.cyclo.paddle {
	import flash.display.DisplayObject;
	import flash.events.AccelerometerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.sensors.Accelerometer;
	import flash.utils.getTimer;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	
	/**
	 * accéléromètre avec plusieurs inclinaisons neutres de gérées, et transition d'une inclinaison neutre à l'autre automatique
	 * @author nico
	 */
	public class AcceleroMultiMode {
		/** interval de temps en ms par défaut de prise d'échantillon de l'accéléromètre */
		protected var DEFAULT_INTERVAL						: Number							= 67;
		/** taille max par défaut de la pile d'échantillons */
		protected var DEFAULT_STACK_MAX						: int								= 4;
		
		/** coef de distance max depuis le centre de l'écran, qui sert de référence pour mesurer l' accélération d'un axe à partir du curseur de la souris */
		protected var _MOUSE_DIST_MAX_COEF					: Number							= .5;
		
		/** instance d'accéléromètre */
		protected var accelerometer							: Accelerometer						= null;
		
		/** taille max de la pile d'échantillons */
		protected var accelStackMax							: int								= -1;
		
		/** pile d'échantillons d'inclinaisons des axes x, y sur ] -PI .. PI] {x,y} ; null si pas encore initialisé */
		protected var accelStack							: Array								= null;
		
		/** échantillon de référence donnant l'inclinaison des axes x, y, z sur [ -PI/2 .. PI/2] {x,y,z} ; null si pas encore initialisé */
		protected var refXYZ								: Object							= null;
		
		/** distance du point z par rapport au point de référence à partir de laquelle on considère qu'il y a échappement */
		protected var REF_DIST_ESC							: Number							= .75;//.88;//.75;
		/** distance du point z par rapport au point de référence à partir de laquelle on considère qu'il y a capture */
		protected var REF_DIST_CAPT							: Number							= .2;
		
		/** temps en ms à partir duquel on effectue un échappement vers le point de réf temporisé */
		protected var ESCAPE_TIME							: int								= 200;// 300;
		/** temps du dernier check de point de référence */
		protected var lastCheck								: int								= -1;
		/** compteur de temps échapé vers un autre point de référence */
		protected var ctrRefEsc								: int								= -1;
		/** temporisation d'un nouveau point de référence vioisin avec inclinaison des axes x, y, z sur [ -PI/2 .. PI/2] {x,y,z} ; null si aucun*/
		protected var tmpCheck								: Object							= null;
		/** flag indiquant si la position de ref est verrouillée (true) ou pas (false) */
		protected var isRefLocked							: Boolean							= false;
		
		/** switcher qui capte la notification de changement de référentiel ; null si aucun */
		protected var switcher								: IAcceleroModeSwitcher				= null;
		
		/** flag indiquant si on est en pause (true) ou pas (false) */
		protected var isPause								: Boolean							= true;
		
		/**
		 * détermine si la détection d'inclinaison est supportée par ce composant ; on ne garantie le fonctionnement quand dans une coque AIR
		 * @return	true si supproté, false sinon
		 */
		public static function get isSupported() : Boolean {
			CONFIG::AccDisabled {
				return false;
			}
			
			CONFIG::AIR {
				return Accelerometer.isSupported;
			}
			
			return false;
		}
		
		/**
		 * construction : on initialise l'accéléromètre
		 * par défaut, on est en pause
		 * @param	pSwitcher	switcher qui capte la notification de changement de référentiel ; null si aucun
		 * @param	pInterval	temps en ms de prise d'échantillon de l'accéléromètre ; laisser -1 pour prendre celui défini par défaut
		 * @param	pStackMax	taille max de la pile d'échantillons d'accéléromètre ; laisser -1 pour garder la config par défaut
		 * @param	pRefXYZ		position de référence initiale, null si aucune de définie
		 */
		public function AcceleroMultiMode( pSwitcher : IAcceleroModeSwitcher = null, pInterval : Number = -1, pStackMax : int = -1, pRefXYZ : Object = null) {
			if ( pStackMax > 0) accelStackMax = pStackMax;
			else accelStackMax = DEFAULT_STACK_MAX;
			
			if ( pRefXYZ != null) {
				refXYZ		= pRefXYZ;
				accelStack	= new Array();
			}
			
			switcher = pSwitcher;
			
			if( isSupported){
				accelerometer = new Accelerometer();
				
				accelerometer.setRequestedUpdateInterval( pInterval > 0 ? pInterval : DEFAULT_INTERVAL);
				accelerometer.addEventListener( AccelerometerEvent.UPDATE, onAccelUpdate);
			}
		}
		
		/**
		 * destructeur
		 */
		public function destroy() : void {
			if( accelerometer) accelerometer.removeEventListener( AccelerometerEvent.UPDATE, onAccelUpdate);
			
			isPause			= true;
			switcher		= null;
			accelerometer	= null;
			accelStack		= null;
			refXYZ			= null;
			tmpCheck		= null;
		}
		
		/** on change la valeur de référence de coef de distance max au centre quand la souris sert de remplacement à l'accéléromètre
		 * @param	pVal	nouvelle valeur de coef : R+*
		 */
		public function set MOUSE_DIST_MAX_COEF( pVal : Number) : void { _MOUSE_DIST_MAX_COEF = pVal; }
		
		/**
		 * on bascule la pause de l'écoute de l'accéléromètre
		 * @param	pIsPause	true pour pauser, false pour relancer
		 * @param	pFlush		true pour vider la pile de positions remporisées (remise à zéro du contrôleur), false pour conserver ; effective uniquement en cas de relance (pIsPause == false)
		 */
		public function switchPause( pIsPause : Boolean, pFlush : Boolean = true) : void {
			var lI	: int;
			
			if ( pIsPause != isPause) {
				isPause	= pIsPause;
				
				if ( ! pIsPause) {
					if ( pFlush && accelStack != null) {
						accelStack = new Array();
						
						for ( lI = 0 ; lI < accelStackMax ; lI++) accelStack.push( { x: 0, y: 0 } );
					}
					
					if ( tmpCheck != null) lastCheck = getTimer();
				}
			}
		}
		
		/**
		 * on bascule l'état de verrou de changement de position de réf
		 * @param	pIsLocked	true pour verrouiller le changement de position de référence, false pour déverrouiller
		 */
		public function switchLock( pIsLocked : Boolean) : void { isRefLocked = pIsLocked;}
		
		/**
		 * on reset la position de référence, ce qui doit entrainer une recherche si le verrou de changement est ouvert
		 */
		public function resetRef() : void {
			refXYZ		= null;
			accelStack	= null;
		}
		
		/**
		 * on force la position de référence
		 * @param	pRefXYZ		nouvelle position de référence avec l'inclinaison des axes x, y, z sur [ -PI/2 .. PI/2]
		 */
		public function forceRef( pRefXYZ : Object) : void {
			var lI	: int;
			
			refXYZ		= pRefXYZ;
			accelStack	= new Array();
			tmpCheck	= null;
			ctrRefEsc	= 0;
			
			for ( lI = 0 ; lI < accelStackMax ; lI++) accelStack.push( { x: 0, y: 0 } );
		}
		
		/**
		 * on récupère l'écart d'inclinaisons en x, y mesuré depuis la position de référence
		 * @param	pIsOrientRelative	mettre true pour obtenir une inclinaison relative à l'orientation, laisser false pour une inclinaison absolue
		 * @param	pMouseAlt			objet alternatif de référence pour mesurer la distance du curseur de souris ; si non défini, on utilise le stage et son centre
		 * @return	{ x, y} les écarts d'inclinaisons des axes x, y en radians sur [ -PI .. PI]
		 */
		public function getInclinaison( pIsOrientRelative : Boolean = false, pMouseAlt : DisplayObject = null) : Point {
			var lRes	: Point;
			var lRect	: Rectangle;
			var lAccel	: Object;
			var lLen	: int;
			var lI		: int;
			var lTmp	: Number;
			
			if ( isSupported) {
				lRes	= new Point();
				
				if ( accelStack != null && accelStack.length > 0) {
					lLen	= accelStack.length;
					
					for ( lI = 0 ; lI < lLen ; lI++) {
						lAccel	= accelStack[ lI];
						lRes.x	+= lAccel.x;
						lRes.y	+= lAccel.y;
					}
					
					lRes.x	/= lLen;
					lRes.y	/= lLen;
					
					if ( pIsOrientRelative) {
						if ( refXYZ.x == 0) {
							if ( refXYZ.y < 0) {
								// 180°
								lRes.x	= -lRes.x;
								lRes.y	= -lRes.y;
							}
						}else {
							lTmp = lRes.x;
							
							if ( refXYZ.x >= 0) {
								// 90°
								lRes.x	= -lRes.y;
								lRes.y	= lTmp;
							}else {
								// -90°
								lRes.x	= lRes.y;
								lRes.y	= -lTmp;
							}
						}
					}
				}
			}else {
				lRect	= MobileDeviceMgr.getInstance().mobileFullscreenRect;
				
				if ( pMouseAlt) {
					lRes	= new Point( pMouseAlt.x - pMouseAlt.parent.mouseX, pMouseAlt.parent.mouseY - pMouseAlt.y);
				}else{
					lRes	= new Point( MobileDeviceMgr.getInstance().screenWidth / 2 - MySystem.stage.mouseX, MySystem.stage.mouseY - MobileDeviceMgr.getInstance().screenHeight / 2);
				}
				
				lRes.normalize( Math.min( 1, lRes.length / ( Math.min( lRect.height, lRect.width) * _MOUSE_DIST_MAX_COEF)) * Math.PI / 8);
			}
			
			return lRes;
		}
		
		/**
		 * on recherche la position de référence la plus proche
		 * @param	pXYZ	position de actuelle avec l'inclinaison des axes x, y, z sur [ -PI/2 .. PI/2] {x, y, z}
		 * @return	position de référence la plus proche calculée avec l'inclinaison des axes x, y, z sur [ -PI/2 .. PI/2]
		 */
		protected function getRefXYZ( pXYZ : Object) : Object {
			var lPI2	: Number	= Math.PI / 2;
			var lPI4	: Number	= lPI2 / 2;
			var lRes	: Object;
			var lPart	: Number;
			var lZ		: Number;
			
			if ( Math.abs( pXYZ.x) > Math.abs( pXYZ.y)) {
				// portrait
				lPart	= Math.round( pXYZ.x / lPI4) * lPI4;
				
				lRes = {
					x: lPart,
					y: 0
				};
			}else {
				// paysage
				lPart	= Math.round( pXYZ.y / lPI4) * lPI4;
				
				lRes = {
					x: 0,
					y: lPart
				};
			}
			
			if ( pXYZ.z > 0) {
				if ( lPart < 0) lRes.z = lPart + lPI2;
				else lRes.z = lPI2 - lPart;
			}else {
				if ( lPart < 0) lRes.z = -( lPart + lPI2);
				else lRes.z = lPart - lPI2;
			}
			
			return lRes;
		}
		
		/**
		 * on calcule l'écart d'inclinaisons des axes x, y par rapport à une position de référence
		 * @param	pRefXYZ	position de référence avec l'inclinaison des axes x, y, z sur [ -PI/2 .. PI/2] {x, y, z}
		 * @param	pXYZ	position de actuelle avec l'inclinaison des axes x, y, z sur [ -PI/2 .. PI/2] {x, y, z}
		 * @return	{ x, y} les écarts d'inclinaisons des axes x, y en radians sur [ -PI .. PI] par rapport à la position de réf
		 */
		protected function getInclinaisonFromRef( pRefXYZ : Object, pXYZ : Object) : Object {
			var lRes	: Object	= { x: 0, y: 0 };
			
			if ( pRefXYZ.y == 0) {
				// portrait
				lRes.y	= pXYZ.y - pRefXYZ.y;
				
				if ( Math.abs( pRefXYZ.z) < .1) {
					// verticale
					if ( pRefXYZ.x > 0) lRes.x = pRefXYZ.z - pXYZ.z;
					else lRes.x = pXYZ.z - pRefXYZ.z;
				}else{
					// incliné
					lRes.x	= pXYZ.x - pRefXYZ.x;
				}
			}else {
				// paysage
				lRes.x	= pXYZ.x - pRefXYZ.x;
				
				if ( Math.abs( pRefXYZ.z) < .1) {
					// verticale
					if ( pRefXYZ.y > 0) lRes.y	= pRefXYZ.z - pXYZ.z;
					else lRes.y	= pXYZ.z - pRefXYZ.z;
				}else{
					// incliné
					lRes.y	= pXYZ.y - pRefXYZ.y;
				}
			}
			
			return lRes;
		}
		
		/**
		 * vérification de fixation au point de référence actuel
		 * @param	pXYZ	position de actuelle avec l'inclinaison des axes x, y, z sur [ -PI/2 .. PI/2] {x, y, z}
		 */
		protected function checkRef( pXYZ : Object) : void {
			var lRef2		: Object;
			var lTime		: int;
			
			if ( ! isRefLocked) {
				lRef2 = getRefXYZ( pXYZ);
				
				if ( lRef2.x != refXYZ.x || lRef2.y != refXYZ.y || lRef2.z != refXYZ.z) {
					if ( dist2( pXYZ, refXYZ) > REF_DIST_ESC) {
						
						//if ( dist2( pXYZ, lRef2) < REF_DIST_CAPT) {
							lTime	= getTimer();
							
							if ( tmpCheck == null || tmpCheck.x != lRef2.x || tmpCheck.y != lRef2.y || tmpCheck.z != lRef2.z) {
								tmpCheck	= lRef2;
								lastCheck	= lTime;
								ctrRefEsc	= 0;
							}else {
								ctrRefEsc	+= lTime - lastCheck;
								lastCheck	= lTime;
								
								if ( ctrRefEsc > ESCAPE_TIME) {
									lRef2		= refXYZ;
									refXYZ		= tmpCheck;
									tmpCheck	= null;
									ctrRefEsc	= 0;
									accelStack	= new Array();
									
									if ( switcher != null) switcher.onRefChange( lRef2, refXYZ);
								}
							}
							
							return;
						//}
					}
				}
				
				tmpCheck = null;
			}
		}
		
		/**
		 * calcul de distance au carré entre 2 points d'espace
		 * @param	pXYZ1	points 1 avec { x, y, z}
		 * @param	pXYZ2	points 2 avec { x, y, z}
		 * @return	distance au carré
		 */
		protected function dist2( pXYZ1 : Object, pXYZ2 : Object) : Number {
			var lX	: Number	= pXYZ1.x - pXYZ2.x;
			var lY	: Number	= pXYZ1.y - pXYZ2.y;
			var lZ	: Number	= pXYZ1.z - pXYZ2.z;
			
			//MySystem.traceDebug( "" + Math.round( ( lX * lX + lY * lY + lZ * lZ) * 100) / 100);
			
			return lX * lX + lY * lY + lZ * lZ;
		}
		
		/**
		 * on capture un échantillon d'accéléromètre
		 * @param	pE	event de mise à jour d'échantillon
		 */
		protected function onAccelUpdate( pE : AccelerometerEvent) : void {
			var lXYZ	: Object;
			
			if( ! isPause){
				if( pE.accelerationX != 0 || pE.accelerationY != 0 || pE.accelerationZ != 0){
					lXYZ = {
						x:	Math.asin( Math.max( -1, Math.min( 1, pE.accelerationX))),
						y:	Math.asin( Math.max( -1, Math.min( 1, pE.accelerationY))),
						z:	Math.asin( Math.max( -1, Math.min( 1, pE.accelerationZ)))
					};
					
					if ( accelStack == null) {
						accelStack	= new Array();
						refXYZ		= getRefXYZ( lXYZ);
						
						if( switcher != null) switcher.onRefChange( null, refXYZ);
					}else if ( accelStack.length > accelStackMax) accelStack.shift();
					
					if( accelStack != null){
						accelStack.push( getInclinaisonFromRef( refXYZ, lXYZ));
						
						checkRef( lXYZ);
					}
				}
			}
		}
	}
}