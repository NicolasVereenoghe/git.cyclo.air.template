package net.cyclo.bitmap {
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	
	/**
	 * gestionnaire de BitmapMovieClip et utilitaires de rasterisation
	 * 
	 * @author	nico
	 */
	public class BitmapMovieClipMgr {
		/** map d'infos de rasterisation : on collectionne les infos de rasterisation des bitmap moiveclip rendus ; _bmpInfos[ <id de bitmap movieclip>] = <BmpInfos> */
		protected static var _bmpInfos				: Object			= { };
		
		/** matrice de transformation qui décrit le scale de base appliqué à l'application et qui influe sur la qualité de rendu des bitmaps générés ; null si pas de scale d ebase appliqué */
		protected static var baseTransMtrx			: Matrix			= null;
		
		/**
		 * on défini un scale de base appliqué à l'application qui va être répercuté sur la qualité de rendu des bitmaps générés
		 * @param	pScale	valeur de scale appliqué sur l'application
		 */
		public static function setBaseScale( pScale : Number) : void {
			baseTransMtrx	= new Matrix();
			
			baseTransMtrx.createBox( pScale, pScale);
		}
		
		/**
		 * on retourne une copie de la matrice de transformation décrivant le scale de base appliqué à l'application
		 * @return	matrice de transformation, ou null si pas de scale de base défini
		 */
		public static function getBaseTransMtrx() : Matrix {
			if ( baseTransMtrx != null) return baseTransMtrx.clone();
			else return null;
		}
		
		/**
		 * on libère la mémoire occupée par un bitmap
		 * @param	pId	identifiant du bitmap à libérer de la mémoire
		 */
		public static function flushByIndex( pId : String) : void {
			BmpInfos( _bmpInfos[ pId]).free();
			
			delete _bmpInfos[ pId];
		}
		
		/**
		 * on vérifie si on a déjà des infos sur un bitmap movieclip dont on passe l'identifiant
		 * @param	pBmpId	identifiant de bitmap
		 * @return	true si on possède des infos (traitements déjà effectués sur ce bitmap), false sinon
		 */
		public static function isBmpInfos( pBmpId : String) : Boolean { return _bmpInfos[ pBmpId] != undefined;}
		
		/**
		 * on collecte les infos de bitmap
		 * @param	pBmpId		identifiant de bitmap 
		 * @param	pBmpInfos	infos de rendu bitmap associées à ce bitmap
		 */
		public static function addBmpInfos( pBmpId : String, pBmpInfos : BmpInfos) : void { _bmpInfos[ pBmpId] = pBmpInfos;}
		
		/**
		 * on récupère les infos de rendu bitmap d'un bitmap ; on suppose que l'info est définie
		 * @param	pBmpId	identifiant de bitmap
		 * @return	infos de rendus bitmap associées à ce bitmap
		 */
		public static function getBmpInfos( pBmpId : String) : BmpInfos { return BmpInfos( _bmpInfos[ pBmpId]);}
	}
}