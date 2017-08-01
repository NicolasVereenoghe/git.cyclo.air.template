package net.cyclo.template.shell {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.assets.AssetVarDesc;
	import net.cyclo.assets.NotifyMallocAssets;
	import net.cyclo.assets.PatternAsset;
	import net.cyclo.loading.CycloLoader;
	import net.cyclo.loading.CycloLoaderListener;
	import net.cyclo.loading.file.MyFile;
	import net.cyclo.mysprite.LvlMgr;
	import net.cyclo.paddle.AcceleroModeSwitcher;
	import net.cyclo.paddle.AcceleroMultiMode;
	import net.cyclo.paddle.IAcceleroModeSwitcher;
	import net.cyclo.paddle.ISwitchModeListener;
	import net.cyclo.paddle.OrientSwitcher;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.sound.SndDesc;
	import net.cyclo.sound.SndMgr;
	import net.cyclo.template.game.hud.IMyHUD;
	import net.cyclo.template.game.hud.MyHUDSample2;
	import net.cyclo.template.game.IGameMgr;
	import net.cyclo.template.game.MyGameMgrSample2;
	import net.cyclo.template.screen.MyScreen;
	import net.cyclo.template.screen.ScreenGUILoading;
	import net.cyclo.template.screen.ScreenGUITCLoading;
	import net.cyclo.template.screen.ScreenLoading;
	import net.cyclo.template.screen.ScreenPopGameover;
	import net.cyclo.template.screen.ScreenPopGameoverSample2;
	import net.cyclo.template.screen.ScreenPopHelp;
	import net.cyclo.template.screen.ScreenPopHelpSample2;
	import net.cyclo.template.screen.ScreenPopQuit;
	import net.cyclo.template.screen.ScreenPopQuitSample2;
	import net.cyclo.template.screen.ScreenPreloading;
	import net.cyclo.template.screen.ScreenReplayFade;
	import net.cyclo.template.screen.ScreenSelect;
	import net.cyclo.template.screen.ScreenSelectSample2;
	import net.cyclo.template.screen.ScreenSplash;
	import net.cyclo.template.screen.ScreenTC;
	import net.cyclo.template.screen.ScreenTCSample2;
	import net.cyclo.template.screen.ScreenTitle;
	import net.cyclo.template.screen.ScreenTitleSample2;
	import net.cyclo.template.shell.datas.SavedDatas;
	import net.cyclo.template.shell.score.MyScore;
	
	/**
	 * exemple de shell complet avec splash / loading / title / select / loading + help / start game moteur de sprites + hud / menu in-game pour retour au select
	 * 
	 * @author nico
	 */
	public class MyShellSample2 extends GameShell implements ISwitchModeListener, IAcceleroModeSwitcher {
		/** id de son de bouton */
		public static var SND_BUTTON									: String												= "button.mp3";
		
		/** couleur RGB du tracé du bg du shell */
		protected var SHELL_BG_COL										: uint													= 0xffffff;
		/** couleur RGB du bg du switcher de mode */
		protected var SWITCHER_BG_COL									: uint													= 0;
		/** couleur ARGB du bg du contenu pris en photo par le switcher de mode */
		protected var SWITCHER_CONTENT_BG_COL							: uint													= 0xFFFFFFFF;
		
		/** taux de préchargement apparent à partir duquel on parse les niveaux */
		protected var PARSE_LVL_PRELOAD_RATE							: Number												= .9;
		
		/** nom de groupe des assets "mini", nécessaires pour arriver jusq'au preloading ; virés de la mémoire en sortie de preloading */
		protected var ASSET_GROUP_MINI									: String												= "mini";
		/** nom de groupe des assets "preloading", assets commun à tous les loading mais déjà nécessaires au preload ; reste en mémoire */
		protected var ASSET_GROUP_PRELOAD								: String												= "preloading";
		/** nom de groupe des assets "gui", uniquement chargés quand on est dans le GUI (par opposition à in-game) */
		protected var ASSET_GROUP_GUI									: String												= "gui";
		/** nom de groupe des assets "tc", assets de GUI persistants sur les TC, alors que le reste du GUI est vidé */
		protected var ASSET_GROUP_TC									: String												= "tc";
		/** nom de groupe des assets partagés entre le GUI et le jeu, ils restent en mémoire */
		protected var ASSET_GROUP_SHARED								: String												= "shared";
		/** nom de grouê des assets de level design ; parsés et vidés de la mémoire dès que le shell est prêt */
		protected var ASSET_GROUP_LVLD									: String												= "lvld";
		/** racine de nom d'asset de level design */
		protected var ASSET_RADIX_LVLD									: String												= "lvld";
		/** nom de variable d'asset qui donne tous les suffix d'asset de level design ; si non défini, il n'y a qu'un level dont le nom est formé par la racine */
		protected var ASSET_VAR_LVLD									: String												= "#LVLD#";
		
		/** le BG du shell */
		protected var bgContainer										: DisplayObject											= null;
		
		/** instance d'accéléro utilisée pour déterminer l'auto orientation au début (juste avant l'affichage du splash) */
		protected var contCalibr										: AcceleroMultiMode										= null;
		
		/** gestionnaire de transition visuelle de changement d'orientation */
		protected var _orientSwitcher									: OrientSwitcher										= null;
		/** { x, y, z} du référentiel d'inclinaison en cours ( inclinaison des axes x, y, z sur [ -PI/2 .. PI/2]) ; null si pas encore défini */
		protected var _contRefXYZ										: Object												= null;
		
		/** flag indiquant si le chargement minimum d'assets est effectué (contenu de splash) (true), ou pas (false) */
		protected var isMiniReady										: Boolean												= false;
		
		/** index de jeu sélectionné pour jouer ; -1 si aucun de sélectionné */
		protected var selectedGameIndex									: int													= -1;
		
		/**
		 * accesseur au référentiel d'inclinaison en cours
		 * @return	{ x, y, z} ( inclinaison des axes x, y, z sur [ -PI/2 .. PI/2]) ; null si pas encore défini
		 */
		public function get contRefXYZ() : Object { return _contRefXYZ; }
		
		/**
		 * accesseur au switcher graphique d'orientation
		 * @return	switcher d'orientation
		 */
		public function get orientSwitcher() : OrientSwitcher { return _orientSwitcher; }
		
		/**
		 * on demande depuis le jeu d'ouvrir la popup de help
		 */
		public function askPopHelp() : void {
			switchGamePause( true);
			setCurrentScreen( new ScreenPopHelpSample2());
		}
		
		/** @inheritDoc */
		public function onRefChange( pFrom : Object, pTo : Object) : void {
			_contRefXYZ = pTo;
			
			MobileDeviceMgr.getInstance().rotContent = AcceleroModeSwitcher.getPopRot( pTo);
			
			if( contCalibr != null){
				contCalibr.destroy();
				contCalibr = null;
				
				if ( isMiniReady) onShellReadyMini();
			}else {
				if ( curScreen != null) curScreen.updateRotContent();
				
				if ( curHUD != null) curHUD.updateRotContent();
				
				if ( curGame != null) curGame.updateRotContent();
			}
		}
		
		/** @inheritDoc */
		public function onSwitchModeAnim( pIsBegin : Boolean) : void {
			switchLock( pIsBegin);
			
			if ( curScreen != null) curScreen.switchPause( pIsBegin);
		}
		
		/** @inheritDoc */
		override public function initShell( pContainer : DisplayObjectContainer, pLocalXML : Object = null, pAssetsXML : XML = null, pLocalFile : Object = null, pAssetsFile : MyFile = null) : void {
			bgContainer = pContainer.addChild( drawBGContainer());
			
			super.initShell( pContainer.addChild( new Sprite()) as DisplayObjectContainer, pLocalXML, pAssetsXML, pLocalFile, pAssetsFile);
			
			_orientSwitcher = new OrientSwitcher( pContainer.addChild( new Sprite()) as Sprite, container, SWITCHER_CONTENT_BG_COL, SWITCHER_BG_COL, this);
			
			if ( AcceleroMultiMode.isSupported) {
				contCalibr = new AcceleroMultiMode( this);
				contCalibr.switchPause( false);
			}
			
			defineSnd();
		}
		
		/** @inheritDoc */
		override public function onBrowseDeactivate() : void {
			super.onBrowseDeactivate();
			
			if ( curGame != null && curScreen == null && prevScreen == null) askPopHelp();
			
			if ( curScreen != null) curScreen.switchPause( true);
			if ( prevScreen != null) prevScreen.switchPause( true);
		}
		
		/** @inheritDoc */
		override public function onBrowseReactivate() : void {
			super.onBrowseReactivate();
			
			if ( curScreen != null) curScreen.switchPause( false);
			if ( prevScreen != null) prevScreen.switchPause( false);
			
			if ( curGame != null && curScreen == null && prevScreen == null) switchGamePause( false);
		}
		
		/** @inheritDoc */
		override public function onBrowseBack( pE : KeyboardEvent) : void {
			CONFIG::AIR{
				if ( pE.keyCode == Keyboard.BACK || pE.keyCode == Keyboard.MENU) {
					pE.preventDefault();
					pE.stopImmediatePropagation();
					
					if ( curScreen is ScreenTitle) MobileDeviceMgr.getInstance().exit();
					else {
						if ( curScreen != null) curScreen.onBrowseBack( pE);
						else if ( curGame != null) {
							SndMgr.getInstance().play( SND_BUTTON);
							
							onGameAborted();
						}
					}
				}
			}
		}
		
		/** @inheritDoc */
		override public function onGameover( pScore : MyScore = null, pSavedDatas : SavedDatas = null) : void {
			switchGamePause( true);
			setCurrentScreen( new ScreenPopGameoverSample2());
		}
		
		/** @inheritDoc */
		override public function onGameAborted() : void {
			switchGamePause( true);
			setCurrentScreen( new ScreenPopQuitSample2());
		}
		
		/** @inheritDoc */
		override public function onGameProgress( pRate : Number) : void { ( curScreen as ScreenLoading).onLoadProgress( .9 * pRate); }
		
		/** @inheritDoc */
		override public function onGameReady() : void {
			switchLock( false);
			
			startGame();
			switchGamePause( true);
			
			( curScreen as ScreenLoading).onLoadProgress( 1);
		}
		
		/** @inheritDoc */
		public override function enableGameHUD( pType : String) : IMyHUD {
			if ( curHUD != null) throw new Error( "ERROR : MyShellSample2::enableGameHUD : un HUD est déjà actif");
			
			curHUD = new MyHUDSample2();
			
			curHUD.init( this, myHUDContainer, null);
			
			return curHUD;
		}
		
		/** @inheritDoc */
		override public function onScreenReady( pScreen : MyScreen) : void {
			super.onScreenReady( pScreen);
			
			if ( pScreen is ScreenPopGameover) {
				switchLock( true);
			}else if ( pScreen is ScreenSplash) {
				switchLock( true);
				
				( pScreen as ScreenSplash).unlock();
			}else if ( pScreen is ScreenPreloading) {
				switchLock( true);
				
				loadAssets();
			}else if ( pScreen is ScreenTC) {
				switchLock( true);
				
				launchGame();
			}else if ( pScreen is ScreenGUILoading) {
				switchLock( true);
				
				AssetsMgr.getInstance().loadAssets(
					new CycloLoader(),
					new PatternAsset( ASSET_GROUP_GUI, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL)
				).load( new CycloLoaderListener( onAssetsGUILoaded));
			}else if ( pScreen is ScreenGUITCLoading) {
				switchLock( true);
				
				killGame();
				
				loadAssetsGUITC();
			}else if ( pScreen is ScreenReplayFade) {
				curGame.reset();
				
				if ( curHUD != null) {
					curHUD.destroy();
					curHUD = null;
				}
				
				curGame.startGame();
				switchGamePause( true);
				
				pScreen.askClose();
			}
		}
		
		/** @inheritDoc */
		override public function onScreenClose( pScreen : MyScreen, pNext : MyScreen = null) : void {
			if ( pScreen is ScreenTC && ! ( pScreen as ScreenTC).isPlay) killGame();
			
			super.onScreenClose( pScreen, pNext);
		}
		
		/** @inheritDoc */
		override public function onScreenEnd( pScreen : MyScreen) : void {
			var lPattern	: PatternAsset;
			
			if ( pScreen is ScreenSplash) setCurrentScreen( getPreloadingInstance());
			else if ( pScreen is ScreenPreloading) {
				setCurrentScreen( getAfterPreloadingInstance());
				
				super.onScreenEnd( pScreen);
				
				lPattern = new PatternAsset( ASSET_GROUP_MINI, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL);
				AssetsMgr.getInstance().freeAssets( lPattern);
				AssetsMgr.getInstance().unloadAssets( null, null, lPattern);
				
				return;
			}else if ( pScreen is ScreenTitle) setCurrentScreen( getSelectInstance());
			else if ( pScreen is ScreenSelect) {
				if ( ( pScreen as ScreenSelect).selectedIndex == -1) setCurrentScreen( getTitleInstance());
				else {
					selectedGameIndex = ( pScreen as ScreenSelect).selectedIndex;
					
					setCurrentScreen( getTCInstance());
					
					super.onScreenEnd( pScreen);
					
					lPattern = new PatternAsset( ASSET_GROUP_GUI, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL);
					AssetsMgr.getInstance().freeAssets( lPattern);
					AssetsMgr.getInstance().unloadAssets( null, null, lPattern);
					
					return;
				}
			}else if ( pScreen is ScreenTC) {
				if ( ( pScreen as ScreenTC).isPlay) {
					switchGamePause( false);
					
					super.onScreenEnd( pScreen);
					
					lPattern = new PatternAsset( ASSET_GROUP_TC, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL);
					AssetsMgr.getInstance().freeAssets( lPattern);
					AssetsMgr.getInstance().unloadAssets( null, null, lPattern);
					
					return;
				}else setCurrentScreen( getGUILoadingInstance());
			}else if ( pScreen is ScreenGUILoading) setCurrentScreen( getSelectInstance());
			else if ( pScreen is ScreenPopQuit) {
				if ( ( pScreen as ScreenPopQuit).isQuit) setCurrentScreen( getGUITCLoadingInstance());
				else if( ( pScreen as ScreenPopQuit).isReplay) setCurrentScreen( getReplayFadeInstance());
				else switchGamePause( false);
			}else if ( pScreen is ScreenGUITCLoading) setCurrentScreen( getFromGameToGUIInstance());
			else if ( pScreen is ScreenPopHelp) {
				if( ( pScreen as ScreenPopHelp).isReplay) setCurrentScreen( getReplayFadeInstance());
				else switchGamePause( false);
			}else if ( pScreen is ScreenPopGameover) {
				if ( ( pScreen as ScreenPopGameover).isReplay) setCurrentScreen( getReplayFadeInstance());
				else setCurrentScreen( getGUITCLoadingInstance());
			}else if ( pScreen is ScreenReplayFade) switchGamePause( false);
			
			super.onScreenEnd( pScreen);
		}
		
		/**
		 * on ajoute les sons de l'appli, et on lance leur préchargement ; à redéfinir pour ajouter de nouveaux sons
		 */
		protected function defineSnd() : void {
			SndMgr.getInstance().addSndDescs( [ new SndDesc( SND_BUTTON, .3)]);
			SndMgr.getInstance().load();
		}
		
		/**
		 * on récupère une instance de splash screen à afficher
		 * @return	instance de splash screen prête à être affichée
		 */
		protected function getSplashInstance() : ScreenSplash { return new ScreenSplash(); }
		
		/**
		 * on récupère une instance d'écran de preloading
		 * @return	instance d'écran de preloading
		 */
		protected function getPreloadingInstance() : ScreenPreloading { return new ScreenPreloading(); }
		
		/**
		 * on définit l'écran qui doit suivre après le preloading
		 * @return	instance d'écran qui suit le preloading
		 */
		protected function getAfterPreloadingInstance() : MyScreen { return getTitleInstance(); }
		
		/**
		 * on définit l'écran qui doit suivre quand on a quitté le jeu pour le GUI
		 * @return	instance d'écran point de chute quand on a quitté le jeu
		 */
		protected function getFromGameToGUIInstance() : MyScreen { return getSelectInstance(); }
		
		/**
		 * on récupère une instance de title screen
		 * @return	instance de title screen
		 */
		protected function getTitleInstance() : ScreenTitle { return new ScreenTitleSample2(); }
		
		/**
		 * on récupère une instance d'écran de sélection
		 * @return	instance d'écran de sélection
		 */
		protected function getSelectInstance() : ScreenSelect { return new ScreenSelectSample2(); }
		
		/**
		 * on récupère une instance d'écran de TC
		 * @return	instance d'écran de TC
		 */
		protected function getTCInstance() : ScreenTC { return new ScreenTCSample2( String( selectedGameIndex)); }
		
		/**
		 * on récupère une instance d'écran de chargement du GUI, quand on vient d'un tc
		 * @return	écran de chargement de GUI
		 */
		protected function getGUILoadingInstance() : ScreenGUILoading { return new ScreenGUILoading(); }
		
		/**
		 * on récupère une instance d'écran de chargement du GUI + TC, quand on vient du jeu
		 * @return	écran de chargement de GUI + TC
		 */
		protected function getGUITCLoadingInstance() : ScreenGUITCLoading { return new ScreenGUITCLoading(); }
		
		/**
		 * on récupère une instance d'écran de fade pendant regénération du jeu en cours (replay)
		 * @return	écran de fade
		 */
		protected function getReplayFadeInstance() : ScreenReplayFade { return new ScreenReplayFade(); }
		
		/**
		 * on crée le BG du shell
		 * @return	bg de shell
		 */
		protected function drawBGContainer() : DisplayObject {
			var lRect	: Rectangle	= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			var lBG		: Sprite	= new Sprite();
			
			lBG.graphics.beginFill( SHELL_BG_COL);
			lBG.graphics.drawRect( lRect.x, lRect.y, lRect.width, lRect.height);
			lBG.graphics.endFill();
			
			lBG.mouseChildren = false;
			lBG.mouseEnabled = false;
			
			return lBG;
		}
		
		/** @inheritDoc */
		override protected function getAssetsPatterns() : Array {
			return [
				new PatternAsset( ASSET_GROUP_GUI, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL),
				new PatternAsset( ASSET_GROUP_SHARED, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL),
				new PatternAsset( ASSET_GROUP_LVLD, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL),
				new PatternAsset( ASSET_GROUP_TC, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL)
			];
		}
		
		/** @inheritDoc */
		override protected function onMallocProgress( pDone : int, pTotal : int) : void { ( curScreen as ScreenLoading).onLoadProgress( PARSE_LVL_PRELOAD_RATE * pDone / pTotal); }
		
		/** @inheritDoc */
		override protected function onShellReady() : void {
			var lVar		: AssetVarDesc	= AssetsMgr.getInstance().getVar( ASSET_VAR_LVLD);
			var lAsset		: AssetInstance;
			var lPattern	: PatternAsset;
			var lI			: int;
			
			if ( lVar != null) {
				for ( lI = 0 ; lI < lVar.length ; lI++) {
					lAsset = AssetsMgr.getInstance().getAssetInstance( ASSET_RADIX_LVLD + lVar.getVal( lI));
					
					LvlMgr.getInstance().parseLvlTemplate( lAsset.content as DisplayObjectContainer, lVar.getVal( lI));
					
					lAsset.free();
				}
			}else {
				lAsset = AssetsMgr.getInstance().getAssetInstance( ASSET_RADIX_LVLD);
				
				LvlMgr.getInstance().parseLvlTemplate( lAsset.content as DisplayObjectContainer);
				
				lAsset.free();
			}
			
			lPattern = new PatternAsset( ASSET_GROUP_LVLD, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL);
			AssetsMgr.getInstance().freeAssets( lPattern);
			AssetsMgr.getInstance().unloadAssets( null, null, lPattern);
			
			( curScreen as ScreenLoading).onLoadProgress( 1);
		}
		
		/** @inheritDoc */
		override protected function getAssetsMiniPatterns() : Array {
			return [
				new PatternAsset( ASSET_GROUP_MINI, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL),
				new PatternAsset( ASSET_GROUP_PRELOAD, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL)
			];
		}
		
		/** @inheritDoc */
		override protected function onShellReadyMini() : void {
			isMiniReady = true;
			
			if ( contCalibr == null) setCurrentScreen( getSplashInstance());
		}
		
		/** @inheritDoc */
		override protected function getGameInstance() : IGameMgr {
			return new MyGameMgrSample2( String( selectedGameIndex));
		}
		
		/**
		 * on retourne une liste de patterns de recherche d'assets à charger lors du process d'initialisation complet d'assets
		 * @return	liste de patterns (PatternAsset) ; null si aucun asset
		 */
		protected function getAssetsGUITCPatterns() : Array {
			return [
				new PatternAsset( ASSET_GROUP_GUI, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL),
				new PatternAsset( ASSET_GROUP_TC, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL)
			];
		}
		
		/**
		 * on lance le chargement de GUI+TC en revenant du jeu pour arriver au gui
		 */
		private function loadAssetsGUITC() : void {
			AssetsMgr.getInstance().loadAssets(
				new CycloLoader(),
				getAssetsGUITCPatterns()
			).load( new CycloLoaderListener( onAssetsGUITCLoaded));
		}
		
		/**
		 * on est notifié de la fin de chargement des assets GUI+TC ; on lance leur allocation
		 * @param	pLoader	instance de loader qui a chargé les assets
		 */
		private function onAssetsGUITCLoaded( pLoader : CycloLoader) : void {
			AssetsMgr.getInstance().mallocAssets(
				new NotifyMallocAssets( onMallocGUIEnd, onMallocGUIProgress),
				getAssetsGUITCPatterns()
			);
		}
		
		/**
		 * on est notifié de la fin de chargement des assets GUI ; on lance leur allocation
		 * @param	pLoader	instance de loader qui a chargé les assets
		 */
		private function onAssetsGUILoaded( pLoader : CycloLoader) : void {
			AssetsMgr.getInstance().mallocAssets(
				new NotifyMallocAssets( onMallocGUIEnd, onMallocGUIProgress),
				new PatternAsset( ASSET_GROUP_GUI, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL)
			);
		}
		
		/**
		 * on est notifié de la progression d'allocation des assets de GUI ou GUI + TC
		 * @param	pDone	nombre d'assets alloués
		 * @param	pTotal	nombre total d'assets à allouer
		 */
		private function onMallocGUIProgress( pDone : int, pTotal : int) : void { ( curScreen as ScreenLoading).onLoadProgress( .9 * pDone / pTotal); }
		
		/**
		 * on est notifié de la fin d'allocation des assets de GUI ou GUI + TC
		 */
		private function onMallocGUIEnd() : void { ( curScreen as ScreenLoading).onLoadProgress( 1); }
	}
}