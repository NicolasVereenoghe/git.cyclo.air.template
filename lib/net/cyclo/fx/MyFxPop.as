package net.cyclo.fx {
	import net.cyclo.shell.device.MobileDeviceMgr;
	
	/**
	 * un fx de pop (genre score), avec gestion d'auto orientation en fonction de MobileDeviceMgr::rotContent
	 * suffix d'asset en fonction de l'orientation : { "1" <=> 0, "2" <=> 90, "3" <=> 180, "4" <=> -90}
	 * 
	 * @author nico
	 */
	public class MyFxPop extends MyFx {
		/** racine de nom de bmp mc de fx de pop */
		protected var BMP_RADIX										: String										= "fxPop";
		
		/** vitesse initial de pop */
		protected var INIT_POP_SPEED								: Number										= 5;
		
		/** rayon de génération de pop */
		protected var POP_RAY										: Number										= 50;
		
		/**
		 * construction
		 * @param	pRay			rayon de génération du motif bmp autour du x, y de scène du fx ; laisser -1 pour valeur par défaut ::POP_RAY
		 * @param	pPopSpeed		vitesse initiale de pop, laisser -1 pour valeur par défaut ::INIT_POP_SPEED
		 * @param	pDropSpeedX		vitesse x de largage de particule (utile pour des particules venant d'un objet en mouvement) ; pas de vitesse par défaut
		 * @param	pDropSpeedY		vitesse y de largage de particule (utile pour des particules venant d'un objet en mouvement) ; pas de vitesse par défaut
		 * @param	pRadix			racine de nom de bmp mc à utiliser à la place de celui par défaut ; null pour garder valeur par défaut
		 * @param	pScaleAnim		true pour adapter la time line du bmp mc à la durée de vie de la particule, false pour laisser jouer en boucle
		 * @param	pDelay			délai en frame avant de lancer l'affichage de la particule, pendant ce temps on est dormant ; laisser 0 pour immédiat
		 * @param	pIsTrans		true pour un motif dont le bitmap carré présente de la transparence, laisser false pour un tracé opaque (plus rapide)
		 */
		public function MyFxPop( pRay : Number = -1, pPopSpeed : Number = -1, pDropSpeedX : Number = 0, pDropSpeedY : Number = 0, pRadix : String = null, pScaleAnim : Boolean = false, pDelay : int = 0, pIsTrans : Boolean = false) {
			var lA	: int	= MobileDeviceMgr.getInstance().rotContent;
			
			super();
			
			if ( pRadix != null) BMP_RADIX = pRadix;
			if ( pPopSpeed >= 0) INIT_POP_SPEED = pPopSpeed;
			if ( pRay >= 0) POP_RAY = pRay;
			
			projSpeed		= INIT_POP_SPEED;
			dropSpeedX		= pDropSpeedX;
			dropSpeedY		= pDropSpeedY;
			scaleAnim		= pScaleAnim;
			lifeCtr			= -pDelay;
			BMP_IS_TRANS	= pIsTrans;
			
			if ( lA == 0) {
				_bmpId	= BMP_RADIX + "1";
				cos		= 0;
				sin		= -1;
			}else if ( lA == 90) {
				_bmpId	= BMP_RADIX + "2";
				cos		= 1;
				sin		= 0;
			}else if ( lA == 180) {
				_bmpId	= BMP_RADIX + "3";
				cos		= 0;
				sin		= 1;
			}else {
				_bmpId	= BMP_RADIX + "4";
				cos		= -1;
				sin		= 0;
			}
			
			_x	+= cos * POP_RAY;
			_y	+= sin * POP_RAY;
		}
	}
}