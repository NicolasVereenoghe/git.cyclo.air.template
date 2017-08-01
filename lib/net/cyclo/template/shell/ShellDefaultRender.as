package net.cyclo.template.shell {
	import adobe.utils.CustomActions;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.assets.IExternalExportGenerator;
	import net.cyclo.assets.NotifyMallocAssets;
	import net.cyclo.loading.CycloLoader;
	import net.cyclo.loading.CycloLoaderListener;
	import net.cyclo.loading.CycloLoaderMgr;
	import net.cyclo.loading.file.MyFile;
	import net.cyclo.shell.device.IDeviceCurRenderMgr;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.template.screen.MyScreen;
	import net.cyclo.template.shell.datas.SavedDatas;
	import net.cyclo.ui.local.LocalMgr;
	
	/**
	 * super classe de shell et de gestion de fonctionnalités de rendu de device
	 * @author nico
	 */
	public class ShellDefaultRender implements IShell, IDeviceCurRenderMgr {
		/** le conteneur principal de la coque du jeu */
		protected var container				: DisplayObjectContainer;
		
		/** conteneur de conteneurs d'écran principal de coque */
		protected var screenContainer		: DisplayObjectContainer;
		
		/** écran principal de coque actif ; null si aucun */
		protected var curScreen				: MyScreen					= null;
		/** précédent écran principal de coque ; null si aucun */
		protected var prevScreen			: MyScreen					= null;
		/** flag indiquant si l'écran en cours est prêt (true) ou pas (false) */
		protected var isCurScreenReady		: Boolean;
		
		/** liste de xml de localisation (Array of XML), ou null si non dispo en local */
		private var localXML				: Array						= null;
		/** xml de description d'assets, ou null si non dispo en local */
		private var assetsXML				: XML						= null;
		/** liste de descripteurs de fichier de localisation à charger (Array of MyFile), null si aucun */
		private var localFile				: Array						= null;
		/** descripteur de fichier d'assets à charger, null si aucun */
		private var assetsFile				: MyFile					= null;
		
		/** identifiant de sauvegarde du jeu */
		protected var SAVE_ID				: String					= "save";
		/** id de map de données des propriétés globales */
		protected var DATAS_GLOBAL_ID		: String					= "global";
		/** id de map de données spécifiques par défaut */
		protected var DATAS_DEFAULT_ID		: String					= "default";
		
		/** @inheritDoc */
		public function onBrowseDeactivate() : void  { MySystem.traceDebug( "INFO : ShellDefaultRender::onBrowseDeactivate");}
		
		/** @inheritDoc */
		public function onBrowseReactivate() : void  { MySystem.traceDebug( "INFO : ShellDefaultRender::onBrowseReactivate");}
		
		/** @inheritDoc */
		public function onBrowseBack( pE : KeyboardEvent) : void { MySystem.traceDebug( "INFO : ShellDefaultRender::onBrowseBack"); }
		
		/** @inheritDoc */
		public function initShell( pContainer : DisplayObjectContainer, pLocalXML : Object = null, pAssetsXML : XML = null, pLocalFile : Object = null, pAssetsFile : MyFile = null) : void {
			container		= pContainer;
			screenContainer	= DisplayObjectContainer( container.addChild( new Sprite()));
			
			if ( pLocalXML is XML) localXML = [ pLocalXML];
			else localXML = pLocalXML as Array;
			
			if ( pLocalFile is MyFile) localFile = [ pLocalFile];
			else localFile = pLocalFile as Array;
			
			assetsXML		= pAssetsXML;
			assetsFile		= pAssetsFile;
			
			initAssetsMini();
		}
		
		/** @inheritDoc */
		public function onScreenClose( pScreen : MyScreen, pNext : MyScreen = null) : void {
			prevScreen = pScreen;
			
			switchLock( true);
			
			setCurrentScreen( pNext);
		}
		
		/** @inheritDoc */
		public function onScreenEnd( pScreen : MyScreen) : void {
			prevScreen = null;
			
			pScreen.destroy();
			
			switchLock( false);
		}
		
		/** @inheritDoc */
		public function onScreenReady( pScreen : MyScreen) : void {
			isCurScreenReady = true;
			
			pScreen.start();
			
			switchLock( false);
		}
		
		/**
		 * @param	pId	si "", on considère qu'il s'agit de données spécifiques, on génère un id par défaut
		 * @inheritDoc
		 */
		public function getSavedDatas( pId : String, pForce : Boolean = false) : SavedDatas {
			var lSO		: SharedObject	= SharedObject.getLocal( SAVE_ID);
			var lRes	: String;
			
			if ( pId == null) pId = DATAS_GLOBAL_ID;
			else if ( pId == "") pId = DATAS_DEFAULT_ID;
			
			lRes = lSO.data[ pId];
			
			if ( lRes != null || pForce) {
				if ( pId == DATAS_GLOBAL_ID) return instanciateSavedDatasGlobal( lRes);
				else return instanciateSavedDatasSpecific( lRes);
			}else return null;
		}
		
		/**
		 * @param	pId	si "", on considère qu'il s'agit de données spécifiques, on génère un id par défaut
		 * @inheritDoc
		 */
		public function setSavedDatas( pId : String, pDatas : SavedDatas) : void {
			var lSO		: SharedObject	= SharedObject.getLocal( SAVE_ID);
			
			if ( pId == null) pId = DATAS_GLOBAL_ID;
			else if ( pId == "") pId = DATAS_DEFAULT_ID;
			
			if ( pDatas != null) lSO.data[ pId] = pDatas.getDatas();
			else delete lSO.data[ pId];
			
			lSO.flush();
		}
		
		/**
		 * crée une instance de données sauvegardables globales
		 * @param	pSerialString	string de données serialisées, null si aucune
		 * @return	instance de données sauvegardables
		 */
		protected function instanciateSavedDatasGlobal( pSerialString : String) : SavedDatas { return new SavedDatas( pSerialString); }
		
		/**
		 * crée une instance de données sauvegardables spécifique
		 * @param	pSerialString	string de données serialisées, null si aucune
		 * @return	instance de données sauvegardables
		 */
		protected function instanciateSavedDatasSpecific( pSerialString : String) : SavedDatas { return new SavedDatas( pSerialString); }
		
		/**
		 * on instancie le singleton du gestionnaire de localisation
		 * @param	pXmls	liste de xml de localisation
		 */
		protected function instanciateLocalMgr( pXmls : Array) : void { new LocalMgr( pXmls); }
		
		/**
		 * on active / désactive le verrou global de souris : pour déverrouiller, on vérifie si l'ecran en cours et le précédent sont respectivement prêt et fini
		 * @param	pIsLock	true pour verrouiller, false sinon
		 */
		protected function switchLock( pIsLock : Boolean) : void {
			if ( pIsLock) MobileDeviceMgr.getInstance().switchLock( true);
			else if( prevScreen == null && curScreen == null || prevScreen == null && isCurScreenReady) MobileDeviceMgr.getInstance().switchLock( false);
		}
		
		/**
		 * on définit l'écran en cours
		 * @param	pScreen	l'écran qui devient celui en cours ; null si aucun écran en cours
		 */
		protected function setCurrentScreen( pScreen : MyScreen) : void {
			curScreen			= pScreen;
			isCurScreenReady	= false;
			
			if ( curScreen != null) {
				switchLock( true);
				
				curScreen.initScreen( this, addScreenDisplay( curScreen));
			}
		}
		
		/**
		 * on ajoute un écran à la zone d'écran
		 * @param	pScreen	instance d'écran dont on ajoute le conteneur graphique à la zone d'écran
		 * @return	conteneur graphique de l'écran
		 */
		protected function addScreenDisplay( pScreen : MyScreen) : DisplayObjectContainer { return screenContainer.addChildAt( new Sprite(), 0) as DisplayObjectContainer; }
		
		/**
		 * on retourne une liste de patterns de recherche d'assets à charger lors du process d'initialisation minimale d'assets
		 * @return	liste de patterns (PatternAsset) ; null si aucun asset
		 */
		protected function getAssetsMiniPatterns() : Array { return null; }
		
		/**
		 * on retourne une liste de patterns de recherche d'assets à charger lors du process d'initialisation complet d'assets
		 * @return	liste de patterns (PatternAsset) ; null si aucun asset
		 */
		protected function getAssetsPatterns() : Array { return null;}
		
		/**
		 * on est notifié que la coque est prête à être lancée avec son contenu minimale
		 */
		protected function onShellReadyMini() : void { loadAssets(); }
		
		/**
		 * on est notifié que la coque est prête à être lancée avec son contenu au complet
		 */
		protected function onShellReady() : void {}
		
		/**
		 * on récupère une interface de génération externe d'export d'assets
		 * @return	ref sur interface à utiliser par le gestionnaire d'assets, ou null si pas utilisé
		 */
		protected function getAssetsExternalExportGenerator() : IExternalExportGenerator { return null;}
		
		/**
		 * on lance le loading complet des assets de la coque
		 */
		protected function loadAssets() : void {
			var lPatterns	: Array	= getAssetsPatterns();
			
			if( lPatterns != null){
				AssetsMgr.getInstance().loadAssets(
					new CycloLoader(),
					lPatterns
				).load( new CycloLoaderListener( onAssetsLoaded, onAssetsLoadProgress));
			}else onShellReady();
		}
		
		/**
		 * on est notifié que la description des assets a bien été construite
		 */
		protected function onAssetDescBuilt() : void { MySystem.traceDebug( "INFO : ShellDefaultRender::onAssetDescBuilt"); }
		
		/**
		 * on lance le process d'initialisation minimale d'assets : loading de localisation et de descripteur d'assets
		 */
		private function initAssetsMini() : void {
			var lLocal	: Array			= localXML;
			var lAssets	: XML			= assetsXML;
			var lLoader	: CycloLoader;
			var lI		: int;
			
			if ( ( lLocal != null && lLocal.length > 0) && lAssets != null || ( lLocal == null || lLocal.length == 0) && lAssets == null && ( localFile == null || localFile.length == 0) && assetsFile == null) onAssetsMiniFilesLoaded( null);
			else {
				lLoader	= new CycloLoader();
				
				if ( lLocal == null || lLocal.length == 0) {
					if ( localFile != null) {
						for ( lI = 0 ; lI < localFile.length ; lI++) lLoader.addTxtFile( localFile[ lI] as MyFile);
					}
				}
				
				if ( lAssets == null) lLoader.addTxtFile( assetsFile);
				
				lLoader.load( new CycloLoaderListener( onAssetsMiniFilesLoaded));
			}
		}
		
		/**
		 * les fichiers du process minimal d'initialisation ont été chargé ; on initialise les gestionnaires de localisation et d'assets ; on lance le chargement minimal d'assets
		 * @param	pLoader		loader qui a chargé les fichiers ou null si les données ne proviennent pas d'un loader
		 */
		private function onAssetsMiniFilesLoaded( pLoader : CycloLoader) : void {
			var lLocal	: Array			= localXML;
			var lAssets	: XML			= assetsXML;
			var lLocals	: Array;
			var lI		: int;
			
			if ( lLocal != null && lLocal.length > 0) instanciateLocalMgr( lLocal);
			else if( localFile != null && localFile.length > 0){
				lLocals = new Array();
				
				for ( lI = 0 ; lI < localFile.length ; lI++) {
					lLocals.push( new XML( CycloLoaderMgr.getInstance().getLoadingFile( ( localFile[ lI] as MyFile).id).getLoadedContent()));
				}
				
				instanciateLocalMgr( lLocals);
			}
			
			if ( lAssets != null) AssetsMgr.getInstance( lAssets, getAssetsExternalExportGenerator());
			else if( assetsFile != null) AssetsMgr.getInstance(
				new XML( CycloLoaderMgr.getInstance().getLoadingFile( assetsFile.id).getLoadedContent()),
				getAssetsExternalExportGenerator()
			);
			
			onAssetDescBuilt();
			
			loadAssetsMini();
		}
		
		/**
		 * on lance le chargement des assets minimum
		 */
		private function loadAssetsMini() : void {
			var lPatterns	: Array	= getAssetsMiniPatterns();
			
			if( lPatterns != null){
				AssetsMgr.getInstance().loadAssets(
					new CycloLoader(),
					lPatterns
				).load( new CycloLoaderListener( onAssetsMiniLoaded));
			}else onShellReadyMini();
		}
		
		/**
		 * on est notifié de la fin de chargement des assets minimum ; on lance leur allocation
		 * @param	pLoader	instance de loader qui a charsgé les assets
		 */
		private function onAssetsMiniLoaded( pLoader : CycloLoader) : void {
			AssetsMgr.getInstance().mallocAssets(
				new NotifyMallocAssets( onMallocMiniEnd),
				getAssetsMiniPatterns()
			);
		}
		
		/**
		 * on est notifié de la fin d'allocation des assets minimum
		 */
		private function onMallocMiniEnd() : void { onShellReadyMini(); }
		
		/**
		 * on est notifié de la progression de loading des assets
		 * @param	pLoader	instance de loader qui charge les assets
		 */
		protected function onAssetsLoadProgress( pLoader : CycloLoader) : void { MySystem.traceDebug( "INFO : ShellDefaultRender::onAssetsLoadProgress : " + pLoader.getProgressRate()); }
		
		/**
		 * on est notifié de la fin de chargement des assets du jeu ; on lance leur allocation
		 * @param	pLoader	instance de loader qui a chargé les assets
		 */
		private function onAssetsLoaded( pLoader : CycloLoader) : void {
			AssetsMgr.getInstance().mallocAssets(
				new NotifyMallocAssets( onMallocEnd, onMallocProgress),
				getAssetsPatterns()
			);
		}
		
		/**
		 * on est notifié de la progression d'allocation des assets
		 * @param	pDone	nombre d'assets alloués
		 * @param	pTotal	nombre total d'assets à allouer
		 */
		protected function onMallocProgress( pDone : int, pTotal : int) : void { MySystem.traceDebug( "INFO : ShellDefaultRender::onMallocProgress : " + ( pDone / pTotal)); }
		
		/**
		 * on est notifié de la fin d'allocation des assets complets
		 */
		private function onMallocEnd() : void { onShellReady();}
	}
}