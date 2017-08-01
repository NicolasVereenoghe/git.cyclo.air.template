package net.cyclo.sound {
	
	/**
	 * gestionnaire de nappes de sons, par itération
	 * 
	 * @author	nico
	 */
	public class LayerFramer {
		/** temps d'attente min en ms entre 2 lectures de sons d'une couche */
		protected var WAIT_MIN								: int									= 3000;
		/** temps d'attente max en ms entre 2 lectures de sons d'une couche */
		protected var WAIT_MAX								: int									= 11000;
		/** deg de courbe de proba */
		protected var WAIT_DEG								: Number								= 2;
		
		/** delai initial d'attente avant la première lecture des layers, en ms */
		protected var ENABLE_WAIT							: int									= 2000;
		
		/** listes de couches de sons, par ordre de priorité décroissante  ; { affix: <affix d'identifiant de sons du layer:String>, snds: <listes d'id de sons:Array of String>, min: <attente min en ms:int>, max: <attente max en ms:int>, deg: <deg courbe proba:Number>, ctr: <compteur d'itération restantes du layer:int>} */
		protected var layers								: Array									= null;
		
		/** niveau de priorité max de lecture ; 0 .. n-1 ; -1 pour non défini */
		protected var lvl									: int									= -1;
		
		/** mode d'itération */
		protected var doMode								: Function								= null;
		
		/**
		 * initialisation
		 * @param	pEnableWait	délai avant première lecture sons des couches en ms, -1 pour par défaut
		 */
		public function init( pEnableWait : int = -1) : void {
			if ( pEnableWait > -1) ENABLE_WAIT = pEnableWait;
			
			layers	= new Array();
			
			setModeVoid();
		}
		
		/**
		 * destruction
		 */
		public function destroy() : void {
			var lI	: int;
			
			for ( lI = 0 ; lI <= lvl ; lI++) SndMgr.getInstance().stop( layers[ lI].affix);
			
			layers = null;
		}
		
		/**
		 * ajoute un layer de sons
		 * @param	pSndAffix	affix d'id des sons de ce layer, pour pouvoir les contrôler globalement
		 * @param	pSnds		liste d'id de sons du layer
		 * @param	pMin		attente min en ms, -1 pour laisser par défaut
		 * @param	pMax		attente max en ms, -1 pour laisser par défaut
		 * @param	pDeg		deg courbe de proba, -1 pour laisser défaut
		 */
		public function addLayer( pSndAffix : String, pSnds : Array, pMin : int = -1, pMax : int = -1, pDeg : Number = -1) : void {
			layers.push( {
				affix: pSndAffix,
				snds: pSnds,
				min: pMin > -1 ? pMin : WAIT_MIN,
				max: pMax > -1 ? pMax : WAIT_MAX,
				deg: pDeg > -1 ? pDeg : WAIT_DEG,
				ctr: ENABLE_WAIT
			});
		}
		
		/**
		 * on passe à un niveau de priorité de couche max
		 * @param	pLvl	niveau de priorité, O .. nb layer -1, -1 pour désactiver
		 */
		public function setLayerLevel( pLvl : int) : void {
			var lI	: int;
			
			if ( pLvl < lvl) {
				for ( lI = lvl ; lI > pLvl ; lI--) {
					SndMgr.getInstance().stop( layers[ lI].affix);
					layers[ lI].ctr = ENABLE_WAIT;
				}
			}
			
			lvl	= pLvl;
			
			if( lvl > -1){
				if ( doMode == doModeVoid) setModeRun();
			}else if ( doMode != doModeVoid) setModeVoid();
		}
		
		/**
		 * itération du manager de nappes (contrôle de lecture)
		 * @param	pDt	temps écoulé en ms depuis la dernière itération
		 */
		public function doFrame( pDt : int) : void { doMode( pDt); }
		
		/**
		 * on passe en itération vite
		 */
		protected function setModeVoid() : void {
			doMode = doModeVoid;
		}
		
		/**
		 * on itére à vide
		 * @param	pDt	temps en ms
		 */
		protected function doModeVoid( pDt : int) : void { }
		
		/**
		 * on passe en mode d'itération de lecture de layers
		 */
		protected function setModeRun() : void {
			doMode = doModeRun;
		}
		
		/**
		 * on itére en mode lecture de layers
		 * @param	PDt	temps écoulé en ms
		 */
		protected function doModeRun( pDt : int) : void {
			var lI		: int;
			
			for ( lI = 0 ; lI <= lvl ; lI++) {
				if ( ! SndMgr.getInstance().isPlaying( layers[ lI].affix)) {
					if ( layers[ lI].ctr < pDt) {
						layers[ lI].ctr	= Math.round( layers[ lI].min + Math.pow( Math.random(), layers[ lI].deg) * ( layers[ lI].max - layers[ lI].min));
						
						SndMgr.getInstance().play( layers[ lI].snds[ Math.round( Math.random() * ( layers[ lI].snds.length - 1))]);
					}else layers[ lI].ctr -= pDt;
				}
			}
		}
	}
}