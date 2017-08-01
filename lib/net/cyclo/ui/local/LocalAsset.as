package net.cyclo.ui.local {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.getQualifiedClassName;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * gère l'affichage d'un asset qui varie suivant la localisation
	 * on utilise l'id de liaison du composant comme racine de nom d'asset, l'id de localisation comme suffixe. le nom obtenu correspond à un id d'asset qu'on ajoute dans le composant
	 */
	public class LocalAsset extends MovieClip implements ILocalListener {
		/** réf sur l'asset localisé ; null si pas encore initialisé */
		protected var asset						: AssetInstance						= null;
		/** indice de localisation de l'asset en cours ; -1 si pas encore initialisé */
		protected var langId					: int								= -1;
		
		/**
		 * construction
		 */
		public function LocalAsset() {
			super();
			
			addEventListener( Event.ADDED_TO_STAGE, onAdded, false, 0, true);
		}
		
		/** @inheritDoc */
		public function onLocalUpdate() : void {
			if ( LocalMgr.getInstance().getCurLangInd() != langId) {
				clearAsset();
				addAsset();
			}
		}
		
		/**
		 * on captude l'event d'ajout sur la scène
		 * @param	pE	event d'ajout sur scène
		 */
		protected function onAdded( pE : Event) : void {
			removeEventListener( Event.ADDED_TO_STAGE, onAdded);
			addEventListener( Event.REMOVED_FROM_STAGE, onRemove);
			
			while ( numChildren > 0) UtilsMovieClip.free( getChildAt( 0));
			
			LocalMgr.getInstance().addListener( this);
			
			addAsset();
		}
		
		/**
		 * on capture l'event de dégagement de la scène
		 * @param	pE	event de virage de la scène
		 */
		protected function onRemove( pE : Event) : void {
			clearAsset();
			
			removeEventListener( Event.REMOVED_FROM_STAGE, onRemove);
			LocalMgr.getInstance().remListener( this);
		}
		
		/**
		 * on libère l'asset en cours, si il y en a un
		 */
		protected function clearAsset() : void {
			if ( asset != null) {
				UtilsMovieClip.free( asset);
				asset.free();
				
				asset = null;
			}
		}
		
		/**
		 * on ajoute l'asset localisé
		 */
		protected function addAsset() : void {
			langId	= LocalMgr.getInstance().getCurLangInd();
			asset	= addChild( AssetsMgr.getInstance().getAssetInstance( getQualifiedClassName( this) + langId)) as AssetInstance;
		}
	}

}