package net.cyclo.fx {
	import flash.geom.Point;
	import net.cyclo.bitmap.BitmapMovieClipMgr;
	import net.cyclo.bitmap.BmpInfos;
	import net.cyclo.utils.UtilsMaths;
	
	/**
	 * série de particules qui suivent une trajectoire de spirographe
	 * 
	 * @author nico
	 */
	public class MyFxSpiroSnake extends MyFx {
		/** racine de nom de bmp mc de particule de burst */
		protected var BMP_RADIX										: String										= "snake_motif";
		
		/** nombre de particules à gérer */
		public var spNbPart											: int											= 0;
		/** écart d'angle en rad couvert par le serpentin ; ignoré si ::spIsSpred à true */
		public var spSnakeDA										: Number										= 0;
		/** rayon du cercle majeur du spirographe */
		public var spRay											: Number										= 0;
		/** rayon du cercle mineur du spirographe */
		public var spRay2											: Number										= 0;
		/** taux de transformation de progression de rotation du cercle mineur dans le cercle majeur */
		public var spRatio											: Number										= 0;
		/** vitesse de progression de rotation en rad par frame sur le cercle mineur */
		public var spSpeed											: Number										= 0;
		/** progression en rad de rotation du cercle mineur du spirographe */
		public var spDA												: Number										= 0;
		/** true pour disperser les particules dans tout le spirographe, false pour avoir un rendu serpentin */
		public var spIsSpred										: Boolean										= false;
		/** true pour adapter l'anim par rapport à la position du motif dans la trainée serpentin, false pour adapter l'anim à la distance relative au rayon min / max */
		public var spIsScale										: Boolean										= false;
		/** offset de rotation en rad sur le cercle majeur pour maintenir une transition soft de ratio */
		public var spMajOffset										: Number										= 0;
		
		/** true pour que le fx reste actif même si hors affichage, false pour clipper quand on passe hors affichage */
		protected var isLocked										: Boolean										= true;
		
		/**
		 * construction
		 * @param	pNbPart			nombre de particules à gérer
		 * @param	pSnakeDA		écart d'angle en rad couvert par le serpentin
		 * @param	pRay			rayon du cercle majeur du spirographe
		 * @param	pRay2			rayon du cercle mineur du spirographe
		 * @param	pRatio			taux de transformation de progression de rotation du cercle mineur dans le cercle majeur
		 * @param	pDA				progression de rotation du cercle mineur en rad
		 * @param	pSpeed			vitesse de progression de rotation en rad par frame sur le cercle mineur
		 * @param	pRadix			racine de nom de bmp mc à utiliser à la place de celui par défaut ; null pour garder valeur par défaut
		 * @param	pIsTrans		true pour un motif dont le bitmap carré présente de la transparence, laisser false pour un tracé opaque (plus rapide)
		 * @param	pIsLocked		laisser true pour que le fx reste actif même si hors affichage, false pour clipper quand on passe hors affichage
		 * @param	pIsSpred		true pour disperser les particules dans tout le spirographe, laisser false pour avoir un rendu serpentin
		 * @param	pIsScale		true pour adapter l'anim par rapport à la position du motif dans la trainée serpentin, laisser false pour adapter l'anim à la distance relative
		 */
		public function MyFxSpiroSnake( pNbPart : int, pSnakeDA : Number, pRay : Number, pRay2 : Number, pRatio : Number, pDA : Number, pSpeed : Number, pRadix : String = null, pIsTrans : Boolean = false, pIsLocked : Boolean = true, pIsSpred : Boolean = false, pIsScale : Boolean = false) {
			super();
			
			if ( pRadix != null) BMP_RADIX = pRadix;
			
			spNbPart		= pNbPart;
			spSnakeDA		= pSnakeDA;
			isLocked		= pIsLocked;
			spIsSpred		= pIsSpred;
			spSpeed			= pSpeed;
			_bmpId			= BMP_RADIX
			spRay			= pRay;
			spRay2			= pRay2;
			spRatio			= pRatio;
			spDA			= pDA;
			BMP_IS_TRANS	= pIsTrans;
			spIsScale		= pIsScale;
		}
		
		/**
		 * on met à jour le ration de conversion de rotation en essayant de maintenir le motif de tête à la même orientation
		 * @param	pRatio			taux de transformation de progression de rotation du cercle mineur dans le cercle majeur
		 */
		public function smoothUpdateRatio( pRatio : Number) : void {
			spMajOffset = ( spMajOffset + spDA * ( spRatio - pRatio)) % ( 2 * Math.PI);
			
			spRatio	= pRatio;
		}
		
		/** @inheritDoc */
		override protected function doModeRun() : Boolean {
			var lOneInside	: Boolean	= false;
			var lBmpInfos	: BmpInfos	= BitmapMovieClipMgr.getBmpInfos( _bmpId);
			var lDA			: Number;
			var lI			: int;
			var lPt			: Point;
			var lA			: Number;
			
			if ( spIsSpred) {
				lDA = ( 2 * Math.PI / Math.abs( spRatio)) / spNbPart;
			}else {
				lDA = spSnakeDA / spNbPart;
			}
			
			for ( lI = 0 ; lI < spNbPart ; lI++) {
				lPt = UtilsMaths.spirographe( spRay, spRay2, spRatio, spDA - lI * lDA, spMajOffset);
				
				if ( mgr.render(
					spIsScale ?
						lBmpInfos.getFrameInfos( 1 + Math.round( ( lBmpInfos.totalFrames - 1) * ( 1 - lI / ( spNbPart - 1)))) :
						lBmpInfos.getFrameInfos( 1 + Math.round( ( lBmpInfos.totalFrames - 1) * lPt.length / ( spRay + spRay2))),
					_x + lPt.x,
					_y + lPt.y,
					BMP_IS_TRANS
				)) lOneInside = true;
			}
			
			spDA += spSpeed;
			
			if ( isLocked) return true;
			else return lOneInside;
		}
	}
}