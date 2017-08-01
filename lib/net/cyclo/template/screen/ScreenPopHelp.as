package net.cyclo.template.screen {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.ui.MyButton;
	
	/**
	 * pop up d'aide avec bouton close
	 * 
	 * @author	nico
	 */
	public class ScreenPopHelp extends MyScreen {
		/** bouton close */
		protected var btClose							: MyButton								= null;
		/** bouton replay */
		protected var btReplay							: MyButton								= null;
		
		/** flag indiquant si on a demandé un replay (true) ou pas (false) */
		protected var _isReplay							: Boolean								= false;
		
		/**
		 * construction
		 */
		public function ScreenPopHelp() {
			super();
			
			ASSET_ID	= "screen_popHelp";
		}
		
		/**
		 * getter sur le flag de replay
		 * @return	true si un replay a été demandé, false sinon
		 */
		public function get isReplay() : Boolean { return _isReplay; }
		
		/** @inheritDoc */
		override public function destroy() : void {
			if( btClose != null){
				btClose.removeEventListener( MouseEvent.MOUSE_DOWN, onBtCloseClicked);
				btClose.destroy();
				btClose = null;
			}
			
			if( btReplay != null){
				btReplay.removeEventListener( MouseEvent.MOUSE_DOWN, onBtReplayClicked);
				btReplay.destroy();
				btReplay = null;
			}
			
			getHitVoidDispatcher().removeEventListener( MouseEvent.MOUSE_DOWN, onBtCloseClicked);
			getHitVoidDispatcher().buttonMode = false;
			
			super.destroy();
		}
		
		/** @inheritDoc */
		override public function updateRotContent() : void {
			var lRect	: Rectangle		= MobileDeviceMgr.getInstance().mobileFullscreenRectRot;
			var lBt		: DisplayObject	= getBtReplayContainer();
			
			super.updateRotContent();
			
			if( lBt != null){
				lBt.x	= lRect.left;
				lBt.y	= lRect.bottom;
			}
		}
		
		/**
		 * on capte le click sur close
		 * @param	pE	event de click
		 */
		protected function onBtCloseClicked( pE : MouseEvent) : void { MySystem.traceDebug( "INFO : ScreenPopHelp::onBtCloseClicked"); }
		
		/**
		 * on capte le click sur replay
		 * @param	pE	event de click
		 */
		protected function onBtReplayClicked( pE : MouseEvent) : void {
			MySystem.traceDebug( "INFO : ScreenPopHelp::onBtReplayClicked");
			
			_isReplay = true;
		}
		
		/**
		 * on récupère le conteneur du bouton replay
		 * @return	conteneur de bouton
		 */
		protected function getBtReplayContainer() : DisplayObjectContainer { return ( getRotContent() as DisplayObjectContainer).getChildByName( "btReplay") as DisplayObjectContainer; }
		
		/**
		 * on récupère le conteneur du bouton close
		 * @return	conteneur de bouton
		 */
		protected function getBtCloseContainer() : DisplayObjectContainer { return ( getRotContent() as DisplayObjectContainer).getChildByName( "btClose") as DisplayObjectContainer; }
		
		/**
		 * on récupère le dispatcher d'event de click par défaut dans le vide
		 * @return	dispatcher de click par défaut
		 */
		protected function getHitVoidDispatcher() : Sprite { return ( getRotContent() as DisplayObjectContainer).getChildByName( "mcHit") as Sprite; }
		
		/** @inheritDoc */
		override protected function launchAfterInit() : void { launchFadeIn(); }
		
		/** @inheritDoc */
		override protected function buildContent() : void {
			if( getBtCloseContainer() != null){
				btClose = new MyButton( getBtCloseContainer());
				btClose.addEventListener( MouseEvent.MOUSE_DOWN, onBtCloseClicked);
			}
			
			if( getBtReplayContainer() != null){
				btReplay = new MyButton( getBtReplayContainer());
				btReplay.addEventListener( MouseEvent.MOUSE_DOWN, onBtReplayClicked);
			}
			
			getHitVoidDispatcher().addEventListener( MouseEvent.MOUSE_DOWN, onBtCloseClicked);
			getHitVoidDispatcher().buttonMode = true;
		}
	}
}