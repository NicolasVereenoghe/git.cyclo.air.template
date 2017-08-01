package net.cyclo.template.shell {
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.assets.PatternAsset;
	import net.cyclo.template.screen.MyScreen;
	import net.cyclo.template.screen.ScreenPreloading;
	
	/**
	 * version réduite du sample 2 pour lancement d'un niveau en particulier, mais avec un minimum de gui
	 * 
	 * @author	nico
	 */
	public class MyShellSample3 extends MyShellSample2 {
		/**
		 * construction : on force la sélection d'un niveau
		 */
		public function MyShellSample3() {
			super();
			
			selectedGameIndex = 0;
		}
		
		/** @inheritDoc */
		override protected function getAssetsPatterns() : Array {
			return [
				new PatternAsset( ASSET_GROUP_SHARED, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL),
				new PatternAsset( ASSET_GROUP_LVLD, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL),
				new PatternAsset( ASSET_GROUP_TC, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL)
			];
		}
		
		/** @inheritDoc */
		override protected function getAssetsGUITCPatterns() : Array { return [ new PatternAsset( ASSET_GROUP_TC, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL)]; }
		
		/** @inheritDoc */
		override protected function getAfterPreloadingInstance() : MyScreen { return getTCInstance(); }
		
		/** @inheritDoc */
		override protected function getFromGameToGUIInstance() : MyScreen { return getTCInstance(); }
	}
}