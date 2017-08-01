package net.cyclo.loading {
	import net.cyclo.shell.MySystem;
	
	/**
	 * implémentation d'un écouteur de loading
	 * @author nico
	 */
	public class CycloLoaderListener implements ICycloLoaderListener {
		/** ref sur callback de notification de loading fini, utiliser la même signature que ::onLoadComplete ; si null, pas de notification */
		protected var _onLoadComplete			: Function		= null;
		
		/** ref sur callback de notification de progression, utiliser la même signature que ::onLoadProgress ; si null, pas de notification */
		protected var _onLoadProgress			: Function		= null;
		
		/** ref sur callback de notification de fichier en cours de loading chargé, utiliser la même signature que ::onCurrentFileLoaded ; si null, pas de notification */
		protected var _onCurrentFileLoaded		: Function		= null;
		
		/** callback de notification d'échec de chargement, utiliser la même signature que ::onLoadError ; si null, pas de notification */
		protected var _onLoadError				: Function		= null;
		
		/**
		 * construction ; on transmet des callback pour gérer les écoutes d'events de loading
		 * @param	pOnLoadComplete			callback de notification de loading fini, utiliser la même signature que ::onLoadComplete ; si null, pas de notification
		 * @param	pOnLoadProgress			callback de notification de progression, utiliser la même signature que ::onLoadProgress ; si null, pas de notification
		 * @param	pOnCurrentFileLoaded	callback de notification de fichier en cours de loading chargé, utiliser la même signature que ::onCurrentFileLoaded ; si null, pas de notification
		 * @param	pOnLoadError			callback de notification d'échec de chargement, utiliser la même signature que ::onLoadError ; si null, pas de notification
		 */
		public function CycloLoaderListener( pOnLoadComplete : Function, pOnLoadProgress : Function = null, pOnCurrentFileLoaded : Function = null, pOnLoadError : Function = null) {
			_onLoadComplete			= pOnLoadComplete;
			_onLoadProgress			= pOnLoadProgress;
			_onCurrentFileLoaded	= pOnCurrentFileLoaded;
			_onLoadError			= pOnLoadError;
		}
		
		/** @inheritDoc */
		public function onLoadComplete( pLoader : CycloLoader) : void {
			if ( _onLoadComplete != null) {
				_onLoadComplete( pLoader);
				
				_onLoadComplete			= null;
				_onLoadProgress			= null;
				_onCurrentFileLoaded	= null;
				_onLoadError			= null;
			}
		}
		
		/** @inheritDoc */
		public function onLoadProgress( pLoader : CycloLoader) : void { if ( _onLoadProgress != null) _onLoadProgress( pLoader);}
		
		/** @inheritDoc */
		public function onCurrentFileLoaded( pLoader : CycloLoader) : void { if ( _onCurrentFileLoaded != null) _onCurrentFileLoaded( pLoader); }
		
		/** @inheritDoc */
		public function onLoadError( pLoader : CycloLoader) : void {
			MySystem.traceDebug( "WARNING : CycloLoaderListener::onLoadError : " + pLoader.getCurLoadingFile().id);
			
			if ( _onLoadError != null) _onLoadError( pLoader);
		}
		
		/**
		 * on définit la callback de fin de chargement d'un fichier de la pile de chargement
		 * @param	pOnCurrentFileLoaded	callback de notification de fichier en cours de loading chargé, utiliser la même signature que ::onCurrentFileLoaded
		 */
		public function setOnCurrentFileLoaded( pOnCurrentFileLoaded : Function) : void {
			if ( _onCurrentFileLoaded != null)  MySystem.traceDebug( "WARNING : CycloLoaderListener::setOnCurrentFileLoaded : _onCurrentFileLoaded already defined, override current value");
			
			_onCurrentFileLoaded = pOnCurrentFileLoaded;
		}
	}
}