package net.cyclo.sound {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.getTimer;
	import net.cyclo.shell.MySystem;
	
	/**
	 * instance de son ( descripteur de canal sonore ouvert)
	 * @author nico
	 */
	public class SndInstance {
		/** canal sonore de son */
		public var chan								: SoundChannel						= null;
		
		/** ref sur la piste sonore en charge de cette instance de son */
		protected var track							: SndTrack							= null;
		/** durée en ms du son */
		protected var len							: Number							= -1;
		/** moment de début de lecture en ms ; /!\ peut être recalculé en cas de pause  ; -1 signifie que le son n'a jamais été démarré */
		protected var from							: int								= -1;
		
		/** descripteur de mode de lecture de cette instance de son */
		protected var mode							: SndPlayMode						= null;
		
		/** flag indiquant si le son est en pause (true), ou pas (false) */
		protected var isPause						: Boolean							= false;
		/** moment temporisé de mise en pause ; -1 si aucune temporisation */
		protected var pausedAt						: int								= -1;
		/** flag indiquant si le son a été détecté comme ayant réellement commencé à jouer (true, false sinon) */
		protected var hasBegun						: Boolean							= false;
		
		/** itérateur de contrôle de lecture du canal sonore */
		protected var framer						: MovieClip							= null;
		/** méthode d'itération de mode de suivi de lecture */
		protected var doMode						: Function							= null;
		/** méthode de démarrage du son ; relatif au mode ; réutilisé pour la pause */
		protected var startMode						: Function							= null;
		
		/**
		 * construction
		 * @param	pTrack	piste sonore en charge de cette instance de son
		 */
		public function SndInstance( pTrack : SndTrack) {
			track	= pTrack;
		}
		
		/**
		 * on effectue une lecture simple
		 * @param	pMode	mode de lecture du son
		 */
		public function play( pMode : SndPlayMode) : void {
			framer	= new MovieClip();
			framer.addEventListener( Event.ENTER_FRAME, onFrame);
			
			mode	= pMode;
			len		= track.snd.length * ( pMode.loops + 1);
			
			if ( pMode is SndPlayModeChained) setModePlayChained();
			else setModePlay();
		}
		
		/**
		 * on stope la lecture, l'instance est prête à être détruite
		 */
		public function stop() : void {
			stopChan();
			
			track.onChanStop( this);
			track = null;
			
			mode = null;
		}
		
		/**
		 * on met en pause / on reprend la lecture de l'instance de son
		 * @param	pIsPause	true pour mettre en pause, false pour reprendre la lecture
		 */
		public function switchPause( pIsPause : Boolean) : void {
			if ( pIsPause && ! isPause) {
				if ( from > -1 && getTimer() - from >= len) stop();
				else{
					stopChan();
					
					pausedAt = getTimer();
					
					SndMgr.getInstance().onRemSnd();
				}
				
				isPause	= true;
			}else if ( isPause && ! pIsPause) {
				if ( SndMgr.getInstance().isFull()) {
					MySystem.traceDebug( "WARNING : SndInstance::switchPause : true : max, on ignore " + track.sndId);
				}else {
					isPause = false;
					
					SndMgr.getInstance().onAddSnd();
					
					framer	= new MovieClip();
					framer.addEventListener( Event.ENTER_FRAME, onFrame);
					
					startMode();
				}
			}
		}
		
		/**
		 * on récupère le moment de démarrage du son
		 * @return	moment de démarrage du son en ms, sur la progression de getTimer ; si son pas encore démarré, int::MAX_VALUE
		 */
		public function getFrom() : int {
			if ( from > -1) return from;
			else return int.MAX_VALUE;
		}
		
		/**
		 * on stoppe le canal sonore
		 */
		protected function stopChan() : void {
			if ( ! isPause) {
				hasBegun = false;
				
				framer.removeEventListener( Event.ENTER_FRAME, onFrame);
				framer = null;
				
				if( chan != null){
					chan.stop();
					chan = null;
				}else {
					MySystem.traceDebug( "WARNING : SndInstance::stopChan : null sound (no speakers ?) : " + track.sndId);
				}
			}
		}
		
		
		/**
		 * on effectue une itération de frame pour vérifier l'état de lecture du canal sonore
		 * @param	pE	event de frame
		 */
		protected function onFrame( pE : Event) : void { doMode(); }
		
		/**
		 * on passe en mode de suivi de lecture normale
		 */
		protected function setModePlay() : void {
			startMode	= startModePlay;
			doMode		= doModePlay;
			
			startMode();
		}
		
		/**
		 * on lance le son en mode lecture normale
		 */
		protected function startModePlay() : void {
			var lDT		: int;
			var lLen	: Number;
			
			if ( pausedAt > -1 && from > -1) {
				lLen	= track.snd.length;
				lDT 	= pausedAt - from;
				chan	= track.snd.play( lDT % lLen, mode.loops - Math.floor( lDT / lLen), new SoundTransform( mode.vol));
				
				if ( chan == null) {
					// même sans son, on simule le redémarrage
					hasBegun	= true;
					from		= getTimer() - lDT;
				}
			}else {
				pausedAt	= -1;
				chan		= track.snd.play( 0, mode.loops, new SoundTransform( mode.vol));
				
				if ( chan == null) {
					// même sans son, on simule son démarrage
					hasBegun	= true;
					from		= getTimer();
				}
			}
		}
		
		/**
		 * on agit en mode suivi de lecture normale
		 */
		protected function doModePlay() : void {
			var lDT		: int;
			var lLen	: Number;
			var lPos	: Number;
			var lCPos	: Number;
			
			if ( ! hasBegun) {
				lCPos	= Math.ceil( chan.position);
				
				if ( lCPos > 0) {
					hasBegun = true;
					
					if( pausedAt < 0) from = getTimer() - lCPos;
					else {
						lLen	= track.snd.length;
						lDT 	= pausedAt - from;
						lPos	= Math.floor( lDT % lLen);
						
						if ( lPos <= lCPos) from = getTimer() - lDT - ( lCPos - lPos);
						else from = getTimer() - lDT - ( lCPos + lLen - lPos);
					}
				}
			}else if ( getTimer() - from >= len) stop();
		}
		
		/**
		 * on passe en mode de suivi de lecture enchainée
		 */
		protected function setModePlayChained() : void {
			startMode	= startModePlayChained;
			doMode		= doModePlayChained;
			
			startMode();
		}
		
		/**
		 * on lance le son en mode lecture enchaînée
		 */
		protected function startModePlayChained() : void { }
		
		/**
		 * on agit en mode suivi de lecture enchainée
		 */
		protected function doModePlayChained() : void {
			if ( ! SndMgr.getInstance().isPlaying( ( mode as SndPlayModeChained).subId)) setModePlay();
		}
	}
}