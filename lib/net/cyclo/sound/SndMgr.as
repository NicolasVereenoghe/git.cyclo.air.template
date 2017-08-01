package net.cyclo.sound {
	import flash.events.Event;
	import net.cyclo.loading.CycloLoader;
	import net.cyclo.loading.CycloLoaderListener;
	import net.cyclo.shell.MySystem;
	
	/**
	 * getionnaire de sons
	 * @author	nico
	 */
	public class SndMgr {
		/** nombre max de sons qu'on peut jouer en même temps */
		protected var MAX_SND							: int								= 20;
		
		/** le singleton */
		protected static var current					: SndMgr							= null;
		
		/** map de pistes sonores utilisées, indexées par id de piste */
		protected var tracks							: Object							= null;
		
		/** compteur de sons joué en ce moment en même temps */
		protected var sndCtr							: int								= -1;
		
		/**
		 * getter de singleton
		 * @return	ref sur le singleton
		 */
		public static function getInstance() : SndMgr {
			if ( ! current) current = new SndMgr();
			
			return current;
		}
		
		/**
		 * construction
		 */
		public function SndMgr() {
			tracks	= new Object();
			sndCtr	= 0;
		}
		
		/**
		 * on libère la mémoire des sons
		 * @param	pSubId		pattern de recherche d'identifiants de son à libérer ; laisser null pour tout décharger
		 * @param	pExcludeId	pattern d'exclusion d'identifiants de son ; laisser null pour aucune exclusion
		 */
		public function unload( pSubId : String = null, pExcludeId : String = null) : void {
			var lTrack	: SndTrack;
			
			for each( lTrack in tracks) {
				if ( pSubId == null || lTrack.sndId.indexOf( pSubId) != -1) {
					if( pExcludeId == null || lTrack.sndId.indexOf( pExcludeId) == -1) lTrack.unload();
				}
			}
		}
		
		/**
		 * on charge des sons en mémoire
		 * @param	pSubId		pattern de recherche d'identifiants de son à charger ; laisser null pour tout charger
		 * @param	pListener	interface de progression de chargement ; /!\ : on utilise CycloLoaderListener::onCurrentFileLoaded en interne pour suivre la progression ; laisser nulll pour charger sans contrôle
		 * @param	pExcludeId	pattern d'exclusion d'identifiants de son ; laisser null pour aucune exclusion
		 */
		public function load( pSubId : String = null, pListener : CycloLoaderListener = null, pExcludeId : String = null) : void {
			var lLoader	: CycloLoader	= new CycloLoader();
			var lTrack	: SndTrack;
			
			for each( lTrack in tracks) {
				if ( pSubId == null || lTrack.sndId.indexOf( pSubId) != -1){
					if ( pExcludeId == null || lTrack.sndId.indexOf( pExcludeId) == -1) lTrack.checkNDoLoading( lLoader);
				}
			}
			
			if ( pListener == null) pListener = new CycloLoaderListener( null);
			
			pListener.setOnCurrentFileLoaded( onSndFileLoaded);
			
			lLoader.load( pListener);
		}
		
		/**
		 * on ajoute une série de descriptions de sons
		 * @param	pDescs	liste de descripteur de sons (SndDesc)
		 */
		public function addSndDescs( pDescs : Array) : void {
			var lI		: int;
			var lId		: String;
			var lDesc	: SndDesc;
			
			for ( lI = 0 ; lI < pDescs.length ; lI++) {
				lDesc			= pDescs[ lI];
				lId				= lDesc.id;
				
				if ( tracks[ lId] != null) {
					MySystem.traceDebug( "WARING : SndMgr::addSndDescs : a sound descriptor exists, ignore new one : " + lId);
					continue;
				}
				
				tracks[ lId]	= new SndTrack( lId, lDesc);
			}
		}
		
		/**
		 * on joue un son
		 * @param	pSndId	identifiant de son
		 * @param	pMode	mode de lecture du son, laisser null pour une lecture par défaut
		 */
		public function play( pSndId : String, pMode : SndPlayMode = null) : void {
			if ( tracks[ pSndId] == null) tracks[ pSndId] = new SndTrack( pSndId);
			
			( tracks[ pSndId] as SndTrack).play( pMode);
		}
		
		/**
		 * on arrête les sons en libérant leur cannal
		 * @param	pSubId		pattern de recherche d'identifiants de son à arrêter ; laisser null pour tout arrêter
		 * @param	pExcludeId	pattern d'exclusion d'identifiants de son ; laisser null pour aucune exclusion
		 */
		public function stop( pSubId : String = null, pExcludeId : String = null) : void {
			var lTrack	: SndTrack;
			
			for each( lTrack in tracks) {
				if ( pSubId == null || lTrack.sndId.indexOf( pSubId) != -1) {
					if ( pExcludeId == null || lTrack.sndId.indexOf( pExcludeId) == -1) lTrack.stop();
				}
			}
		}
		
		/**
		 * on met en pause / on reprend la lecture de sons
		 * @param	pIsPause	true pour mettre en pause, false pour reprendre la lecture
		 * @param	pSubId		pattern de recherche d'identifiants de sons ; laisser null pour désigner tous les sons
		 * @param	pExcludeId	pattern d'exclusion d'identifiants de son ; laisser null pour aucune exclusion
		 */
		public function switchPause( pIsPause : Boolean, pSubId : String = null, pExcludeId : String = null) : void {
			var lTrack	: SndTrack;
			
			for each( lTrack in tracks) {
				if ( pSubId == null || lTrack.sndId.indexOf( pSubId) != -1) {
					if ( pExcludeId == null || lTrack.sndId.indexOf( pExcludeId) == -1) lTrack.switchPause( pIsPause);
				}
			}
		}
		
		/**
		 * on vérifie si des sons sont en train d'être joués
		 * @param	pSubId		pattern de recherche d'identifiants de son à vérifier ; laisser null pour tout vérifier
		 * @param	pExcludeId	pattern d'exclusion d'identifiants de son ; laisser null pour aucune exclusion
		 * @return	true si un son à vérifier est en train d'être joué, false sinon
		 */
		public function isPlaying( pSubId : String = null, pExcludeId : String = null) : Boolean {
			var lTrack	: SndTrack;
			
			for each( lTrack in tracks) {
				if ( pSubId == null || lTrack.sndId.indexOf( pSubId) != -1) {
					if ( pExcludeId == null || lTrack.sndId.indexOf( pExcludeId) == -1) {
						if( lTrack.isPlaying()) return true;
					}
				}
			}
			
			return false;
		}
		
		/**
		 * on récupère une liste triée par ordre d'ancienneté décroissante de lancement de canaux sonores correspondants au critère de recherche
		 * @param	pSubId		pattern de recherche d'identifiants de son à vérifier ; laisser null pour tout vérifier
		 * @param	pExcludeId	pattern d'exclusion d'identifiants de son ; laisser null pour aucune exclusion
		 * @return	liste de canaux de sons ( SndInstance) trié par ancienneté décroissante
		 */
		public function getChannelHistory( pSubId : String = null, pExcludeId : String = null) : Array {
			var lRes	: Array		= new Array();
			var lTrack	: SndTrack;
			
			for each( lTrack in tracks) {
				if ( pSubId == null || lTrack.sndId.indexOf( pSubId) != -1) {
					if ( pExcludeId == null || lTrack.sndId.indexOf( pExcludeId) == -1) {
						lTrack.updateChannelHistory( lRes);
					}
				}
			}
			
			return lRes;
		}
		
		/**
		 * on vérifie si les canaux sonores sont plein
		 * @return	true si plein, false sinon et du coup on peut jouer du son
		 */
		public function isFull() : Boolean { return sndCtr >= MAX_SND; }
		
		/**
		 * on est notifié qu'un son est lancé et qu'il occupe un canal
		 */
		public function onAddSnd() : void { sndCtr++; }
		
		/**
		 * on est notifié qu'un son s'arrête et qu'il libère un canal
		 */
		public function onRemSnd() : void { sndCtr--; }
		
		/**
		 * on est notifié de la fin de chargement d'un fichier de son
		 * @param	pLoader	loader chargé deu loading de ce fichier
		 */
		protected function onSndFileLoaded( pLoader : CycloLoader) : void {
			var lTrack	: SndTrack;
			
			for each( lTrack in tracks) {
				if ( lTrack.desc.file.id == pLoader.getCurLoadingFile().id) {
					lTrack.onSndLoaded( pLoader);
				}
			}
		}
	}
}