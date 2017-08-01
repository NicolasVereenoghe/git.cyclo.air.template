package net.cyclo.sound {
	
	/**
	 * on lance un son dès qu'un autre s'est arrêté ; la technique d'enchaînement est light, elle ne permet pas un enchaînement exact
	 * @author	nico
	 */
	public class SndPlayModeChained extends SndPlayMode {
		/** pattern de recherche d'identifiants de son à vérifier la fin de lecture avant de lancer notre son ; laisser null pour tout vérifier */
		protected var _subId							: String							= null;
		
		/**
		 * @inheritDoc
		 * @param		pSubId	pattern de recherche d'identifiants de son à vérifier la fin de lecture avant de lancer notre son ; laisser null pour tout vérifier
		 */
		public function SndPlayModeChained( pSubId : String = null, pVol : Number = 1, pLoops : int = -1) {
			super( pVol, pLoops);
			
			_subId = pSubId;
		}
		
		/**
		 * on récupère la pattern de recherche d'identifiants de son à vérifier la fin de lecture avant de lancer notre son
		 * @return	pattern de recherche, ou null pour désigner tous les sons
		 */
		public function get subId() : String { return _subId; }
	}
}