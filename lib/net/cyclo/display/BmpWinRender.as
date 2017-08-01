package net.cyclo.display {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.PixelSnapping;
	import flash.display.StageQuality;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.cyclo.bitmap.BitmapMovieClipMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * gère le rendu d'une fenêtre bitmap dans une zone de dessin direct
	 * @author nico
	 */
	public class BmpWinRender {
		/** bordure en pixels à ajouter à la fenêtre de rendu */
		protected var BORDER						: int												= 1;
		
		/** scale de qualité global de bitmap */
		protected var globalQScale					: Number											= 1;
		
		/** couleur RGB de fond par défaut */
		protected var col							: uint												= 0;
		
		/** conteneur de zone de dessin direct */
		protected var cont							: DisplayObjectContainer							= null;
		
		/** rectangle de fenêtre d'affichage dans repère de conteneur de dessin */
		protected var winRect						: Rectangle											= null;
		
		/** bitmap source */
		protected var srcBmp						: Bitmap											= null;
		
		/** bitmap d'affichage */
		protected var bmp							: Bitmap											= null;
		
		/** construction */
		public function BmpWinRender() { }
		
		/**
		 * init
		 * @param	pCont		conteneur de dessin
		 * @param	pWinRect	rectangle de fenêtre d'affichage dans repère de conteneur de dessin
		 * @param	pSrcBmp		instanc source de bitmap à rendre
		 * @param	pQScale		scale de qualité global ; sinon laisser -1 pour val par défaut
		 * @param	pIsFixedQ	laisser true pour éviter que la déformation globale joue sur la qualité des fx, mettre false pour laisser influer (/!\ : perf hasardeuses)
		 * @param	pSmooth		laisser true pour avoir le smooth, false sinon
		 * @param	pSnap		snap (voir PixelSnapping::)
		 * @param	pTrans		true pour rendu avec transparence, sinon laiser false
		 * @param	pCol		couleur ARGB de fond par défaut
		 */
		public function init( pCont : DisplayObjectContainer, pWinRect : Rectangle, pSrcBmp : Bitmap, pQScale : Number = -1, pIsFixedQ : Boolean = true, pSmooth : Boolean = true, pSnap : String = "never", pTrans : Boolean = false, pCol : uint = 0) : void {
			cont	= pCont;
			winRect	= pWinRect;
			srcBmp	= pSrcBmp;
			col		= pCol;
			
			if ( pQScale > 0) globalQScale = pQScale;
			if ( ! pIsFixedQ) globalQScale *= BitmapMovieClipMgr.getBaseTransMtrx().a;
			
			bmp = pCont.addChild( new Bitmap(
				new BitmapData(
					Math.floor( pWinRect.width * globalQScale) + 2 * BORDER,
					Math.floor( pWinRect.height * globalQScale) + 2 * BORDER,
					pTrans,
					pCol
				),
				pSnap,
				pSmooth
			)) as Bitmap;
			
			bmp.scaleX = bmp.scaleY = 1 / globalQScale;
			
			bmp.x = winRect.left + ( winRect.width - bmp.width) / 2;
			bmp.y = winRect.top + ( winRect.height - bmp.height) / 2;
		}
		
		/**
		 * on demande de rendre une fenêtre sur le bitmap source
		 * @param	pRect		portion de rectangle du bitmap source à rendre 
		 * @param	pDoClear	true pour cleaner le précédent rendu avant de faire le nouveau, laisser false pour ne pas cleaner
		 * @param	pSmooth		true pour un parsing smooth du bmp source, laisser false sinon
		 */
		public function doRender( pRect : Rectangle, pDoClear : Boolean = false, pSmooth : Boolean = false) : void {
			var lMtrx	: Matrix	= new Matrix();
			
			lMtrx.tx = -pRect.left;
			lMtrx.ty = -pRect.top;
			lMtrx.scale( globalQScale * bmp.width / pRect.width, globalQScale * bmp.height / pRect.height);
			
			if ( pDoClear) bmp.bitmapData.fillRect( bmp.getRect( bmp), col);
			
			bmp.bitmapData.draw(
				srcBmp.bitmapData,
				lMtrx,
				null,
				null,
				null,
				pSmooth
			);
		}
		
		/** destruction */
		public function destroy() : void {
			bmp.bitmapData.dispose();
			UtilsMovieClip.clearFromParent( bmp);
			bmp = null;
			
			winRect = null;
			srcBmp = null;
			cont = null;
		}
	}
}