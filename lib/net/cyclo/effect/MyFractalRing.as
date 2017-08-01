package net.cyclo.effect {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * anneau de motifs d'un fractal en spiral
	 * 
	 * @author	nico
	 */
	public class MyFractalRing extends Sprite {
		/** ref sur gestionnaire de fractal desponsable de cet anneau */
		protected var mgr											: MyFractalMgr									= null;
		
		/** étape entière effective de rendu de cet anneau dans la suite d'anneau du fractal spiral */
		protected var _relativeStep									: int											= 0;
		
		/** identifiant d'asset de rendu du motif reçu à l'init */
		protected var _assetInitId									: String										= null;
		
		/**
		 * initialisation et rendu de l'anneau de motifs
		 * @param	pMgr			fractal responsable de cet anneau
		 * @param	pRelativeStep	étape entière effective de rendu dans le fractal
		 */
		public function init( pMgr : MyFractalMgr, pRelativeStep : int) : void {
			var lNb		: int				= pMgr.nbMotif;
			var lId		: String			= Math.random() > pMgr.ALT_RATE ? pMgr.ASSET_ID : pMgr.ASSET_ALT_ID;
			var lI		: int;
			
			mgr				= pMgr;
			_relativeStep	= pRelativeStep;
			_assetInitId	= lId;
			
			for ( lI = 0 ; lI < lNb ; lI++) {
				( addChild( new Sprite()) as DisplayObjectContainer).addChild( instanciateMotif( lId));
				
				setMotif( lI);
			}
		}
		
		/**
		 * destruction de l'anneau
		 */
		public function destroy() : void {
			while ( numChildren > 0) clearMotif();
			
			mgr = null;
		}
		
		/**
		 * lecture de l'étape entière effective de cet anneau dans le fractal
		 */
		public function get relativeStep() : int { return _relativeStep; }
		
		/**
		 * on applati les motifs pour changer l'angle d'ouverture ; on repositionne les motifs à bonne distance de l'origine
		 */
		public function refreshMotif() : void {
			var lI : int;
			
			for ( lI = 0 ; lI < numChildren ; lI++) updateMotif( lI);
		}
		
		/**
		 * on met à jour le nombre de motifs sur l'anneau en les rerépartissant ; on ajoute / retire le nécessaire
		 */
		public function refreshNbMotif() : void {
			var lNb		: int			= mgr.nbMotif;
			var lId		: String		= _assetInitId;
			
			if ( lNb > numChildren) {
				while( numChildren < lNb) ( addChild( new Sprite()) as DisplayObjectContainer).addChild( instanciateMotif( lId));
				
				lNb = 0;
				while ( lNb < numChildren) setMotif( lNb++);
			}else if ( lNb < numChildren) {
				while ( numChildren > lNb) clearMotif();
				
				lNb = 0;
				while ( lNb < numChildren) setMotif( lNb++);
			}
		}
		
		/**
		 * on vire un motif de l'anneau
		 */
		protected function clearMotif() : void {
			var lCont	: DisplayObjectContainer	= ( getChildAt( 0) as DisplayObjectContainer);
			var lAsset	: AssetInstance				= lCont.getChildAt( 0) as AssetInstance;
			
			UtilsMovieClip.clearFromParent( lAsset);
			lAsset.free();
			
			UtilsMovieClip.clearFromParent( lCont);
		}
		
		/**
		 * on configure un motif d'anneau
		 * @param	pI	indice de motif d'anneau [ 0 .. n-1]
		 */
		protected function setMotif( pI : int) : void {
			var lMotif	: DisplayObject	= getChildAt( pI);
			var lVects	: Array			= mgr.motifVectors0;
			var lDist0	: Number		= mgr.dist0;
			
			lMotif.rotation	= pI / lVects.length * 360;
			lMotif.x		= lDist0 * lVects[ pI].x;
			lMotif.y		= lDist0 * lVects[ pI].y;
			lMotif.scaleX	= mgr.flattenCoef;
		}
		
		/**
		 * on met à jour l'angle d'ouverture et la distance à l'origine d'un motif
		 * @param	pI	indice de motif d'anneau [ 0 .. n-1]
		 */
		protected function updateMotif( pI : int) : void {
			var lMotif	: DisplayObject	= getChildAt( pI);
			var lVects	: Array			= mgr.motifVectors0;
			var lDist0	: Number		= mgr.dist0;
			
			lMotif.x		= lDist0 * lVects[ pI].x;
			lMotif.y		= lDist0 * lVects[ pI].y;
			lMotif.scaleX	= mgr.flattenCoef;
		}
		
		/**
		 * on crée une instance de motif d'anneau
		 * @param	pId		identifiant d'asset de motif d'anneau, MyFractalMgr::ASSET_ID ou MyFractalMgr::ASSET_ALT_ID
		 * @return	instance de motif sous forme d'un objet graphique à attacher
		 */
		protected function instanciateMotif( pId : String) : DisplayObject { return AssetsMgr.getInstance().getAssetInstance( pId); }
	}
}