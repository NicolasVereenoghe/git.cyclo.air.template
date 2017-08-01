package net.cyclo.template.shell {
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.assets.PatternAsset;
	import net.cyclo.loading.file.MyFile;
	import net.cyclo.mysprite.LvlMgr;
	import net.cyclo.paddle.AcceleroModeSwitcher;
	import net.cyclo.paddle.AcceleroMultiMode;
	import net.cyclo.paddle.IAcceleroModeSwitcher;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.template.game.IGameMgr;
	import net.cyclo.template.game.MyGameMgrSample1;
	import net.cyclo.template.screen.MyScreen;
	import net.cyclo.template.screen.ScreenSplash;
	
	/**
	 * exemple de shell avec auto orient / splash / start game avec moteur de sprites
	 * @author nico
	 */
	public class MyShellSample1 extends GameShell implements IAcceleroModeSwitcher {
		/** instance d'accéléro utilisée pour déterminer l'auto orientation au début (juste avant l'affichage du splash) */
		protected var contCalibr										: AcceleroMultiMode										= null;
		
		/** { x, y, z} du référentiel d'inclinaison en cours ( inclinaison des axes x, y, z sur [ -PI/2 .. PI/2]) ; null si pas encore défini */
		protected var _contRefXYZ										: Object												= null;
		
		/** flag indiquant si le chargement minimum d'assets est effectué (contenu de splash) (true), ou pas (false) */
		protected var isMiniReady										: Boolean												= false;
		
		/**
		 * accesseur au référentiel d'inclinaison en cours
		 * @return	{ x, y, z} ( inclinaison des axes x, y, z sur [ -PI/2 .. PI/2]) ; null si pas encore défini
		 */
		public function get contRefXYZ() : Object { return _contRefXYZ; }
		
		/** @inheritDoc */
		public function onRefChange( pFrom : Object, pTo : Object) : void {
			_contRefXYZ = pTo;
			
			MobileDeviceMgr.getInstance().rotContent = AcceleroModeSwitcher.getPopRot( pTo);
			
			if( contCalibr != null){
				contCalibr.destroy();
				contCalibr = null;
				
				if ( isMiniReady) onShellReadyMini();
			}else if ( curScreen != null) curScreen.updateRotContent();
		}
		
		/** @inheritDoc */
		override public function initShell( pContainer : DisplayObjectContainer, pLocalXML : Object = null, pAssetsXML : XML = null, pLocalFile : Object = null, pAssetsFile : MyFile = null) : void {
			super.initShell( pContainer.addChild( new Sprite()) as DisplayObjectContainer, pLocalXML, pAssetsXML, pLocalFile, pAssetsFile);
			
			// TODO : ajouter les sons : SndMgr.getInstance().addSndDescs( [ new SndDesc( <ID>, <VOL>)]);
			// TODO : SndMgr.getInstance().load();
			
			if ( AcceleroMultiMode.isSupported) {
				contCalibr = new AcceleroMultiMode( this);
				contCalibr.switchPause( false);
			}
		}
		
		/** @inheritDoc */
		override public function onBrowseDeactivate() : void {
			super.onBrowseDeactivate();
			
			if ( curGame != null && curScreen == null) curGame.switchPause( true);
		}
		
		/** @inheritDoc */
		override public function onBrowseReactivate() : void {
			super.onBrowseReactivate();
			
			if ( curGame != null && curScreen == null) curGame.switchPause( false);
		}
		
		/** @inheritDoc */
		override public function onGameReady() : void {
			( curScreen as ScreenSplash).unlock();
			
			curGame.startGame();
			curGame.switchPause( true);
		}
		
		/** @inheritDoc */
		override public function onScreenEnd( pScreen : MyScreen) : void {
			var lPatterns	: Array;
			
			super.onScreenEnd( pScreen);
			
			if ( pScreen is ScreenSplash) {
				lPatterns	= getAssetsMiniPatterns();
				
				AssetsMgr.getInstance().freeAssets( lPatterns);
				AssetsMgr.getInstance().unloadAssets( null, null, lPatterns);
				
				curGame.switchPause( false);
			}
		}
		
		/**
		 * on récupère une instance de splash screen à afficher ; utile à redéfinir pour donner un splash alternatif
		 * @return	instance de splash screen prête à être affichée
		 */
		protected function getSplashInstance() : ScreenSplash { return new ScreenSplash(); }
		
		/**
		 * on récupère l'id d'asset du symbole de level design
		 * @return	id d'asset de symbole de level design
		 */
		protected function getLvlAssetName() : String { return "lvld0"; }
		
		/** @inheritDoc */
		override protected function getAssetsMiniPatterns() : Array {
			return [
				new PatternAsset( "mini", PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL),
				new PatternAsset( "lvld", PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL)
			];
		}
		
		/** @inheritDoc */
		override protected function onShellReadyMini() : void {
			var lAsset	: AssetInstance;
			
			isMiniReady = true;
			
			if ( contCalibr == null) {
				lAsset = AssetsMgr.getInstance().getAssetInstance( getLvlAssetName());
				
				LvlMgr.getInstance().parseLvlTemplate( lAsset.content as DisplayObjectContainer);
				
				lAsset.free();
				
				setCurrentScreen( getSplashInstance());
				
				super.onShellReadyMini();
			}
		}
		
		/** @inheritDoc */
		override protected function loadAssets() : void { launchGame(); }
		
		/** @inheritDoc */
		override protected function getGameInstance() : IGameMgr { return new MyGameMgrSample1(); }
	}
}