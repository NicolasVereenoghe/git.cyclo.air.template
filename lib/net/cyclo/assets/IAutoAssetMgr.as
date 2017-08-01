package net.cyclo.assets {
	
	/**
	 * interface d'un gestionnaire d'AutoAsset, qui capte les remontées de déclaration des instances qu'il contient
	 * 
	 * @author nico
	 */
	public interface IAutoAssetMgr {
		/**
		 * on signale l'ajout d'un AutoAsset dans les enfants du manager
		 * @param	pAsset	instance d'AutoAsset qui s'est ajouté au stage et qui entame son loading/allocation
		 */
		function onAutoAssetAdded( pAsset : AutoAsset) : void;
		
		/**
		 * on signale qu'une instance d'AutoAsset est prête et affichée dans son conteneur
		 * @param	pAsset	instance d'AutoAsset prête
		 */
		function onAutoAssetReady( pAsset : AutoAsset) : void;
	}
}