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
	 * title card de jeu ; on effectue le loading du jeu, puis un bouton play invite à entrer dedans, ou bt back pour revenir à l'écran d'avant
	 * 
	 * @author nico
	 */
	public class ScreenTC extends ScreenLoading {
		/** bouton start */
		protected var btBack									: MyButton										= null;
		
		/** bouton play */
		protected var btPlay									: MyButton										= null;
		
		/** flag indiquant si le bouton play a été appuyé */
		protected var _isPlay									: Boolean										= false;
		
		/**
		 * getter sur le flag _isPlay
		 * @return	true si le bouton play a été appuyé, false sinon
		 */
		public function get isPlay() : Boolean { return _isPlay; }
		
		/** @inheritDoc */
		public function ScreenTC() {
			super();
			
			ASSET_ID		= "screen_tc";
		}
		
		/** @inheritDoc */
		override public function destroy() : void {
			if( btBack != null){
				btBack.removeEventListener( MouseEvent.MOUSE_DOWN, onBackClicked);
				btBack.destroy();
				btBack = null;
			}
			
			btPlay.removeEventListener( MouseEvent.MOUSE_DOWN, onPlayClicked);
			btPlay.destroy();
			btPlay = null;
			
			getHitVoidDispatcher().removeEventListener( MouseEvent.MOUSE_DOWN, onPlayClicked);
			getHitVoidDispatcher().buttonMode = false;
			
			super.destroy();
		}
		
		/** @inheritDoc */
		override public function updateRotContent() : void {
			var lRect	: Rectangle		= MobileDeviceMgr.getInstance().mobileFullscreenRectRot;
			var lBt		: DisplayObject	= getBtBackContainer();
			
			super.updateRotContent();
			
			if( lBt != null){
				lBt.x	= lRect.left;
				lBt.y	= lRect.top;
			}
		}
		
		/**
		 * on capte le click sur le bouton back
		 * @param	pE	event de souris
		 */
		protected function onBackClicked( pE : MouseEvent) : void { MySystem.traceDebug( "INFO : ScreenTC::onBackClicked"); }
		
		/**
		 * on capte le click sur le bouton play
		 * @param	pE	event de souris
		 */
		protected function onPlayClicked( pE : MouseEvent) : void {
			MySystem.traceDebug( "INFO : ScreenTC::onPlayClicked");
			
			_isPlay = true;
		}
		
		/**
		 * on récupère une réf vers le conteneur de graphisme du bouton start
		 * @return	conteneur graphique de bouton start
		 */
		protected function getBtBackContainer() : DisplayObjectContainer { return ( getRotContent() as DisplayObjectContainer).getChildByName( "btBack") as DisplayObjectContainer; }
		
		/**
		 * on récupère une réf vers le conteneur du bouton play
		 * @return	conteneur bouton play
		 */
		protected function getBtPlayContainer() : DisplayObjectContainer { return ( getRotContent() as DisplayObjectContainer).getChildByName( "btPlay") as DisplayObjectContainer; }
		
		/**
		 * on récupère le dispatcher d'event de click par défaut dans le vide
		 * @return	dispatcher de click par défaut
		 */
		protected function getHitVoidDispatcher() : Sprite { return ( getRotContent() as DisplayObjectContainer).getChildByName( "mcHit") as Sprite; }
		
		/** @inheritDoc */
		override protected function buildContent() : void {
			super.buildContent();
			
			if( getBtBackContainer() != null){
				btBack = new MyButton( getBtBackContainer());
				btBack.addEventListener( MouseEvent.MOUSE_DOWN, onBackClicked);
				getBtBackContainer().visible = false;
			}
			
			btPlay = new MyButton( getBtPlayContainer());
			btPlay.addEventListener( MouseEvent.MOUSE_DOWN, onPlayClicked);
			
			getHitVoidDispatcher().addEventListener( MouseEvent.MOUSE_DOWN, onPlayClicked);
			getHitVoidDispatcher().buttonMode = true;
			
			getBtPlayContainer().visible = false;
			getHitVoidDispatcher().visible = false;
		}
		
		/** @inheritDoc */
		override protected function launchAfterInit() : void { launchFadeIn(); }
		
		/** @inheritDoc */
		override protected function doFinal() : void {
			super.doFinal();
			
			if( getBtBackContainer() != null) getBtBackContainer().visible = true;
			getBtPlayContainer().visible = true;
			getHitVoidDispatcher().visible = true;
		}
	}
}