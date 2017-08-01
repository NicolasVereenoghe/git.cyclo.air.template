package net.cyclo.template.screen {
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.ui.MyButton;
	
	/**
	 * pop up de fin de partie ; on propose de rejouer ou de continuer vers le menu
	 * 
	 * @author nico
	 */
	public class ScreenPopGameover extends MyScreen {
		/** durée minimum de verrouillage en ms */
		protected var WAIT_DURATION						: Number								= 1500;
		
		/** timer utilisé pour l'attente minimum ; null si pas en cours de contrôle ou timer fini */
		protected var timer								: Timer									= null;
		
		/** bouton rejouer */
		protected var btReplay							: MyButton								= null;
		/** bouton next */
		protected var btNext							: MyButton								= null;
		
		/** flag indiquant si on veut rejouer le niveau en cours (true) ou pas (false) pour continuer vers la suite */
		protected var _isReplay							: Boolean								= false;
		
		/**
		 * construction
		 */
		public function ScreenPopGameover() {
			super();
			
			ASSET_ID	= "screen_popGameover";
		}
		
		/**
		 * on vérifie si on a appuyé sur rejouer en fermant cette pop up
		 * @return	true pour rejouer, false sinon (continuer vers la suite)
		 */
		public function get isReplay() : Boolean { return _isReplay; }
		
		/** @inheritDoc */
		override public function destroy() : void {
			killTimer();
			
			btNext.removeEventListener( MouseEvent.MOUSE_DOWN, onBtNextClicked)
			btNext.destroy();
			btNext = null;
			
			btReplay.removeEventListener( MouseEvent.MOUSE_DOWN, onBtReplayClicked)
			btReplay.destroy();
			btReplay = null;
			
			super.destroy();
		}
		
		/** @inheritDoc */
		override public function start() : void {
			super.start();
			
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
		override protected function buildContent() : void {
			btNext = new MyButton( getBtNextContainer());
			btNext.addEventListener( MouseEvent.MOUSE_DOWN, onBtNextClicked);
			
			btReplay = new MyButton( getBtReplayContainer());
			btReplay.addEventListener( MouseEvent.MOUSE_DOWN, onBtReplayClicked);
		}
		
		/** @inheritDoc */
		override protected function launchAfterInit() : void { launchFadeIn(); }
		
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
			
			MobileDeviceMgr.getInstance().switchLock( false);
		}
		
		/**
		 * on récupère le conteneur du bouton replay
		 * @return	conteneur de bouton
		 */
		protected function getBtReplayContainer() : DisplayObjectContainer { return ( getRotContent() as DisplayObjectContainer).getChildByName( "btReplay") as DisplayObjectContainer; }
		
		/**
		 * on récupère le conteneur du bouton next
		 * @return	conteneur de bouton
		 */
		protected function getBtNextContainer() : DisplayObjectContainer { return ( getRotContent() as DisplayObjectContainer).getChildByName( "btNext") as DisplayObjectContainer; }
		
		/**
		 * on capte le click sur bouton replay
		 * @param	pE	event de click
		 */
		protected function onBtReplayClicked( pE : MouseEvent) : void {
			MySystem.traceDebug( "INFO : ScreenPopGameover::onBtReplayClicked");
			
			_isReplay = true;
		}
		
		/**
		 * on capte le click sur bouton next
		 * @param	pE	event de click
		 */
		protected function onBtNextClicked( pE : MouseEvent) : void { MySystem.traceDebug( "INFO : ScreenPopGameover::onBtNextClicked"); }
	}
}