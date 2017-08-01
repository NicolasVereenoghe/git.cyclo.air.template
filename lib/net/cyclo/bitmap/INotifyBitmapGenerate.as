package net.cyclo.bitmap {
	
	/**
	 * @brief		pour recevoir la notification de fin de génération bitmap, on doit implémenter cette interface
	 * @interface	INotifyBitmapGenerate
	 * 
	 * @author	nico
	 */
	public interface INotifyBitmapGenerate {
		/**
		 * @brief		méthode qui reçoit la notification de fin de traitement de génération bitmap
		 * @fn			public void onBitmapGenerateComplete( pBmpId : String)
		 * @memberof	INotifyBitmapGenerate
		 * 
		 * @param	pBmpId	identifiant bitmap du bitmap généré
		 */
		function onBitmapGenerateComplete( pBmpId : String) : void;
	}
}