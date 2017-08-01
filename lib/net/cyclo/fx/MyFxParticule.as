package net.cyclo.fx {
	import flash.geom.Point;
	
	/**
	 * un fx de particule avec quelques comportements de base
	 * 
	 * @author nico
	 */
	public class MyFxParticule extends MyFx {
		/** racine de nom de bmp mc de particule de burst */
		protected var BMP_RADIX										: String										= "particule_motif";
		
		/** valeur max de vitesse de projection */
		protected var PROJ_SPEED_MAX								: Number										= 3;
		
		/**
		 * construction
		 * @param	pCos			vecteur x unitaire direction initiale de projection
		 * @param	pSin			vecteur y unitaire direction initiale de projection
		 * @param	pDropSpeedX		vitesse x de largage de particule (utile pour des particules venant d'un objet en mouvement) ; pas de vitesse par défaut
		 * @param	pDropSpeedY		vitesse y de largage de particule (utile pour des particules venant d'un objet en mouvement) ; pas de vitesse par défaut
		 * @param	pPartNum		numéro de particule [ 1 <=> intensité min .. n <=> intensité max] (utilisé en suffix de nom d'asset)
		 * @param	pTotal			nombre de particules de la palette
		 * @param	pRadix			racine de nom de bmp mc à utiliser à la place de celui par défaut ; null pour garder valeur par défaut
		 * @param	pScaleAnim		true pour adapter la time line du bmp mc à la durée de vie de la particule, false pour laisser jouer en boucle
		 * @param	pDelay			délai en frame avant de lancer l'affichage de la particule, pendant ce temps on est dormant ; laisser 0 pour immédiat
		 * @param	pIsTrans		true pour un motif dont le bitmap carré présente de la transparence, laisser false pour un tracé opaque (plus rapide)
		 * @param	pGrav			force de gravité à appliquer au système, null si pas de gravité
		 * @param	pLifeDelay		durée de vie de particule en nombre d'itérations ; laisser -1 pour valeur par défaut
		 */
		public function MyFxParticule( pCos : Number, pSin : Number, pDropSpeedX : Number = 0, pDropSpeedY : Number = 0, pPartNum : int = 1, pTotal : int = 1, pRadix : String = null, pScaleAnim : Boolean = false, pDelay : int = 0, pIsTrans : Boolean = false, pGrav : Point = null, pLifeDelay : int = -1) {
			super();
			
			if ( pRadix != null) BMP_RADIX = pRadix;
			if ( pLifeDelay > -1) LIFE_CTR_MAX = pLifeDelay;
			
			grav			= pGrav;
			cos				= pCos;
			sin				= pSin;
			_bmpId			= BMP_RADIX + pPartNum;
			projSpeed		= PROJ_SPEED_MAX * pPartNum / pTotal;
			dropSpeedX		= pDropSpeedX;
			dropSpeedY		= pDropSpeedY;
			scaleAnim		= pScaleAnim;
			lifeCtr			= -pDelay;
			BMP_IS_TRANS	= pIsTrans;
		}
	}
}