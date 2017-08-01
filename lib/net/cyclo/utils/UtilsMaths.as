package net.cyclo.utils {
	import flash.geom.Point;
	
	/**
	 * méthodes utilitaires de maths
	 * @author	nico
	 */
	public class UtilsMaths {
		/** coef de conversion de degré en radian */
		public static const COEF_DEG_2_RAD					: Number								= Math.PI / 180;
		
		/** coef de conversion de radian en degré */
		public static const COEF_RAD_2_DEG					: Number								= 180 / Math.PI;
		
		/**
		 * fonction de puissance ronde définie de [ 0 .. 1] vers [ 0 .. 1] ; permet d'avoir une parabole "quart de cercle" plus ou moins écrasée
		 * @param	pNum	nombre à élever à une puissance ronde ; pNum E [ 0 .. 1]
		 * @param	pPow	puissance ; sur ] 0 .. 1[ quart de cercle incurvé vers le haut ; sur ] 1 .. +~[ incurvé vers le bas ; 1 <=> droite ; .5 et 2 définissent des quarts de cercle parfaits
		 * @return	nombre élevé à la puissance ronde en [ 0 .. 1]
		 */
		public static function powRound( pNum : Number, pPow : Number) : Number {
			return 1 - Math.pow( 1 - Math.pow( pNum, pPow), 1 / pPow);
		}
		
		/**
		 * modulo d'angle en radian sur  ] -PI .. PI ]
		 * @param	pA	angle à mettre sur l'interval
		 * @return	angle en radian sur  ] -PI .. PI ]
		 */
		public static function modRad( pA : Number) : Number {
			pA %= Math.PI * 2;
			
			if ( pA <= -Math.PI) return pA + Math.PI * 2;
			else if ( pA > Math.PI) return pA - Math.PI * 2;
			else return pA;
		}
		
		/**
		 * modulo d'angle en degré sur  ] -180 .. 180 ]
		 * @param	pA	angle à mettre sur l'interval
		 * @return	angle en degré sur  ] -180 .. 180 ]
		 */
		public static function modDeg( pA : Number) : Number {
			pA %= 360;
			
			if ( pA <= -180) return pA + 360;
			else if ( pA > 180) return pA - 360;
			else return pA;
		}
		
		/**
		 * exprime les coordonnées d'un vecteur dans un repère dont on a tourné les axes
		 * @param	pVect	vecteur dont on effectue un changement de repère
		 * @param	pCos	cosinus d'angle de rotation du nouveau repère
		 * @param	pSin	sinus d'angle de rotation du nouveau repère
		 * @return	nouveau vecteur exprimé dans le repère tourné
		 */
		public static function rotRepere( pVect : Point, pCos : Number, pSin : Number) : Point {
			return new Point(
				pVect.x * pCos + pVect.y * pSin,
				pVect.y * pCos - pVect.x * pSin
			);
		}
		
		/**
		 * on récupère une coordonée de spirographe
		 * @param	pRay		rayon du cercle majeur
		 * @param	pRay2		rayon du cercle mineur
		 * @param	pRatio		taux de transformation de progression de rotation du cercle mineur dans le cercle majeur
		 * @param	pDA			progression de rotation du cercle mineur en rad
		 * @param	pMajOffset	offset de rotation en rad à appliquer à la rotation majeure
		 * @return	coordonnées spirographées
		 */
		public static function spirographe( pRay : Number, pRay2 : Number, pRatio : Number, pDA : Number, pMajOffset : Number = 0) : Point {
			var lMajA		: Number	= pDA * pRatio + pMajOffset;
			var lMajCos		: Number	= Math.cos( lMajA);
			var lMajSin		: Number	= Math.sin( lMajA);
			var lMinCos		: Number	= Math.cos( pDA);
			var lMinSin		: Number	= Math.sin( pDA);
			
			return new Point(
				lMajCos * pRay + ( lMinCos * lMajCos + lMinSin * lMajSin) * pRay2,
				lMajSin * pRay + ( lMinSin * lMajCos - lMinCos * lMajSin) * pRay2
			);
		}
	}
}