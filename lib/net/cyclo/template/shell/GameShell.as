package net.cyclo.template.shell {
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import net.cyclo.loading.file.MyFile;
	import net.cyclo.shell.MySystem;
	import net.cyclo.template.game.hud.IMyHUD;
	import net.cyclo.template.game.IGameMgr;
	import net.cyclo.template.shell.datas.SavedDatas;
	import net.cyclo.template.shell.score.MyScore;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * implémentation commune d'un shell de jeu
	 * @author nico
	 */
	public class GameShell extends ShellDefaultRender implements IGameShell {
		/** conteneur de jeu */
		protected var gameContainer						: DisplayObjectContainer;
		/** conteneur de HUD */
		protected var myHUDContainer					: DisplayObjectContainer;
		
		/** réf sur le jeu en cours d'éxé, ou null si aucun */
		protected var curGame							: IGameMgr					= null;
		/** réf sur l'instance de HUD qui a été activée ; null si aucune instance active */
		protected var curHUD							: IMyHUD					= null;
		
		/** @inheritDoc */
		public override function initShell( pContainer : DisplayObjectContainer, pLocalXML : Object = null, pAssetsXML : XML = null, pLocalFile : Object = null, pAssetsFile : MyFile = null) : void {
			gameContainer	= DisplayObjectContainer( pContainer.addChild( new Sprite()));
			myHUDContainer	= DisplayObjectContainer( pContainer.addChild( new Sprite()));
			
			super.initShell( pContainer, pLocalXML, pAssetsXML, pLocalFile, pAssetsFile);
		}
		
		/** @inheritDoc */
		public function onGameReady() : void { startGame(); }
		
		/** @inheritDoc */
		public function onGameProgress( pRate : Number) : void { MySystem.traceDebug( "INFO : GameShell::onGameProgress : " + pRate); }
		
		/** @inheritDoc */
		public function onGameAborted() : void { killGame(); }
		
		/** @inheritDoc */
		public function onGameover( pScore : MyScore = null, pSavedDatas : SavedDatas = null) : void { onGameAborted(); }
		
		/** @inheritDoc */
		public function enableGameHUD( pType : String) : IMyHUD { return null; }
		
		/** @inheritDoc */
		public function getCurGame() : IGameMgr { return curGame; }
		
		/**
		 * on retourne les données sauvegardées pour le jeu en cours ; il doit y avoir une instance de jeu en cours
		 * @return	données sauvées du jeu en cours ; instance vierge si inexistant
		 */
		protected function getCurGameSavedDatas() : SavedDatas { return getSavedDatas( curGame.gameId, true); }
		
		/**
		 * on lance le jeu désigné par ::gameId
		 */
		protected function launchGame() : void {
			curGame = getGameInstance();
			curGame.init( this, gameContainer, getCurGameSavedDatas());
		}
		
		/**
		 * on fait le start du jeu en cours
		 */
		protected function startGame() : void { curGame.startGame();}
		
		/**
		 * on bascule la pause du jeu
		 * @param	pPause	true pour mettre en pause, false sinon
		 */
		protected function switchGamePause( pPause : Boolean) : void {
			curGame.switchPause( pPause);
			
			if ( curHUD != null) curHUD.switchPause( pPause);
		}
		
		/**
		 * on libère la mémoire d'un jeu
		 */
		protected function killGame() : void {
			if ( curHUD != null) {
				curHUD.destroy();
				curHUD = null;
			}
			
			curGame.destroy();
			curGame = null;
			
			while ( gameContainer.numChildren > 0) UtilsMovieClip.free( gameContainer.getChildAt( 0));
		}
		
		/**
		 * on retourne l'instance de jeu à lancer en fonction l'identifiant de jeu défini lors de la construction de la coque minimale (voir ::gameId)
		 * @return	instance de jeu à lancer ; null si aucune instance trouvée
		 */
		protected function getGameInstance() : IGameMgr { return null; }
	}
}