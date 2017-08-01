package net.cyclo.fx {
	import flash.display.BitmapData;
	import flash.geom.Point;
	import net.cyclo.bitmap.BitmapMovieClipMgr;
	import net.cyclo.bitmap.BmpInfos;
	
	/**
	 * instance de fx qui effectue son affichage dans un BitmapData d'un FxGroundMgr
	 * 
	 * @author nico
	 */
	public class MyFx {
		/** frottement du système projection */
		protected var PROJ_FROT								: Number										= .03;
		/** frottement du système largage */
		protected var DROP_FROT								: Number										= .1;
		/** frottement du système gravité */
		protected var GRAV_FROT								: Number										= .1;
		
		/** vitesse min, en-dessous on stoppe */
		protected var MIN_SPEED								: Number										= .1;
		
		/** true pour un motif dont le bitmap carré présente de la transparence, laisser false pour un tracé opaque (plus rapide) */
		protected var BMP_IS_TRANS							: Boolean										= false;
		
		/** durée de vie max d'une particule */
		protected var LIFE_CTR_MAX							: int											= 20;
		
		/** idnentifiant de fx, unique pour un plan d'affichage ; null si pas défini */
		protected var _id									: String										= null;
		
		/** abscisse vituelle de scène */
		protected var _x									: Number										= 0;
		/** ordonnée virtuelle de scène */
		protected var _y									: Number										= 0;
		
		/** vecteur x unitaire direction de projection */
		protected var cos									: Number										= 0;
		/** vecteur y unitaire direction de projection */
		protected var sin									: Number										= 0;
		
		/** force de gravité appliquée au système ; null si aucune */
		protected var grav									: Point											= null;
		/** vitesse de système gravité */
		protected var gravSpeed								: Point											= null;
		
		/** valeur courante de vitesse de projection */
		protected var projSpeed								: Number										= 0;
		
		/** composante x de vitesse de largage */
		protected var dropSpeedX							: Number										= 0;
		/** composante y de vitesse de largage */
		protected var dropSpeedY							: Number										= 0;
		
		/** identifiant de bmp mc de fx ; null si non défini */
		protected var _bmpId								: String										= null;
		
		/** true pour adapter la time line du bmp mc à la durée de vie de la particule, false pour laisser jouer en boucle */
		protected var scaleAnim								: Boolean										= false;
		
		/** compteur de durée de vie */
		protected var lifeCtr								: int											= 0;
		
		/** gestionnaire de plan de fx */
		protected var mgr									: FxGroundMgr									= null;
		
		/** mode d'itération : retourne true si l'affichage a réussi et on conserve l'instance de fx, false si affichage fini et potentiellement destruction de fx */
		protected var doMode								: Function										= null;
		
		/**
		 * construction
		 */
		public function MyFx() { }
		
		/**
		 * accès à l'identifiant de fx
		 * @return	identifiant de fx, null si pas défini
		 */
		public function get id() : String { return _id; }
		
		/**
		 * initialisation
		 * @param	pMgr	le gestionnaire de plan de fx responsable de ce fx
		 * @param	pId		identifiant de fx, unique pour un plan
		 * @param	pX		abscisse vituelle initiale
		 * @param	pY		ordonnée vituelle initiale
		 */
		public function init( pMgr : FxGroundMgr, pId : String, pX : Number, pY : Number) : void {
			mgr		= pMgr;
			_id		= pId;
			_x		= pX;
			_y		= pY;
			
			setModeRun();
		}
		
		/**
		 * destruction
		 */
		public function destroy() : void {
			grav = null;
			gravSpeed = null;
			mgr = null;
		}
		
		/**
		 * on effectue l'itération de frame avec son rendu
		 * @return	true si l'affichage a réussi ; false si fin d'affichage et fx doit être détruit ; on retourne true quand même si on détecte que le fx n'est plus géré (::mgr == null) pour ignorer une procédure de destruction hors contexte
		 */
		public function doFrameRender() : Boolean {
			if( mgr != null) return doMode();
			else return true;
		}
		
		/**
		 * on effectue la physique de base du fx
		 */
		protected function doMove() : void {
			projSpeed	-= projSpeed * PROJ_FROT;
			dropSpeedX	-= dropSpeedX * DROP_FROT;
			dropSpeedX	-= dropSpeedX * DROP_FROT;
			
			if ( projSpeed < MIN_SPEED) projSpeed = 0;
			if ( dropSpeedX * dropSpeedX + dropSpeedY * dropSpeedY < MIN_SPEED * MIN_SPEED) dropSpeedX = dropSpeedY = 0;
			
			_x += projSpeed * cos + dropSpeedX;
			_y += projSpeed * sin + dropSpeedY;
			
			if ( grav != null) {
				if ( gravSpeed == null) gravSpeed = new Point();
				
				gravSpeed = gravSpeed.subtract( new Point( gravSpeed.x * GRAV_FROT, gravSpeed.y * GRAV_FROT)).add( grav);
				
				_x += gravSpeed.x;
				_y += gravSpeed.y;
			}
		}
		
		/**
		 * on passe en mode d'itération actif
		 */
		protected function setModeRun() : void { doMode = doModeRun; }
		
		/**
		 * on agit en mode d'itération active
		 * @return	false fin d'affichage, true on continue
		 */
		protected function doModeRun() : Boolean {
			var lBmpInfos	: BmpInfos;
			
			if ( lifeCtr++ < 0) return true;
			if ( lifeCtr > LIFE_CTR_MAX) return false;
			
			doMove();
			
			lBmpInfos = BitmapMovieClipMgr.getBmpInfos( _bmpId);
			
			if ( scaleAnim) {
				return mgr.render(
					lBmpInfos.getFrameInfos( 1 + Math.round( ( lBmpInfos.totalFrames - 1) * ( lifeCtr - 1) / LIFE_CTR_MAX)),
					_x,
					_y,
					BMP_IS_TRANS
				);
			}else {
				return mgr.render(
					lBmpInfos.getFrameInfos( 1 + ( lifeCtr - 1) % lBmpInfos.totalFrames),
					_x,
					_y,
					BMP_IS_TRANS
				);
			}
		}
	}
}