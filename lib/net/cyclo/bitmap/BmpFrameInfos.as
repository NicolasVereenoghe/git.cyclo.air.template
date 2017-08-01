package net.cyclo.bitmap {
	import flash.display.BitmapData;
	
	/**
	 * descripteur d'infos de bitmap associées à une frame à rendre
	 * 
	 * @author	nico
	 */
	public class BmpFrameInfos {
		/** données bitmap de ce qui a été parsé dans la frame décrite ; null si pas défini */
		protected var _bmp				: BitmapData			= null;
		
		/** abscisse du rendu bitmap dans repère de frame de clip rasterisé */
		protected var _x				: Number;
		/** ordonée de rendu bitmap dans repère de frame de clip rasterisé */
		protected var _y				: Number;
		
		/**
		 * construction de descripteur d'infos de rendu de bitmap de frame
		 * @param	pBmp	données bitmap de rendu
		 * @param	pX		abscisse du rendu bitmap dans repère de frame de clip rasterisé
		 * @param	pY		orddonée de rendu bitmap dans repère de frame de clip rasterisé
		 */
		public function BmpFrameInfos( pBmp : BitmapData, pX : Number, pY : Number) {
			_bmp	= pBmp;
			_x		= pX;
			_y		= pY;
		}
		
		/**
		 * destructeur : on libère la mémoire occupée par la description bitmap de la frame
		 */
		public function free() : void { bmp = null;}
		
		/**
		 * on récupère les données bitmap
		 * @return	données bitmap
		 */
		public function get bmp() : BitmapData { return _bmp; }
		
		/**
		 * on redéfinit les données bitmap
		 * @param	pBmp	nouvelles données bitmap
		 */
		public function set bmp( pBmp : BitmapData) : void {
			try{ if ( _bmp != null && _bmp.width != 0) _bmp.dispose();}catch ( pE : Error) {}
			
			_bmp = pBmp;
		}
		
		/**
		 * on récupère l'abscisse du rendu bitmap dans repère de frame de clip rasterisé
		 * @return	abscisse
		 */
		public function get x() : Number { return _x;}
		
		/**
		 * on récupère l'ordonnée du rendu bitmap dans repère de frame de clip rasterisé
		 * @return	ordonnée
		 */
		public function get y() : Number { return _y;}
	}
}