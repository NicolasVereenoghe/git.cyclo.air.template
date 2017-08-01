package net.cyclo.fx {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.PixelSnapping;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.cyclo.bitmap.BitmapMovieClipMgr;
	import net.cyclo.bitmap.BmpFrameInfos;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * gestionnaire de plan d'affichage de fx optimisés, dérivants de MyFx
	 * on dessine dans un bitmap, qui est étiré pour matcher la définition des bitmaps générées (voir MobileDeviceMgr::baseScale et BitmapMovieClipMgr::getBaseTransMtrx)
	 * 
	 * @author	nico
	 */
	public class FxGroundMgr {
		/** scale global de bitmap, composé de BitmapMovieClipMgr::getBaseTransMtrx et ::BMP_SCALE_QUALITY */
		protected var BMP_GLOBAL_SCALE							: Number										= 1;
		
		/** scale de qualité interne aux fx ; /!\ : ajuster les assets de bitmap de fx en fonction */
		protected var BMP_SCALE_QUALITY							: Number										= .3;
		
		/** lageur de zone bmp d'affichage */
		protected var BMP_DISP_W								: int											= 0;
		/** hauteur de zone bmp d'affichage */
		protected var BMP_DISP_H								: int											= 0;
		
		/** rendu lissé (true) ou pas (false) */
		protected var IS_SMOOTHED								: Boolean									 	= false;
		
		/** nombre de secteurs angulaires dans 360° pour répartir le random de génération de particules (min 1) */
		protected var BURST_SMOOTH_REPARTITION_NB_SECTOR		: int											= 3;
		/** nombre de particules générées par burst */
		protected var BURST_TOTAL_PART							: int											= 21;// 42;
		/** nombre de sous particules (min 1) ; palette d'intensités */
		protected var BURST_SUB_PART_NB							: int											= 3;
		
		/** le bitmap d'affichage */
		protected var bmp										: Bitmap										= null;
		/** conteneur d'affichage */
		protected var container									: DisplayObjectContainer						= null;
		
		/** pile de fx (MyFx) classés par ordre de profondeur ( 0 <=> dessus .. n-1 <=> dessous) */
		protected var fxs										: Array											= null;
		
		/** compteur de fx */
		protected var ctr										: int											= 0;
		
		/**
		 * construction
		 * @param	pQScale	scale de qualité à utiliser plutôt que celui par défaut ; sinon laisser -1
		 * @param	pBmp	bitmap à utiliser par ce plan ; null pour s'en allouer une lors de l vue initiale
		 */
		public function FxGroundMgr( pQScale : Number = -1, pBmp : Bitmap = null) {
			if ( pQScale > 0) BMP_SCALE_QUALITY = pQScale;
			if ( pBmp != null) bmp = pBmp;
		}
		
		/**
		 * on récupère l'abscisse de coin haut gauche du bmp de tracé
		 * @return	abscisse dans repère vituel scrollé
		 */
		public function get bmpX() : Number { return bmp.x; }
		
		/**
		 * on récupère l'ordonnée de coin haut gauche du bmp de tracé
		 * @return	ordonnée dans repère vituel scrollé
		 */
		public function get bmpY() : Number { return bmp.y; }
		
		/**
		 * initialisation
		 * @param	pContainer	conteneur d'affichage à utiliser pour le rendu
		 * @param	pIsFixedQ	laisser true pour éviter que la déformation globale joue sur la qualité des fx, mettre false pour laisser influer (/!\ : perf hasardeuses)
		 */
		public function init( pContainer : DisplayObjectContainer, pIsFixedQ : Boolean = true) : void {
			container				= pContainer;
			container.mouseChildren	= false;
			container.mouseEnabled	= false;
			fxs						= new Array();
			
			if ( ! pIsFixedQ) BMP_GLOBAL_SCALE = BitmapMovieClipMgr.getBaseTransMtrx().a * BMP_SCALE_QUALITY;
			else BMP_GLOBAL_SCALE = BMP_SCALE_QUALITY;
		}
		
		/**
		 * on extrait le bmp du gestionnaire de plan
		 * le bmp n'est plus enregistré et géré par le plan
		 * le gestionnaire devient instable, il doit être détruit
		 * on laisse cette opération possible pour transmettre le bloc mémoire lourd de ce plan
		 * @return	bmp du plan de fx
		 */
		public function extractBmp() : Bitmap {
			var lRes	: Bitmap	= bmp;
			
			UtilsMovieClip.clearFromParent( bmp);
			bmp = null;
			
			return lRes;
		}
		
		/**
		 * destruction
		 */
		public function destroy() : void {
			while ( fxs.length > 0) ( fxs.pop() as MyFx).destroy();
			fxs = null;
			
			if( bmp != null){
				bmp.bitmapData.dispose();
				UtilsMovieClip.clearFromParent( bmp);
				bmp = null;
			}
			
			UtilsMovieClip.clearFromParent( container);
			container = null;
		}
		
		/**
		 * définit la vue initiale
		 * @param	pInitView	rectangle affiché (dimensions du rendu bmp fixées par ses dimensions)
		 * 
		 */
		public function setInitView( pRect : Rectangle) : void {
			BMP_DISP_W	= Math.ceil( pRect.width * BMP_GLOBAL_SCALE);
			BMP_DISP_H	= Math.ceil( pRect.height * BMP_GLOBAL_SCALE);
			
			if( bmp == null){
				bmp			= container.addChild( new Bitmap( new BitmapData( BMP_DISP_W, BMP_DISP_H, true, 0), PixelSnapping.ALWAYS, IS_SMOOTHED)) as Bitmap;
				bmp.scaleX	= bmp.scaleY = 1 / BMP_GLOBAL_SCALE;
			}else container.addChild( bmp);
			
			bmp.x		= pRect.left;
			bmp.y		= pRect.top;
		}
		
		/**
		 * on effectue l'itération de frame des fx, à la nouvelle position de rendu
		 * @param	pX	abscisse de nouvelle position de rendu (coin haut gauche du cadre de fx dans la scène)
		 * @param	pY	ordonnée de nouvelle position de rendu (coin haut gauche du cadre de fx dans la scène)
		 */
		public function doFrameGroundAt( pX : Number, pY : Number) : void {
			var lRect	: Rectangle		= new Rectangle( 0, 0, BMP_DISP_W, BMP_DISP_H);
			var lI		: int;
			var lFx		: MyFx;
			
			bmp.bitmapData.fillRect( lRect, 0);
			
			bmp.x	= pX;
			bmp.y	= pY;
			
			for ( lI = fxs.length - 1 ; lI >= 0 ; lI--) {
				lFx = fxs[ lI] as MyFx;
				
				if ( ! lFx.doFrameRender()) remFx( lFx.id);
			}
		}
		
		/**
		 * on ajoute un fx au plan
		 * @param	instance de fx à ajouter au dessus de la liste d'affichage bitmap ; initialisé en interne par cet appel
		 * @param	pX		abscisse vituelle initiale (comprend l'offset de position de rendu, relative à la scène)
		 * @param	pY		ordonnée vituelle initiale (comprend l'offset de position de rendu, relative à la scène)
		 * @return	identiant unique de fx dans le plan
		 */
		public function addFx( pFx : MyFx, pX : Number, pY : Number) : String {
			var lId	: String = ( ++ctr).toString();
			
			fxs.unshift( pFx);
			
			pFx.init( this, lId, pX, pY);
			
			pFx.doFrameRender();
			
			return lId;
		}
		
		/**
		 * on retire un fx du plan ; l'affichage n'est pas détruit, il le sera au prochain rafraîchissment (::doFrameGround)
		 * @param	pId	identif unique de fx dans le plan
		 */
		public function remFx( pId : String) : void {
			var lI	: int;
			var lFx	: MyFx;
			
			for ( lI = 0 ; lI < fxs.length ; lI++) {
				lFx	= fxs[ lI] as MyFx;
				
				if ( lFx.id == pId) {
					lFx.destroy();
					
					fxs.splice( lI, 1);
					
					return;
				}
			}
			
			MySystem.traceDebug( "WARNING : FxGroundMgr::remFx : not found : " + pId);
		}
		
		/**
		 * on demande l'affichage d'un bitmap dans la zone d'affichage du plan de fx
		 * @param	pData		données bitmap à afficher
		 * @param	pDestX		abscisse de destination du motif dans le plan d'affichage (virtuel)
		 * @param	pDestY		ordonnée de destination du motif dans le plan d'affichage (virtuel)
		 * @param	pIsTrans	true pour un motif dont le bitmap carré présente de la transparence, laisser false pour un tracé opaque (plus rapide)
		 * @return	true si l'affichage se passe bien dans la zone ; false si hors zone ce qui signifie une potentielle fin de vie pour les fx
		 */
		public function render( pData : BmpFrameInfos, pDestX : Number, pDestY : Number, pIsTrans : Boolean = false) : Boolean {
			var lBmp	: BitmapData	= pData.bmp;
			var lDest	: Point			= new Point( ( pDestX - bmp.x) * BMP_GLOBAL_SCALE + pData.x, ( pDestY - bmp.y) * BMP_GLOBAL_SCALE + pData.y);
			
			if ( lDest.x > bmp.width || lDest.x + lBmp.width < 0 || lDest.y > bmp.height || lDest.y + lBmp.height < 0) return false;
			
			bmp.bitmapData.copyPixels( pData.bmp, new Rectangle( 0, 0, lBmp.width, lBmp.height), lDest, null, null, pIsTrans);
			
			return true;
		}
		
		/**
		 * génération d'un burst dirigé vers une position fixe de l'écran
		 * @param	pFromWXY		coordonnées de départ dans repère de fenêtre
		 * @param	pToWXY			coordonnées de destination dans repère de fenêtre
		 * @param	pGenFromRay		ray d'anneau de génération ; 0 pour toutes les particules générés au centre
		 * @param	pRadix			racine de nom de bmp mc de particule à utiliser à la place de celui par défaut ; null pour garder valeur par défaut
		 * @param	pDelay			délai en frames de répartition de la génération ; laisser 0 pour tout lacher d'un coup
		 * @param	pIsTrans		true pour un motif dont le bitmap carré présente de la transparence, laisser false pour un tracé opaque (plus rapide)
		 * @param	pTotalPart		nombre total de particules à générer ; laisser 0 pour la valeur par défaut ::BURST_TOTAL_PART
		 */
		public function genPartToFixedScreen( pFromWXY : Point, pToWXY : Point, pGenFromRay : Number = 0, pRadix : String = null, pDelay : int = 0, pIsTrans : Boolean = false, pTotalPart : int = 0) : void {
			var lRect		: Rectangle		= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			var lX			: Number		= bmp.x + pFromWXY.x - lRect.left;
			var lY			: Number		= bmp.y + pFromWXY.y - lRect.top;
			var lFromA		: Number		= Math.random() * 2 * Math.PI;
			var lDA			: Number		= 2 * Math.PI / BURST_SMOOTH_REPARTITION_NB_SECTOR;
			var lI			: int			= 0;
			var lTotalPart	: int			= pTotalPart > 0 ? pTotalPart : BURST_TOTAL_PART;
			var lCurMaxI	: int;
			var lISub		: int;
			var lA			: Number;
			var lCos		: Number;
			var lSin		: Number;
			var lISect		: int;
			
			for ( lISect = 0 ; lISect < BURST_SMOOTH_REPARTITION_NB_SECTOR ; lISect++) {
				lCurMaxI = Math.min( Math.ceil( ( lISect + 1) * lTotalPart / BURST_SMOOTH_REPARTITION_NB_SECTOR), lTotalPart);
				
				for ( ; lI < lCurMaxI ; lI++) {
					lA		= lFromA + Math.random() * lDA;
					lCos	= Math.cos( lA);
					lSin	= Math.sin( lA);
					
					addFx(
						new MyFxFixedWTarget(
							pToWXY,
							lCos,
							lSin,
							Math.ceil( BURST_SUB_PART_NB * Math.min( 1, ( lCurMaxI - lI) / ( lCurMaxI - Math.ceil( lISect * lTotalPart / BURST_SMOOTH_REPARTITION_NB_SECTOR)))),
							BURST_SUB_PART_NB,
							pRadix,
							Math.round( Math.random() * pDelay),
							pIsTrans
						),
						lX + pGenFromRay * lCos,
						lY + pGenFromRay * lSin
					);
				}
				
				lFromA += lDA;
			}
		}
		
		/**
		 * génération d'un burst de particules autour d'un rayon de génération
		 * @param	pX				abscisse virtuelle de scène de centre d'anneau de burst
		 * @param	pY				ordonnée virtuelle de scène de centre d'anneau de burst
		 * @param	pDropSpeedX		vitesse x de largage de particule (utile pour des particules venant d'un objet en mouvement) ; pas de vitesse par défaut
		 * @param	pDropSpeedY		vitesse y de largage de particule (utile pour des particules venant d'un objet en mouvement) ; pas de vitesse par défaut
		 * @param	pGenFromRay		ray d'anneau de génération ; 0 pour toutes les particules générés au centre
		 * @param	pRadix			racine de nom de bmp mc de particule à utiliser à la place de celui par défaut ; null pour garder valeur par défaut
		 * @param	pScaleAnim		true pour adapter la time line du bmp mc à la durée de vie de la particule, false pour laisser jouer en boucle
		 * @param	pDelay			délai en frames de répartition de la génération ; laisser 0 pour tout lacher d'un coup
		 * @param	pIsTrans		true pour un motif dont le bitmap carré présente de la transparence, laisser false pour un tracé opaque (plus rapide)
		 * @param	pTotalPart		nombre total de particules à générer ; laisser 0 pour la valeur par défaut ::BURST_TOTAL_PART
		 * @param	pGrav			force de gravité à appliquer au système, null si pas de gravité
		 * @param	pRayYRate		coef appliqué aux coposantes y des particules générées pour avoir un oval ; bricolé mais rapide ; laisser 1 pour un disque
		 * @param	pLifeDelay		durée de vie de particule en nombre d'itérations ; laisser -1 pour valeur par défaut
		 */
		public function genPartBurst( pX : Number, pY : Number, pDropSpeedX : Number = 0, pDropSpeedY : Number = 0, pGenFromRay : Number = 0, pRadix : String = null, pScaleAnim : Boolean = false, pDelay : int = 0, pIsTrans : Boolean = false, pTotalPart : int = 0, pGrav : Point = null, pRayYRate : Number = 1, pLifeDelay : int = -1) : void {
			var lFromA		: Number		= Math.random() * 2 * Math.PI;
			var lDA			: Number		= 2 * Math.PI / BURST_SMOOTH_REPARTITION_NB_SECTOR;
			var lI			: int			= 0;
			var lTotalPart	: int			= pTotalPart > 0 ? pTotalPart : BURST_TOTAL_PART;
			var lCurMaxI	: int;
			var lISub		: int;
			var lA			: Number;
			var lCos		: Number;
			var lSin		: Number;
			var lISect		: int;
			
			for ( lISect = 0 ; lISect < BURST_SMOOTH_REPARTITION_NB_SECTOR ; lISect++) {
				lCurMaxI = Math.min( Math.ceil( ( lISect + 1) * lTotalPart / BURST_SMOOTH_REPARTITION_NB_SECTOR), lTotalPart);
				
				for ( ; lI < lCurMaxI ; lI++) {
					lA		= lFromA + Math.random() * lDA;
					lCos	= Math.cos( lA);
					lSin	= Math.sin( lA);
					
					addFx(
						new MyFxParticule(
							lCos,
							lSin,
							pDropSpeedX,
							pDropSpeedY,
							Math.ceil( BURST_SUB_PART_NB * Math.min( 1, ( lCurMaxI - lI) / ( lCurMaxI - Math.ceil( lISect * lTotalPart / BURST_SMOOTH_REPARTITION_NB_SECTOR)))),
							BURST_SUB_PART_NB,
							pRadix,
							pScaleAnim,
							Math.round( Math.random() * pDelay),
							pIsTrans,
							pGrav,
							pLifeDelay
						),
						pX + pGenFromRay * lCos,
						pY + pGenFromRay * lSin * pRayYRate
					)
				}
				
				lFromA += lDA;
			}
		}
	}
}