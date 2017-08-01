package net.cyclo.template.game {
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.net.URLLoader;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.assets.NotifyMallocAssets;
	import net.cyclo.assets.PatternAsset;
	import net.cyclo.loading.CycloLoader;
	import net.cyclo.loading.CycloLoaderListener;
	import net.cyclo.loading.CycloLoaderMgr;
	import net.cyclo.loading.ICycloLoaderListener;
	import net.cyclo.loading.file.MyFile;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.template.shell.datas.SavedDatas;
	import net.cyclo.template.shell.IGameShell;
	import net.cyclo.template.shell.score.MyScore;
	import net.cyclo.ui.local.LocalMgr;
	
	/**
	 * implémentation générique de gestionnaire de jeu avec gestion des assets par le composant net.cyclo.assets.AssetsMgr
	 * @author nico
	 */
	public class GameMgrAssets implements IGameMgr {
		/** racine de nom de groupe d'assets du jeu */
		protected var GAME_GROUP_ASSET_RADIX	: String						= "game";
		
		/** réf sur le conteneur des éléments de jeu */
		protected var gameContainer				: DisplayObjectContainer		= null;
		
		/** réf sur le shell responsable de ce jeu */
		protected var shell						: IGameShell					= null;
		
		/** données sauvegardable de jeu */
		protected var savedDatas				: SavedDatas					= null;
		
		/** @inheritDoc */
		public function init( pShell : IGameShell, pGameContainer : DisplayObjectContainer, pSavedDatas : SavedDatas = null) : void {
			shell			= pShell;
			gameContainer	= pGameContainer;
			savedDatas		= pSavedDatas;
			
			loadAssets();
		}
		
		/** @inheritDoc */
		public function reset() : void { MySystem.traceDebug( "WARNING : GameMgrAssets::reset : méthode abstraite, doit être redéfinie"); }
		
		/** @inheritDoc */
		public function getScore() : MyScore {
			MySystem.traceDebug( "INFO : GameMgrAssets::getScore : pas de définition, le score est calculé par le shell");
			
			return null;
		}
		
		/** @inheritDoc */
		public function getDatas() : SavedDatas { return savedDatas; }
		
		/** @inheritDoc */
		public function get gameId() : String {
			MySystem.traceDebug( "WARNING : GameMgrAssets::gameId : méthode abstraite, identifiant vide");
			
			return "";
		}
		
		/** @inheritDoc */
		public function startGame() : void { MySystem.traceDebug( "WARNING : GameMgrAssets::startGame : méthode abstraite, doit être redéfinie"); }
		
		/** @inheritDoc */
		public function destroy() : void {
			AssetsMgr.getInstance().freeAssets( getGamePatternAsset( false));
			AssetsMgr.getInstance().unloadAssets( null, null, getGamePatternAsset( false));
			
			savedDatas = null;
			shell = null;
			gameContainer = null;
		}
		
		/** @inheritDoc */
		public function switchPause( pIsPause : Boolean) : void { MySystem.traceDebug( "WARNING : GameMgrAssets::switchPause : méthode abstraite, doit être redéfinie : " + pIsPause); }
		
		/** @inheritDoc */
		public function updateRotContent() : void { MySystem.traceDebug( "INFO : GameMgrAssets::updateRotContent : rot=" + MobileDeviceMgr.getInstance().rotContent); }
		
		/** @inheritDoc */
		public function getShell() : IGameShell { return shell; }
		
		/** @inheritDoc */
		public function onFeedbackEnd( pEvtId : String = null, pLvl : int = 0, pVal : int = 0, pWXY : Point = null) : void { MySystem.traceDebug( "INFO : GameMgrAssets::onFeedbackEnd : id=" + pEvtId + " lvl=" + pLvl + " val=" + pVal + " from screen pt=" + pWXY); }
		
		/**
		 * on retourne une liste de patterns d'assets utilisés par le jeu en cours
		 * @param	pIsLoad	true si demande de liste pour loader ces assets, false pour une liste à libérer
		 * @return	liste de patterns d'assets (PatternAsset)
		 */
		protected function getGamePatternAsset( pIsLoad : Boolean = true) : Array { return [ new PatternAsset( GAME_GROUP_ASSET_RADIX + gameId, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL)];}
		
		/**
		 * on est notifié que le jeu est prêt à être lancé
		 */
		protected function onGameReady() : void { shell.onGameReady();}
		
		/**
		 * on lance le chargement d'assets du jeu
		 */
		private function loadAssets() : void {
			AssetsMgr.getInstance().loadAssets(
				new CycloLoader(),
				getGamePatternAsset()
			).load( new CycloLoaderListener( onAssetsLoaded));
		}
		
		/**
		 * on est notifié de la fin de chargement des assets du jeu ; on lance leur allocation
		 * @param	pLoader	instance de loader qui a charsgé les assets
		 */
		private function onAssetsLoaded( pLoader : CycloLoader) : void {
			AssetsMgr.getInstance().mallocAssets(
				new NotifyMallocAssets( onMallocEnd, onMallocProgress),
				getGamePatternAsset()
			);
		}
		
		/**
		 * on est notifié de la fin d'allocation des assets du jeu
		 */
		private function onMallocEnd() : void { onGameReady(); }
		
		/**
		 * on est notifié de la progression de chargement des assets de jeu
		 */
		private function onMallocProgress( pDone : int, pTotal : int) : void { shell.onGameProgress( pDone / pTotal); }
	}

}