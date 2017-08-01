package net.cyclo.sound {
	import flash.events.Event;
	import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import net.cyclo.loading.CycloLoader;
	import net.cyclo.loading.CycloLoaderListener;
	import net.cyclo.loading.CycloLoaderMgr;
	import net.cyclo.loading.file.LoadingFile;
	import net.cyclo.shell.MySystem;
	
	/**
	 * piste sonore
	 * @author	nico
	 */
	public class SndTrack {
		/** descripteur du son */
		protected var _desc								: SndDesc								= null;
		
		/** instance de son gérée par cette piste sonore ; null si pas encore alloué */
		protected var _snd								: Sound									= null;
		
		/** dictionnaire de descripteurs de canaux sonores ouverts */
		protected var channels							: Dictionary							= null;
		
		/** indique si le son doit être joué automatiquement dès qu'il est prêt (true), ou pas (false) */
		protected var shouldPlayOnReady					: Boolean								= false;
		/** mode de lecture à adopter sur un son joué automatiquement dès qu'il est prêt, ou null si aucun mode en particulier de défini */
		protected var playModeOnReay					: SndPlayMode							= null;
		/** indique si un chargement a été lancé pour le fichier de ce son */
		protected var isLoading							: Boolean								= false;
		
		/**
		 * construction
		 * @param	pId			identifiant de son
		 * @param	pDesc		descripteur de son ; laisser null pour une config par défaut
		 */
		public function SndTrack( pId : String, pDesc : SndDesc = null) {
			var lLoader	: CycloLoader;
			
			if ( pDesc == null) _desc = new SndDesc( pId);
			else _desc = pDesc;
			
			channels	= new Dictionary();
		}
		
		/**
		 * on libère la mémoire du son, sans altérer le descripteur
		 */
		public function unload() : void {
			stop();
			
			if ( CycloLoaderMgr.getInstance().getLoadingFile( _desc.file.id) != null) CycloLoaderMgr.getInstance().freeLoadedFileMem( _desc.file);
			
			isLoading	= false;
			_snd		= null;
		}
		
		/**
		 * on inserre les canaux sonores dans une liste triée par ordre décroissant d'ancienneté de lancement
		 * @param	pSortList	liste de canaux ( SndInstance) triés où inserrer les canaux de cette piste
		 */
		public function updateChannelHistory( pSortList : Array) : void {
			var lBeg	: int;
			var lEnd	: int;
			var lMid	: int;
			var lChan	: SndInstance;
			var lFrom	: int;
			
			for each( lChan in channels) {
				lFrom	= lChan.getFrom();
				lBeg	= 0;
				lEnd	= pSortList.length;
				lMid	= Math.floor( ( lBeg + lEnd) / 2);
				
				while ( lBeg < lEnd) {
					if ( lFrom > ( pSortList[ lMid] as SndInstance).getFrom()) {
						lBeg = lMid + 1;
					}else if ( lFrom < ( pSortList[ lMid] as SndInstance).getFrom()) {
						lEnd = lMid;
					}else break;
					
					lMid = Math.floor( ( lBeg + lEnd) / 2);
				}
				
				pSortList.splice( lMid, 0, lChan);
			}
		}
		
		/**
		 * on est notifié que le son a fini par se charger
		 * @param	pLoader	loader responsable du chargement du son ; null si aucun
		 */
		public function onSndLoaded( pLoader : CycloLoader) : void {
			isLoading = false;
			
			_snd = CycloLoaderMgr.getInstance().getLoadingFile( _desc.file.id).getLoadedContent() as Sound;
			
			if ( shouldPlayOnReady) addSndInstance( playModeOnReay);
		}
		
		/**
		 * on récupère l'identifiant de son
		 * @return	identifiant de son
		 */
		public function get sndId() : String { return _desc.id; }
		
		/**
		 * on récupère le descripteur du son de cette piste
		 * @return	descripteur de son
		 */
		public function get desc() : SndDesc { return _desc; }
		
		/**
		 * on récupère l'instance de son géré par cette piste
		 * @return	instance de son, ou null si pas encore alloué
		 */
		public function get snd() : Sound { return _snd; }
		
		/**
		 * on joue une occurence de son de la piste
		 * @param	pMode	mode de lecture du son, laisser null pour une lecture par défaut
		 */
		public function play( pMode : SndPlayMode = null) : void {
			if ( _snd != null) addSndInstance( pMode);
			else {
				shouldPlayOnReady	= true;
				playModeOnReay		= pMode;
				
				checkNDoLoading();
			}
		}
		
		/**
		 * on arrête toutes les occurences de sons de cette piste
		 */
		public function stop() : void {
			var lChans	: Dictionary	= new Dictionary( true);
			var lChan	: SndInstance;
			
			for each( lChan in channels) lChans[ lChan] = lChan;
			for each( lChan in lChans) lChan.stop();
			
			shouldPlayOnReady	= false;
			playModeOnReay		= null;
		}
		
		/**
		 * on met en pause / on reprend la lecture des sons de la piste
		 * @param	pIsPause	true pour mettre en pause, false pour reprendre la lecture
		 */
		public function switchPause( pIsPause : Boolean) : void {
			var lChan	: SndInstance;
			
			for each( lChan in channels) lChan.switchPause( pIsPause);
		}
		
		/**
		 * on vérifie si au moins un son de la piste est en train d'être joué
		 * @return	true si un son est en train d'être joué, false sinon
		 */
		public function isPlaying() : Boolean {
			var lChan	: SndInstance;
			
			for each( lChan in channels) return true;
			
			return isLoading && shouldPlayOnReady;
		}
		
		/**
		 * on est notifié de l'arrêt d'un canal de la piste
		 * @param	pChan	canal qui s'est arrêté et qu'on libère
		 */
		public function onChanStop( pChan : SndInstance) : void {
			channels[ pChan] = null;
			delete channels[ pChan];
			
			SndMgr.getInstance().onRemSnd();
		}
		
		/**
		 * le son est lancé en mode exclusif (SndPlayModeExclusive), on nétoie les sons trop vieux
		 * @param	pMode	mode d'exclusivité du son
		 */
		protected function removeChannelOldHistory( pMode : SndPlayModeExclusive) : void {
			var lSnds	: Array	= SndMgr.getInstance().getChannelHistory( pMode.subId);
			var lDif	: int	= lSnds.length - pMode.maxSnd;
			var lI		: int;
			
			//MySystem.traceDebug( pMode.subId + " : " + lSnds.length + " // " + pMode.maxSnd);
			
			if ( lDif > 0) {
				for ( lI = 0 ; lI < lDif ; lI++) {
					( lSnds[ lI] as SndInstance).stop();
				}
			}
		}
		
		/**
		 * on lance une instance de son
		 * @param	pMode	mode de lecture du son, laisser null pour une lecture par défaut
		 */
		protected function addSndInstance( pMode : SndPlayMode = null) : void {
			var lTmpMpde	: SndPlayMode	= null;
			var lSnd		: SndInstance;
			
			if ( pMode != null) {
				if ( pMode is SndPlayModeExclusive) removeChannelOldHistory( pMode as SndPlayModeExclusive);
			}else if( _desc.defaultPlayMode is SndPlayModeExclusive) removeChannelOldHistory( _desc.defaultPlayMode as SndPlayModeExclusive);
			
			if ( SndMgr.getInstance().isFull()) {
				MySystem.traceDebug( "WARNING : SndTrack::addSndInstance : max, on ignore " + sndId);
			}else {
				SndMgr.getInstance().onAddSnd();
				
				lSnd			= new SndInstance( this);
				channels[ lSnd]	= lSnd;
				
				if ( pMode == null) pMode = _desc.defaultPlayMode;
				else pMode.wrapDesc( _desc);
				
				lSnd.play( pMode);
			}
		}
		
		/**
		 * on vérifie si un chargement a été lancé ; si ce n'est pas le cas, on charge ; si l'identifiant de son a une correspondance en liaison, on utilise cette définition en mémoire
		 * @param	pLoader	instance de loader où empiler le chargement ; si null, on gère le chargement de manière discrète en interne
		 */
		public function checkNDoLoading( pLoader : CycloLoader = null) : void {
			if ( ApplicationDomain.currentDomain.hasDefinition( sndId)) {
				_snd = ( new ( getDefinitionByName( sndId) as Class)()) as Sound;
				
				onSndLoaded( null);
			} else if ( ! isLoading) {
				isLoading = true;
				
				if( pLoader == null){
					pLoader	= new CycloLoader();
					
					pLoader.addSndFile( _desc.file);
					
					pLoader.load( new CycloLoaderListener( onSndLoaded));
				}else {
					pLoader.addSndFile( _desc.file);
				}
			}
		}
	}
}