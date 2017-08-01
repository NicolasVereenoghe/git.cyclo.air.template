package net.cyclo.assets {
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.utils.getQualifiedClassName;
	import net.cyclo.loading.CycloLoader;
	import net.cyclo.loading.CycloLoaderListener;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * asset instanciée in-line dans un conteneur movieclip
	 * util pour inclure des images externes sans précharger, ainsi on n'occupe la mémoire qu'avec ce qu'on voit
	 * instance d'asset qui se génère automatiquement si elle s'ajoute au stage, et se libère si retirée du stage
	 * traitement asynchrone lors de la construction fait que l'asset peut ne pas être prêt tout de suite
	 * quand ajouté au stage, on fait remonter l'info (de parent en parent) jusqu'à trouver un IAutoAssetMgr pour lui signaler sa présence,
	 * puis, quand l'asset est alloué, idem, on fait remonter l'info à un IAutoAssetMgr pour qu'il libère le déroulement du jeu
	 * 
	 * @author nico
	 */
	public class AutoAsset extends MovieClip {
		/** sémaphore de génération d'assets, true quand en cours de génération et donc indique que les outils de génération ne sont pas disponibles, false si le verrou du sémaphore est relaché */
		protected static var assetGenSema							: Boolean												= false;
		/** pile d'instances qui attendent d'être générées ; null si pas encore utilisée */
		protected static var assetGenWaitStack						: Array													= null;
		
		/** identifiant d'asset déduit de cette instance ; null si pas encore défini */
		protected var _id											: String												= null;
		
		/** instance d'asset désignée par l'AutoAsset */
		protected var _instance										: AssetInstance											= null;
		
		/**
		 * construction
		 */
		public function AutoAsset( ) {
			super();
			
			_id = getQualifiedClassName( this);
			
			MySystem.traceDebug( "INFO : AutoAsset : " + _id);
			
			stop();
			
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
		}
		
		/**
		 * on capte l'ajout sur le stage, on notifie le gestionnaire parent
		 * @param	pE	event d'ajout sur stage
		 */
		protected function onAddedToStage( pE : Event) : void {
			removeEventListener( Event.ADDED_TO_STAGE, onAddedToStage);
			
			addEventListener( Event.REMOVED_FROM_STAGE, onRemove);
			
			getParentMgr().onAutoAssetAdded( this);
			
			initialize();
		}
		
		/**
		 * le clip est retiré de la scène, on libère la mémoire
		 * @param	pE	évènement de virage de scène ; peut être levé pour tout enfant du clip, on doit contrôler qu'il s'agit bien de l'instance
		 */
		protected function onRemove( pE : Event) : void {
			var lPat	: PatternAsset;
			
			if ( pE.currentTarget == this) {
				MySystem.traceDebug( "INFO : AutoAsset::onRemove : " + _id);
				
				removeEventListener( Event.REMOVED_FROM_STAGE, onRemove);
				
				UtilsMovieClip.free( _instance);
				_instance.free();
				
				if ( _instance.desc.activeCtr == 0) {
					MySystem.traceDebug( "INFO : AutoAsset::onRemove : freeAsset " + _id);
					
					lPat = new PatternAsset( _id, PatternAsset.FIND_ON_ID, PatternAsset.MATCH_ALL);
					AssetsMgr.getInstance().freeAssets( lPat);
					AssetsMgr.getInstance().unloadAssets( null, null, lPat);
				}
				
				_instance = null;
			}
		}
		
		/**
		 * on lance la construction du contenu : accès au loading/malloc d'asset asynchrone ; process prend fin avec la notification IAutoAssetMgr::onAutoAssetReady
		 */
		protected function initialize() : void {
			MySystem.traceDebug( "INFO : AutoAsset::initialize : " + _id);
			
			if ( AssetsMgr.getInstance().getAssetDescById( _id).isMalloc()) attachAssetInstance();
			else if( assetGenSema){
				if ( assetGenWaitStack == null) assetGenWaitStack = new Array();
				
				assetGenWaitStack.push( this);
			}else genAssetInstance();
		}
		
		/**
		 * on lance la génération de l'asset désigné par cet AutoAsset ; on vérouille le sémaphore de génération
		 */
		protected function genAssetInstance() : void {
			assetGenSema = true;
			
			AssetsMgr.getInstance().loadAssets(
				new CycloLoader(),
				new PatternAsset( _id, PatternAsset.FIND_ON_ID, PatternAsset.MATCH_ALL)
			).load( new CycloLoaderListener( onAssetLoaded));
		}
		
		/**
		 * on signale la fin de chargement de l'asset désigné par l'AutoAsset, on lance son 
		 * @param	pLoader	loader qui a chargé l'asset
		 */
		protected function onAssetLoaded( pLoader : CycloLoader) : void {
			AssetsMgr.getInstance().mallocAssets(
				new NotifyMallocAssets( onMallocEnd),
				new PatternAsset( _id, PatternAsset.FIND_ON_ID, PatternAsset.MATCH_ALL)
			);
		}
		
		/**
		 * on capte la fin d'allocation mémoire, on instancie l'asset et on vérifie si il n'y en pas d'autres qui attendent le sémaphore
		 */
		protected function onMallocEnd() : void {
			attachAssetInstance();
			
			if ( assetGenWaitStack == null || assetGenWaitStack.length == 0) assetGenSema = false;
			else {
				( assetGenWaitStack.shift() as AutoAsset).genAssetInstance();
			}
		}
		
		/**
		 * on instancie l'asset désigné par l'AutoAsset, on signale que tout est prêt
		 */
		protected function attachAssetInstance() : void {
			while ( numChildren > 0) UtilsMovieClip.free( getChildAt( 0));
			
			_instance = addChild( AssetsMgr.getInstance().getAssetInstance( _id)) as AssetInstance;
			
			getParentMgr().onAutoAssetReady( this);
		}
		
		/**
		 * on recherche un parent gestionnaire, le premier rencontré dans l'imbrication montante
		 * @return	instance de gestionnaire, c'est probablement une erreur si on n'en trouve pas
		 */
		protected function getParentMgr() : IAutoAssetMgr {
			var lParent	: DisplayObjectContainer	= parent;
			
			while( ! ( lParent == null || lParent is Stage)){
				if ( lParent is IAutoAssetMgr) return lParent as IAutoAssetMgr;
				
				lParent = lParent.parent;
			}
			
			MySystem.traceDebug( "ERROR : AutoAsset::getParentMgr : aucun gestionnaire parent");
			
			return null;
		}
	}
}