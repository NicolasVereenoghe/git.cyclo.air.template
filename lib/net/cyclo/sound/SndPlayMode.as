package net.cyclo.sound {
	
	/**
	 * descripteur de mode de lecture d'un son
	 * @author	nico
	 */
	public class SndPlayMode {
		/** descripteur de son que l'on wrappe dans la description de lecture ; null si pas de descripteur */
		protected var _desc							: SndDesc					= null;
		/** taux de volume (0..1) */
		protected var _vol							: Number					= -1;
		/** nombre de répétitions à faire ; -1 signifie que ça doit être déterminé par le descripteur de son */
		protected var _loops						: int						= -1;
		
		/**
		 * construction
		 * @param	pVol	taux du volume (0..1)
		 * @param	pLoops	nombre de répétitions à faire ; laisser -1 pour que ce soit déterminé par défaut par le descripteur de son
		 */
		public function SndPlayMode( pVol : Number = 1, pLoops : int = -1) {
			_vol	= pVol;
			_loops	= pLoops;
		}
		
		/**
		 * calcul "wrappé" de taux de volume
		 * @return	taux de volume (0..1)
		 */
		public function get vol() : Number { return _vol * _desc.vol; }
		
		/**
		 * définition "wrappée" du nombre de répétitions à effectuer dans la lecture de ce son
		 * @return	nombre de répétitions à effectuer dans la lecture de ce son
		 */
		public function get loops() : int {
			if ( _loops == -1) return _desc.loops;
			else return _loops;
		}
		
		/**
		 * 
		 * @param	pDesc	descripteur de son qu'on wrappe dans le descripteur de mode de lecture
		 */
		public function wrapDesc( pDesc : SndDesc) : void { _desc = pDesc; }
	}
}