package net.cyclo.loading.file {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import net.cyclo.loading.CycloLoader;
	import net.cyclo.loading.CycloLoaderMgr;
	import net.cyclo.shell.MySystem;
	
	/**
	 * {abstract}
	 * descripteur d'un chargement de fichier
	 * 
	 * @author	nico
	 */
	public class LoadingFile {
		/** nom du paramètre de version */
		protected var VERSION_PARAM			: String		= "version";
		
		/** descripteur du fichier à charger */
		protected var _file					: MyFile;
		
		/** composant de gestion de loading responsable de ce descripteur */
		protected var cycloLoader			: CycloLoader;
		
		/** version par défaut définie dans le gestionnaire de chargement (CycloLoader) responsable de ce descripteur ; null si pas utilisé */
		protected var defaultVersion		: String		= null;
		
		/**
		 * on récupère l'identifiant de propriété embed d'un identifiant de fichier qu'on précise
		 * @param	pId		identifiant de fichier (peut être son url, on ne garde que le nom de fichier et son extension)
		 * @return	conversion du descripteur de fichier en nom d'embed
		 */
		public static function getEmbedNameFromId( pId : String) : String {
			pId = pId.split( "?")[ 0];
			
			if ( pId.indexOf( "://") != -1) pId = pId.split( "://")[ 1];
			
			pId = pId.replace( /\\/g, "/");
			pId = pId.replace( /\.\.\//g, "");
			pId = pId.replace( /\.\//g, "");
			pId = pId.replace( /\//g, "_");
			pId = pId.replace( /\./g, "_");
			
			return pId;
		}
		
		/**
		 * construction
		 * @param	pFile			descripteur du fichier à charger
		 */
		public function LoadingFile( pFile : MyFile) {
			_file		= pFile;
			
			buildLoader();
			addLoaderListener();
		}
		
		/**
		 * {abstract}
		 * libère la mémoire occupée par le loader
		 */
		public function free() : void {
			trace( "INFO : LoadingFile::free : " + _file.id);
			
			if ( cycloLoader != null) removeLoaderListener();
			
			_file		= null;
			cycloLoader	= null;
		}
		
		/**
		 * donne l'identifiant du descripteur de loading
		 * @return	identifiant, on se base sur l'identifiant du descripteur de fichier
		 */
		public function get id() : String { return _file.id;}
		
		/**
		 * on récupère la référence du fichier dont on s'occupe du chargement
		 * @return	le fichier géré par le chargement
		 */
		public function get file() : MyFile { return _file;}
		
		/**
		 * {abstract}
		 * donne le poid en octets déjà chargés
		 * @return	octets déjà chargé
		 */
		public function get bytesLoaded() : int {
			trace( "ERROR : LoadingFile::bytesLoaded méthode abstraite, doit être redéfinie !");
			
			return 0;
		}
		
		/**
		 * on vérifie si le fichier décrit est embed
		 * @return	true si embed, false sinon
		 */
		public function isEmbed() : Boolean { return CycloLoaderMgr.getInstance().getEmbedContent( getEmbedName()) != null; }
		
		/**
		 * lance le chargement du fichier
		 * @param	pCycloLoader	composant de gestion de loading responsable de ce descripteur lors de son chargement
		 */
		public function load( pCycloLoader : CycloLoader) : void {
			cycloLoader		= pCycloLoader;
			defaultVersion	= cycloLoader.defaultVersion;
			
			doLoad();
		}
		
		/**
		 * {abstract}
		 * récupère le dispatcher d'event sur le loader utilisé ; contexte = ajouter les listener de fin de chargement et d'erreur
		 * @return	dispatcher du loader utilisé
		 */
		public function getLoaderDispatcher() : EventDispatcher {
			trace( "ERROR : LoadingFile::getLoaderDispatcher méthode abstraite, doit être redéfinie !");
			
			return null;
		}
		
		/**
		 * {abstract}
		 * on récupère le contenu chargé du fichier
		 * 
		 * TODO : gérer des erreurs typiques ? voir AssetDesc ... genre ReferenceError ...
		 * 
		 * @param	pId		identifiant de resource à rechercher dans le fichier (utile pour les symbole à id dans un swf) ; laisser null si n'a pas de sens (time line de swf, ou fichier texte) ; voir les définitions des filles pour savoir si c'est géré
		 * @return	contenu chargé ; le type varie suivant le contenu chargé, voir spécialisations des filles de LoadingFile
		 */
		public function getLoadedContent( pId : String = null) : * {
			trace( "ERROR : LoadingFile::getLoadedContent méthode abstraite, doit être redéfinie !");
			
			return null;
		}
		
		/**
		 * {abstract}
		 * implélmentation du lancement du loading
		 */
		protected function doLoad() : void { trace( "ERROR : LoadingFile::doLoad méthode abstraite, doit être redéfinie !");}
		
		/**
		 * {abstract}
		 * on construit l'instance de loader
		 */
		protected function buildLoader() : void { trace( "ERROR : LoadingFile::getLoaderDispatcher méthode abstraite, doit être redéfinie !");}
		
		/**
		 * on ajoute les écouteurs sur les évènement de fin de chargement et d'erreur
		 */
		protected function addLoaderListener() : void {
			var lEvtDisp	: EventDispatcher	= getLoaderDispatcher();
			
			lEvtDisp.addEventListener( Event.COMPLETE, onLoadComplete);
			lEvtDisp.addEventListener( IOErrorEvent.IO_ERROR, onLoadIOError);
		}
		
		/**
		 * on retire les écouteurs sur les évènements de fin de chargement et d'erreur
		 */
		protected function removeLoaderListener() : void {
			var lEvtDisp	: EventDispatcher	= getLoaderDispatcher();
			
			lEvtDisp.removeEventListener( Event.COMPLETE, onLoadComplete);
			lEvtDisp.removeEventListener( IOErrorEvent.IO_ERROR, onLoadIOError);
		}
		
		/**
		 * appelé quand le loader en cours a fini de charger le fichier
		 * @param	pE	évènement à la source de l'appel
		 */
		protected function onLoadComplete( pE : Event) : void {
			removeLoaderListener();
			
			cycloLoader.onCurFileLoaded();
			
			cycloLoader = null;
		}
		
		/**
		 * appelé quand le loader en cours signale une erreur de chargement
		 * @param	pE	évènement d'erreur d'entrée / sortie à la source de l'appel
		 */
		protected function onLoadIOError( pE : IOErrorEvent) : void {
			MySystem.traceDebug( "WARNING : LoadingFile::onLoadIOError : " + id);
			
			removeLoaderListener();
			
			cycloLoader.onCurFileError();
			
			cycloLoader = null;
		}
		
		/**
		 * on récupère l'identifiant de propriété embed du fichier qu'on veut charger
		 * @return	conversion du descripteur de fichier en nom d'embed
		 */
		protected function getEmbedName() : String { return getEmbedNameFromId( getUrlRequest().url);}
		
		/**
		 * on construit l'objet de description d'url de fichier pour le charger
		 * @return	descripteur d'url du fichier
		 */
		protected function getUrlRequest() : URLRequest {
			var lName		: String	= _file.realName;
			var lExtPath	: String	= MySystem.getExtPath( String( lName.split( "?")[ 0]).split( ".").pop());
			var lPath		: String	= _file.path != null ? ( MySystem.getTagPath( _file.path) != null ? MySystem.getTagPath( _file.path) : _file.path) : ( lExtPath != null ? lExtPath : "");
			var lUrl		: String;
			
			if( lName.indexOf( "://") != -1) lUrl = lName;
			else if( lPath.indexOf( "://") != -1) lUrl = lPath + lName;
			else if( MySystem.mainPath != null) lUrl = MySystem.mainPath + lPath + lName;
			else lUrl = lPath + lName;
			
			if( _file.version != null){
				if( _file.version != MyFile.VERSION_CACHE) lUrl = addVersionToUrl( lUrl, _file.version);
			}else if( defaultVersion != null){
				if( defaultVersion != MyFile.VERSION_CACHE) lUrl = addVersionToUrl( lUrl, defaultVersion);
			}
			
			return new URLRequest( lUrl);
		}
		
		/**
		 * on ajoute la version en fin de paramètres de l'url spécifiée
		 * @param	pUrl		url où ajouter le paramètre de version
		 * @param	pVersion	tag de version anti-cache (MyFile::VERSION_CACHE) ou valeur à faire figurer litéralement dans le paramètre de version
		 * @return	nouvelle url avec le paramètre de version ajouté
		 */
		protected function addVersionToUrl( pUrl : String, pVersion : String) : String {
			if( pVersion == MyFile.VERSION_NO_CACHE) pVersion = ( new Date()).time.toString();
			
			if( pUrl.indexOf( "?") != -1) return pUrl + "&" + VERSION_PARAM + "=" + pVersion;
			else return pUrl + "?" + VERSION_PARAM + "=" + pVersion;
		}
	}
}