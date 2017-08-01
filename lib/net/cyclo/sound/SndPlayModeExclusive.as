package net.cyclo.sound {
	
	/**
	 * on lance un son en mode exclusive : ne supporte qu'un nombre limité de sons au lancement, si excédés, on éteint les plus anciens correspondants au pattern de recherche
	 * @author nico
	 */
	public class SndPlayModeExclusive extends SndPlayMode {
		/** pattern de recherche d'identifiants de son à vérifier pour l'exclusivité */
		protected var _subId							: String							= null;
		/** nb max de sons tolérés en plus du notre, au delà on stoppe à commencer par les plus vieux */
		protected var _maxSnd							: int								= 0;
		
		/**
		 * @inheritDoc
		 * @param	pSubId		pattern de recherche d'identifiants de son à vérifier pour l'exclusivité ; laisser null pour tout vérifier
		 * @param	pMaxSnd		nb max de sons tolérés en plus du notre, au delà on stoppe à commencer par les plus vieux
		 */
		public function SndPlayModeExclusive( pSubId : String = null, pMaxSnd : int = 0, pVol : Number = 1, pLoops : int = -1) {
			super( pVol, pLoops);
			
			_subId	= pSubId;
			_maxSnd	= pMaxSnd;
		}
		
		/**
		 * on récupère la pattern de recherche d'identifiants pour l'exclusivité
		 * @return	pattern de recherche, ou null pour désigner tous les sons
		 */
		public function get subId() : String { return _subId; }
		
		/**
		 * on récupère le nombre max de sons de la pattern de recherche tolérés en même temps que notre son
		 * @return	nombre max de sons tolérés
		 */
		public function get maxSnd() : int { return _maxSnd; }
	}
}