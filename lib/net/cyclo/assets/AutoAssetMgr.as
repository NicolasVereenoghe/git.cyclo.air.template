package net.cyclo.assets {
	import flash.display.Sprite;
	
	/**
	 * implémentation d'un forwarder de gestionnaire de messages d'AutoAsset
	 * on capte les messages et on les forward à un gestionnaire de messages effectif
	 * util quand le gestionnaire effectif n'est pas le conteneur graphique des AutoAsset
	 * 
	 * @author nico
	 */
	public class AutoAssetMgr extends Sprite implements IAutoAssetMgr {
		/** gestionnaire effectif à qui on forward les messages d'AutoAsset */
		protected var mgr										: IAutoAssetMgr													= null;
		
		/**
		 * construction
		 * @param	pMgr	gestionnaire effectif à qui on forward les messages d'AutoAsset
		 */
		public function AutoAssetMgr( pMgr : IAutoAssetMgr) {
			super();
			
			mgr = pMgr;
		}
		
		/**
		 * destruction
		 */
		public function destroy() : void { mgr = null; }
		
		/** @inheritDoc */
		public function onAutoAssetAdded( pAsset : AutoAsset) : void { mgr.onAutoAssetAdded( pAsset); }
		
		/** @inheritDoc */
		public function onAutoAssetReady( pAsset : AutoAsset) : void { mgr.onAutoAssetReady( pAsset); }
	}
}