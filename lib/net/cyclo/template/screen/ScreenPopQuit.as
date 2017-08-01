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
	 * pop up de quit qui demande confirmation (btYes / btNo)
	 * 
	 * @author	nico
	 */
	public class ScreenPopQuit extends MyScreen {
		/** bouton yes */
		protected var btYes							: MyButton								= null;
		/** bouton no */
		protected var btNo							: MyButton								= null;
		/** bouton replay */
		protected var btReplay						: MyButton								= null;
		
		/** flag indiquant si le quit a reçu confirmation (true) ou pas (false) */
		protected var _isQuit						: Boolean								= false;
		/** flag indiquant si on a demandé un replay (true) ou pas (false) */
		protected var _isReplay						: Boolean								= false;
		
		/**
		 * construction
		 */
		public function ScreenPopQuit() {
			super();
			
			ASSET_ID	= "screen_popQuit";
		}
		
		/**
		 * getter sur le flag de validation de quit
		 * @return	true pour valider le quit, false sinon
		 */
		public function get isQuit() : Boolean { return _isQuit; }
		
		/**
		 * getter sur le flag de replay
		 * @return	true si un replay a été demandé, false sinon
		 */
		public function get isReplay() : Boolean { return _isReplay; }
		
		/** @inheritDoc */
		override public function destroy() : void {
			btYes.removeEventListener( MouseEvent.MOUSE_DOWN, onBtYesClicked);
			btYes.destroy();
			btYes = null;
			
			btNo.removeEventListener( MouseEvent.MOUSE_DOWN, onBtNoClicked);
			btNo.destroy();
			btNo = null;
			
			if( btReplay != null){
				btReplay.removeEventListener( MouseEvent.MOUSE_DOWN, onBtReplayClicked);
				btReplay.destroy();
				btReplay = null;
			}
			
			getHitVoidDispatcher().removeEventListener( MouseEvent.MOUSE_DOWN, onBtNoClicked);
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
		 * on capte le click sur yes
		 * @param	pE	event de click
		 */
		protected function onBtYesClicked( pE : MouseEvent) : void {
			MySystem.traceDebug( "INFO : ScreenPopQuit::onBtYesClicked");
			
			_isQuit = true;
		}
		
		/**
		 * on capte le click sur no
		 * @param	pE	event de click
		 */
		protected function onBtNoClicked( pE : MouseEvent) : void { MySystem.traceDebug( "INFO : ScreenPopQuit::onBtNoClicked"); }
		
		/**
		 * on capte le click sur replay
		 * @param	pE	event de click
		 */
		protected function onBtReplayClicked( pE : MouseEvent) : void {
			MySystem.traceDebug( "INFO : ScreenPopQuit::onBtReplayClicked");
			
			_isReplay = true;
		}
		
		/**
		 * on récupère le conteneur du bouton replay
		 * @return	conteneur de bouton
		 */
		protected function getBtReplayContainer() : DisplayObjectContainer { return ( getRotContent() as DisplayObjectContainer).getChildByName( "btReplay") as DisplayObjectContainer; }
		
		/**
		 * on récupère le conteneur du bouton yes
		 * @return	conteneur de bouton
		 */
		protected function getBtYesContainer() : DisplayObjectContainer { return ( getRotContent() as DisplayObjectContainer).getChildByName( "btYes") as DisplayObjectContainer; }
		
		/**
		 * on récupère le dispatcher d'event de click par défaut dans le vide
		 * @return	dispatcher de click par défaut
		 */
		protected function getHitVoidDispatcher() : Sprite { return ( getRotContent() as DisplayObjectContainer).getChildByName( "mcHit") as Sprite; }
		
		/**
		 * on récupère le conteneur du bouton no
		 * @return	conteneur de bouton
		 */
		protected function getBtNoContainer() : DisplayObjectContainer { return ( getRotContent() as DisplayObjectContainer).getChildByName( "btNo") as DisplayObjectContainer; }
		
		/** @inheritDoc */
		override protected function launchAfterInit() : void { launchFadeIn(); }
		
		/** @inheritDoc */
		override protected function buildContent() : void {
			btYes = new MyButton( getBtYesContainer());
			btYes.addEventListener( MouseEvent.MOUSE_DOWN, onBtYesClicked);
			
			btNo = new MyButton( getBtNoContainer());
			btNo.addEventListener( MouseEvent.MOUSE_DOWN, onBtNoClicked);
			
			if( getBtReplayContainer() != null){
				btReplay = new MyButton( getBtReplayContainer());
				btReplay.addEventListener( MouseEvent.MOUSE_DOWN, onBtReplayClicked);
			}
			
			getHitVoidDispatcher().addEventListener( MouseEvent.MOUSE_DOWN, onBtNoClicked);
			getHitVoidDispatcher().buttonMode = true;
		}
	}
}