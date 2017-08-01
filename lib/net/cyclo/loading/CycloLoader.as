package net.cyclo.loading {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	import net.cyclo.loading.file.LoadingFileSnd;
	
	import net.cyclo.loading.file.LoadingFile;
	import net.cyclo.loading.file.LoadingFileDisplay;
	import net.cyclo.loading.file.LoadingFileTxt;
	import net.cyclo.loading.file.MyFile;
	
	/**
	 * un loader de fichiers
	 * 
	 * @author	nico
	 */
	public class CycloLoader extends Sprite {
		/** objet recevant les notifications de progression du loading */
		protected var listener						: ICycloLoaderListener;
		
		/** poids total du chargement à effectuer à octets; -1 si non défini */
		protected var totalSize						: int;
		/** nombre d'octets chargés depuis l'appel au loading effectif */
		protected var curLoadedBytes				: int;
		
		/** indice courrant de fichier chargé dans la pile (0..n-1) */
		protected var currentLoadedFileI			: int;
		
		/** paramètre de version à utiliser par défaut si pas spécifié dans les fichiers à charger ; null si pas défini */
		protected var _defaultVersion				: String;
		
		/** pile de descripteurs de chargement de fichier */
		protected var fileLoads						: Array;
		
		/**
		 * on construit un loader qui va nous permettre de définir une pile de fichiers à charger, de lancer leur chargement, et de suivre la progression de l'opération
		 * @param	pDefaultVersion	paramètre de version à utiliser par défaut si pas spécifié dans les fichiers à charger ; laisser null si pas défini ; voir constantes MyFile::VERSION_NO_CACHE, MyFile::VERSION_CACHE 
		 */
		public function CycloLoader( pDefaultVersion : String = null) {
			_defaultVersion	= pDefaultVersion;
			fileLoads		= new Array();
		}
		
		/**
		 * libération de mémoire en fin de loading ; DEBUG : essaye d'interrompre le chargement en cours et libère les suivants
		 */
		public function destroy() : void {
			var lI	: int;
			
			if ( fileLoads != null) {
				for ( lI = currentLoadedFileI ; lI < fileLoads.length ; lI++) ( fileLoads[ lI] as LoadingFile).free();
			}
			
			fileLoads	= null;
			listener	= null;
			
			if( hasEventListener( Event.ENTER_FRAME)) removeEventListener( Event.ENTER_FRAME, onLoadProgress);
		}
		
		/**
		 * on récupère le descripteur de ficher en chargement, en cours de traitement
		 * @return	descripteur de fichier en chargement en cours, ou null si aucun
		 */
		public function getCurLoadingFile() : LoadingFile {
			if ( fileLoads != null && currentLoadedFileI < fileLoads.length) return fileLoads[ currentLoadedFileI];
			else return null;
		}
		
		/**
		 * on récupère la version par défaut pour les fichiers chargés ici
		 * @return	tag de version par défaut, ou null si pas défini
		 */
		public function get defaultVersion() : String { return _defaultVersion;}
		
		/**
		 * ajoute un fichier de type Display à la liste de chargement
		 * @param	pFile	descripteur du fichier à charger
		 */
		public function addDisplayFile ( pFile : MyFile) : void { fileLoads.push( new LoadingFileDisplay( pFile));}
		
		/**
		 * on ajoute un fichier de type texte à la liste de chargement
		 * @param	pFile	dsecripteur du fichier à charger
		 */
		public function addTxtFile( pFile : MyFile) : void { fileLoads.push( new LoadingFileTxt( pFile));}
		
		/**
		 * on ajoute un fichier de type son à la liste de chargement
		 * @param	pFile	descripteur de fichier à charger
		 */
		public function addSndFile( pFile : MyFile) : void { fileLoads.push( new LoadingFileSnd( pFile));}
		
		/**
		 * on lance le chargement de la pile de fichiers ajoutés au loader
		 * @param	pListener	instance écoutant la progression du chargement
		 * @param	pTotalSize	poids total du chargement en octets pour effectuer la progression ; laisser -1 par défaut pour ne pas se baser sur l'estimation (mais alors progression faussée)
		 */
		public function load( pListener : ICycloLoaderListener, pTotalSize : int = -1) : void {
			listener			= pListener;
			totalSize			= pTotalSize;
			currentLoadedFileI	= -1;
			curLoadedBytes		= 0;
			
			addEventListener( Event.ENTER_FRAME, onLoadProgress);
			
			loadNext();
		}
		
		/**
		 * donne le taux de progression du chargement en cours ; n'a de sens à appeler que quand le chargement est lancé
		 * @return	taux de progression : [ 0 <=> aucun avancement .. 1 <=> terminé]
		 */
		public function getProgressRate() : Number {
			if( totalSize > 0){
				if( currentLoadedFileI < fileLoads.length) return Math.min( 1, ( curLoadedBytes + LoadingFile( fileLoads[ currentLoadedFileI]).bytesLoaded) / totalSize);
				else return 1;
			}else return currentLoadedFileI / fileLoads.length;
		}
		
		/**
		 * un fichier de la pile de chargement, celui qui est en cours de chargement, notifie qu'il a fini de se charger
		 */
		public function onCurFileLoaded() : void {
			var lLoadedFile	: LoadingFile	= fileLoads[ currentLoadedFileI] as LoadingFile;
			
			curLoadedBytes	+= lLoadedFile.bytesLoaded;
			
			CycloLoaderMgr.getInstance().regLoadedFile( lLoadedFile);
			
			notifyLoadCurrentFileComplete();
			
			loadNext();
		}
		
		/**
		 * le fichier de pile en cours de chargement notifie qu'il rencontre une erreur de loading
		 */
		public function onCurFileError() : void {
			notifyLoadError();
			
			loadNext();
		}
		
		/**
		 * méthode qui itère le suivi de progression du loading
		 * @param	pE	évènement itérateur
		 */
		protected function onLoadProgress( pE : Event) : void { notifyLoadProgress();}
		
		/**
		 * initialise le chargement du fichier suivant dans la pile à charger
		 */
		protected function loadNext() : void {
			var lCurLoad	: LoadingFile;
			
			if( fileLoads != null){
				currentLoadedFileI++;
				
				if( currentLoadedFileI < fileLoads.length){
					lCurLoad = fileLoads[ currentLoadedFileI] as LoadingFile;
					
					if( CycloLoaderMgr.getInstance().isAlreadyLoaded( lCurLoad.id)){
						curLoadedBytes += CycloLoaderMgr.getInstance().getFileLoadedSize( lCurLoad.id);
						
						notifyLoadCurrentFileComplete();
						
						loadNext();
					}else lCurLoad.load( this);
				}else finalizeLoading();
			}
		}
		
		/**
		 * on finalise le loading de la pile de fichiers
		 */
		protected function finalizeLoading() : void {
			notifyLoadComplete();
			
			destroy();
		}
		
		/**
		 * on notifie notre listener de la progression 
		 */
		protected function notifyLoadProgress() : void { listener.onLoadProgress( this);}
		
		/**
		 * on notifie notre listener de la fin de tous les chargements
		 */
		protected function notifyLoadComplete() : void { listener.onLoadComplete( this);}
		
		/**
		 * on notifie notre listener que le fichier en cours de traitement dans la liste des fichiers à charger est arrivé au terme de son chargement
		 */
		protected function notifyLoadCurrentFileComplete() : void { listener.onCurrentFileLoaded( this); }
		
		/**
		 * on notifie notre listener d'une erreur de chargement du fichier de pile en cours de chargement
		 */
		protected function notifyLoadError() : void { listener.onLoadError( this); }
	}
}