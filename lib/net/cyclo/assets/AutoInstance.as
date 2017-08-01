package net.cyclo.assets {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.getQualifiedClassName;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * asset instanciée in-line dans un conteneur movieclip
	 * util pour inclure des images externes sans les avoir dans la mémoire swc
	 * l'asset est supposé disponible (chargé et alloué)
	 * 
	 * @author nico
	 */
	public class AutoInstance extends MovieClip {
		/** identifiant d'asset déduit de cette instance ; null si pas encore défini */
		protected var _id											: String												= null;
		
		/** instance d'asset désignée par l'AutoAsset */
		protected var _instance										: AssetInstance											= null;
		
		/**
		 * construction
		 */
		public function AutoInstance() {
			super();
			
			_id = getQualifiedClassName( this);
			
			MySystem.traceDebug( "INFO : AutoInstance : " + _id);
			
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
			
			initialize();
		}
		
		/**
		 * le clip est retiré de la scène, on libère la mémoire
		 * @param	pE	évènement de virage de scène ; peut être levé pour tout enfant du clip, on doit contrôler qu'il s'agit bien de l'instance
		 */
		protected function onRemove( pE : Event) : void {
			if ( pE.currentTarget == this) {
				MySystem.traceDebug( "INFO : AutoInstance::onRemove : " + _id);
				
				removeEventListener( Event.REMOVED_FROM_STAGE, onRemove);
				
				UtilsMovieClip.free( _instance);
				_instance.free();
				
				_instance = null;
			}
		}
		
		/**
		 * on lance la construction du contenu : accès au loading/malloc d'asset asynchrone ; process prend fin avec la notification IAutoAssetMgr::onAutoAssetReady
		 */
		protected function initialize() : void {
			MySystem.traceDebug( "INFO : AutoInstance::initialize : " + _id);
			
			while ( numChildren > 0) UtilsMovieClip.free( getChildAt( 0));
			
			_instance = addChild( AssetsMgr.getInstance().getAssetInstance( _id)) as AssetInstance;
		}
	}
}