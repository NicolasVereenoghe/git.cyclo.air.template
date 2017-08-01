package net.cyclo.bitmap {
	import flash.geom.Matrix;
	import net.cyclo.shell.MySystem;
	
	/**
	 * descripteur de rendu bitmap d'un clip rasterisé
	 * 
	 * @author	nico
	 */
	public class BmpInfos {
		/** snapping du bitmap généré ; utiliser les constantes de PixelSnapping */
		protected var _snap					: String;
		/** false pas de rendu bitmap avec smoothing, true avec */
		protected var _smooth				: Boolean;
		
		/** collection de descripteur de rendu bitmap de frame, indexées par num de frame [ 1 .. n] */
		protected var frames				: Object;
		/** compteur de frames bitmap générées */
		protected var _totalFrames			: int;
		
		/** matrice de transformation inversée de contrôle de qualité de rendu ; null si pas utilisée ; ex.: si on 2 fois plus de détails, on aura agrandi le bitmap x2, mais pour le rendu c'est l'inverse, on divise par 2 */
		protected var _qualityInvertMatrx	: Matrix	= null;
		
		/**
		 * construction du descripteur
		 * @param	pSnap			snapping du bitmap généré ; utiliser les constantes de PixelSnapping
		 * @param	pSmooth			false pas de rendu bitmap avec smoothing, true avec
		 * @param	pQualityMtrx	optionnel : une matrice de transformation pour controler la qualité de rasterisation ; lors du rendu, on appliquera la transformation inverse pour rendre à la taille d'origine ; pas besoin de cloner la matrice transmise, elle l'est dans le code
		 */
		public function BmpInfos( pSnap : String, pSmooth : Boolean, pQualityMtrx : Matrix = null) {
			_totalFrames	= 0;
			_snap			= pSnap;
			_smooth			= pSmooth;
			frames			= {};
			
			if( pQualityMtrx != null){
				_qualityInvertMatrx	= pQualityMtrx.clone();
				_qualityInvertMatrx.invert();
			}
		}
		
		/**
		 * destructeur : on libère la mémoire occupée par les infos du bitmap décrit
		 */
		public function free() : void {
			var lI	: String;
			
			for( lI in frames) BmpFrameInfos( frames[ lI]).free();
			
			frames = null;
		}
		
		/**
		 * on récupère lse infos de rendu bitmap à une certaine frame ; on suppose que les infos sont définies pour cette frame
		 * @param	pFrame	numéro de frame
		 */
		public function getFrameInfos( pFrame : int) : BmpFrameInfos { return BmpFrameInfos( frames[ pFrame]);}
		
		/**
		 * on récupère la matrice de transformation à appliquer au bitmap à rendre
		 * @return	matrice de transformation à appliquer au rendu bitmap, ou null si rien à appliquer ; attention, ce n'est pas une copie
		 */
		public function get transMtrx() : Matrix { return _qualityInvertMatrx;}
		
		/**
		 * on ajoute un descripteur de rendu bitmap de frame à la collection
		 * @param	pFrame	numéro de frame de l'info à ajouter
		 * @param	pInfos	infos de descripteur de rendu bitmap de frame
		 */
		public function addFrameInfos( pFrame : int, pInfos : BmpFrameInfos) : void {
			var lPrev	: BmpFrameInfos;
			
			if ( frames[ pFrame - 1] != undefined) {
				lPrev	= BmpFrameInfos( frames[ pFrame - 1]);
				
				if ( pInfos != lPrev && lPrev.bmp.compare( pInfos.bmp) == 0) {
					pInfos.bmp = lPrev.bmp;
				}
			}
			
			frames[ pFrame] = pInfos;
			_totalFrames++;
		}
		
		/**
		 * on récupère le nombre de frame bitmap qui constituent le rendu du clip rasterisé
		 * @return	nombre de frames bitmap
		 */
		public function get totalFrames() : int { return _totalFrames;}
		
		/**
		 * snapping du bitmap généré ; voir les constantes de PixelSnapping
		 * @return	snapping du bitmap généré
		 */
		public function get snap() : String { return _snap;}
		
		/**
		 * on récupère la valeur de l'attribut de smoothing du bitmap généré
		 * @return	false pas de rendu bitmap avec smoothing, true avec
		 */
		public function get smooth() : Boolean { return _smooth;}
	}
}