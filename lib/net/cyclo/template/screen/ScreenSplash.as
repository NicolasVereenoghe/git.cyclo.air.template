package net.cyclo.template.screen {
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	/**
	 * splash screen qui reste verrouillé tant qu'on ne le libère pas (::unlock)
	 * @author	nico
	 */
	public class ScreenSplash extends MyScreen {
		/** durée minimum d'affichage en ms */
		protected var WAIT_DURATION				: Number					= 2000;
		
		/** timer utilisé pour l'attente minimum ; null si pas en cours de contrôle ou timer fini */
		protected var timer						: Timer						= null;
		
		/** true si écran verrouillé, false sinon ; on déverrouille de l'extérieur, tend que verrouillé, ne peut pas à la suite */
		protected var isLocked					: Boolean					= true;
		
		/**
		 * construction
		 */
		public function ScreenSplash() {
			super();
			
			ASSET_ID		= "screen_splash";
			FADE_RGB_USE	= true;
			BG_RGB_USE		= true;
		}
		
		/**
		 * on demande le déverrouillage de l'écran ; si le timer est fini, on enchaîne
		 */
		public function unlock() : void {
			isLocked = false;
			
			if ( timer == null) launchFadeOut();
		}
		
		/** @inheritDoc */
		override protected function launchAfterInit() : void { shell.onScreenReady( this); }
		
		/** @inheritDoc */
		override public function start() : void {
			timer		= new Timer( WAIT_DURATION, 1);
			timer.addEventListener( TimerEvent.TIMER_COMPLETE, onWaitComplete);
			timer.start();
		}
		
		/** @inheritDoc */
		override public function switchPause( pIsPause : Boolean) : void {
			super.switchPause( pIsPause);
			
			if ( timer != null) {
				if ( pIsPause && timer.running) timer.stop();
				else if ( ( ! pIsPause) && ! timer.running) timer.start();
			}
		}
		
		/** @inheritDoc */
		override public function destroy() : void {
			killTimer();
			
			super.destroy();
		}
		
		/**
		 * on détruit le timer actif
		 */
		protected function killTimer() : void {
			if( timer != null){
				timer.stop();
				timer.removeEventListener( TimerEvent.TIMER_COMPLETE, onWaitComplete);
				
				timer = null;
			}
		}
		
		/**
		 * le timer actif a fini son attente, si l'écran est déverouillé, on enchaîne
		 * @param	pE	event de timer
		 */
		protected function onWaitComplete( pE : TimerEvent) : void {
			killTimer();
			
			if( ! isLocked) launchFadeOut();
		}
	}
}