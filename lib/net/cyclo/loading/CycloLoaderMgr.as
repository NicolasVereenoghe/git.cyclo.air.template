package net.cyclo.loading {
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import net.cyclo.loading.file.LoadingFile;
	import net.cyclo.loading.file.MyFile;
	import net.cyclo.shell.MySystem;
	
	/**
	 * gestionnaire de loader ; singleton
	 * 
	 * @author	nico
	 */
	public class CycloLoaderMgr {
		/** singleton */
		protected static var instance				: CycloLoaderMgr			= null;
		
		/** map de fichiers déjà chargés (LoadingFile), indexés par identifiant de descripteur de chargement de fichier, sert d'historique */
		protected var loadedFiles					: Object;
		
		/** instance collection qui contient les embed dans ses propriétés statiques ; null si pas d'embed */
		protected var _embed						: Object					= null;
		
		/**
		 * récupère le singleton, le crée si n'existe pas encore
		 * @return	singleton
		 */
		public static function getInstance() : CycloLoaderMgr {
			if( instance == null) instance = new CycloLoaderMgr();
			
			return instance;
		}
		
		/**
		 * constructeur
		 */
		public function CycloLoaderMgr() {
			// TODO !!
			loadedFiles		= new Object();
		}
		
		/**
		 * on définit l'instance qui contient en propriétés les embed
		 * @param	pEmbed	instance de collection d'embed
		 */
		public function set embed( pEmbed : Object) : void { _embed = pEmbed;}
		
		/**
		 * on récupère un contenu embed
		 * @param	pId	identifiant de contenu embed dans la classe statique des embed qui a été spécifiée
		 * @return	réf sur contenu embed, ou null si aucun contenu correspondant
		 */
		public function getEmbedContent( pId : String) : Class {
			if ( _embed != null && _embed.hasOwnProperty( pId)) return _embed[ pId] as Class;
			else return null;
		}
		
		/**
		 * libère la mémoire allouée à un fichier chargé
		 * @param	pFile	descripteur de fichier
		 */
		public function freeLoadedFileMem( pFile : MyFile) : void {
			trace( "INFO : CycloLoaderMgr::freeLoadedFileMem : " + pFile.id);
			
			//if (loadedFiles[ pFile.id] != null) {
				LoadingFile( loadedFiles[ pFile.id]).free();
			//}
			
			delete loadedFiles[ pFile.id];
			
			MySystem.gc();
		}
		
		/**
		 * on enregistre un descripteur de fichier chargé
		 * @param	pLoadedFile	descripteur de fichier chargé
		 */
		public function regLoadedFile( pLoadedFile : LoadingFile) : void { loadedFiles[ pLoadedFile.id] = pLoadedFile;}
		
		/**
		 * détermine si un fichier a déjà été chargé
		 * @param	pFileId	identifiant de descripteur du fichier à chercher
		 * @return	true si déjà chargé, false sinon
		 */
		public function isAlreadyLoaded( pFileId : String) : Boolean { return ( loadedFiles[ pFileId] != null); }
		
		/**
		 * on récupère une référence sur un descripteur de chargement de fichier
		 * @param	pFileId	identifiant de descripteur du fichier
		 * @return	réf sur le descripteur, ou null si inextistant ou pas fini de charger
		 */
		public function getLoadingFile( pFileId : String) : LoadingFile {
			if( isAlreadyLoaded( pFileId)) return loadedFiles[ pFileId];
			else return null;
		}
		
		/**
		 * donne le poid d'un fichier déjà chargé
		 * @param	pFileId	identifiant de descripteur du fichier à chercher
		 * @return	poid en octet de ce fichier
		 */
		public function getFileLoadedSize( pFileId : String) : int { return ( loadedFiles[ pFileId] as LoadingFile).bytesLoaded;}
	}
}