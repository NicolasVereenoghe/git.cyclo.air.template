package net.cyclo.assets {
	
	/**
	 * @brief		pour recevoir des notifications de progressions et de fin de traitement d'allocation mémoire des assets, on doit implémenter cette interface
	 * @interface	INotifyMallocAssets
	 * 
	 * @author	nico
	 */
	public interface INotifyMallocAssets {
		/**
		 * @brief		méthode qui reçoit la notification de progression de traitement d'allocation mémoire ; par exemple pour construire une barre de progression
		 * @fn			public void onMallocAssetsProgress( int pCurrent, int pTotal)
		 * @memberof	INotifyMallocAssets
		 * 
		 * @param	pCurrent	nombre de traitements d'allocation mémoire effectués
		 * @param	pTotal		nombre total de traitements d'allocation mémoire à effectuer pendant la phase d'allocation
		 */
		function onMallocAssetsProgress( pCurrent : int, pTotal : int) : void;
		
		/**
		 * @brief		méthode qui reçoit la notification de fin de traitement d'allocation mémoire ; une fois cette méthode appelée, les assets mis en mémoire sont prêts à être utilisés
		 * @fn			public void onMallocAssetsEnd()
		 * @memberof	INotifyMallocAssets
		 */
		function onMallocAssetsEnd() : void;
	}
}