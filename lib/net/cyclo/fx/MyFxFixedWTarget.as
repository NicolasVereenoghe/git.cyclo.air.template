package net.cyclo.fx {
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.cyclo.bitmap.BitmapMovieClipMgr;
	import net.cyclo.bitmap.BmpInfos;
	import net.cyclo.shell.device.MobileDeviceMgr;
	
	/**
	 * une particule fixe dans le conteneur de jeu, qui a pour destination un point fixe à l'écran (prévu pour effet de HUD)
	 * coordonnées virtuelles _x, _y réexprimées pour êtr erelatives au repère du conteneur du jeu, non scrollé
	 * 
	 * @author nico
	 */
	public class MyFxFixedWTarget extends MyFx {
		/** racine de nom de bmp mc de particule de burst */
		protected var BMP_RADIX										: String										= "winParticule_motif";
		
		/** valeur max de vitesse de projection */
		protected var PROJ_SPEED_MAX								: Number										= 9;
		
		/** altération / exagération de vitesse subie à l'init en fonction de l'écart entre l'orientation de projection et la destination finale */
		protected var ALT_INIT_SPEED								: Number										= 3;
		
		/** force de chute vers la cible d'écran */
		protected var W_TARGET_FORCE								: Number										= 3;
		/** vitesse max de chute */
		protected var W_TARGET_MAX_SPEED							: Number										= 30;
		/** rayon de proximité avec la cible */
		protected var W_TARGET_RAY									: Number										= 80;
		
		/** coordonnées de destination dans le repère de conteneur de jeu */
		protected var wTarget										: Point											= null;
		
		/** vitesse de ciblage */
		protected var wSpeed										: Point											= null;
		
		/**
		 * construction
		 * @param	pToWXY			coordonnées de destination dans repère de conteneur de jeu
		 * @param	pCos			vecteur x unitaire direction initiale de projection
		 * @param	pSin			vecteur y unitaire direction initiale de projection
		 * @param	pPartNum		numéro de particule [ 1 <=> intensité min .. n <=> intensité max] (utilisé en suffix de nom d'asset)
		 * @param	pTotal			nombre de particules de la palette
		 * @param	pRadix			racine de nom de bmp mc à utiliser à la place de celui par défaut ; null pour garder valeur par défaut
		 * @param	pDelay			délai en frame avant de lancer l'affichage de la particule, pendant ce temps on est dormant ; laisser 0 pour immédiat
		 * @param	pIsTrans		true pour un motif dont le bitmap carré présente de la transparence, laisser false pour un tracé opaque (plus rapide)
		 */
		public function MyFxFixedWTarget( pToWXY : Point, pCos : Number, pSin : Number, pPartNum : int = 1, pTotal : int = 1, pRadix : String = null, pDelay : int = 0, pIsTrans : Boolean = false) {
			var lDelt	: Point;
			
			super();
			
			if ( pRadix != null) BMP_RADIX = pRadix;
			
			wTarget			= pToWXY;
			cos				= pCos;
			sin				= pSin;
			_bmpId			= BMP_RADIX + pPartNum;
			projSpeed		= PROJ_SPEED_MAX * pPartNum / pTotal;
			lifeCtr			= -pDelay;
			BMP_IS_TRANS	= pIsTrans;
			wSpeed			= new Point();
			LIFE_CTR_MAX	= 8;
		}
		
		/** @inheritDoc */
		override public function init( pMgr : FxGroundMgr, pId : String, pX : Number, pY : Number) : void {
			var lRect	: Rectangle	= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			var lDelt	: Point;
			
			super.init( pMgr, pId, pX, pY);
			
			_x		= lRect.left + pX - mgr.bmpX;
			_y		= lRect.top + pY - mgr.bmpY;
			lDelt	= wTarget.subtract( new Point( _x, _y));
			
			lDelt.normalize( 1);
			
			projSpeed	+= ALT_INIT_SPEED * ( lDelt.x * cos + lDelt.y * sin);
		}
		
		/** @inheritDoc */
		override protected function doModeRun() : Boolean {
			var lRect		: Rectangle	= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			var lDelt		: Point;
			var lBmpInfos	: BmpInfos;
			
			if ( lifeCtr++ < 0) return true;
			
			projSpeed	-= projSpeed * PROJ_FROT;
			
			if ( projSpeed < MIN_SPEED) projSpeed = 0;
			
			_x += projSpeed * cos;
			_y += projSpeed * sin;
			
			if ( lifeCtr > LIFE_CTR_MAX) {
				lDelt = wTarget.subtract( new Point( _x, _y));
				
				if ( lDelt.length <= W_TARGET_RAY) return false;
				
				lDelt.normalize( W_TARGET_FORCE);
				
				wSpeed = wSpeed.add( lDelt);
				
				if ( wSpeed.length > W_TARGET_MAX_SPEED) wSpeed.normalize( W_TARGET_MAX_SPEED);
				
				_x		+= wSpeed.x;
				_y		+= wSpeed.y;
			}
			
			lBmpInfos = BitmapMovieClipMgr.getBmpInfos( _bmpId);
			
			mgr.render(
				lBmpInfos.getFrameInfos( 1 + ( lifeCtr - 1) % lBmpInfos.totalFrames),
				mgr.bmpX + _x - lRect.left,
				mgr.bmpY + _y - lRect.top,
				BMP_IS_TRANS
			);
			
			return true;
		}
	}
}