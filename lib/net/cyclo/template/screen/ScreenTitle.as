package net.cyclo.template.screen {
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import net.cyclo.shell.MySystem;
	import net.cyclo.ui.MyButton;
	
	/**
	 * écran titre du jeu ; bouton start
	 * @author nico
	 */
	public class ScreenTitle extends MyScreen {
		/** bouton start */
		protected var btStart									: MyButton										= null;
		
		/**
		 * construction
		 */
		public function ScreenTitle() {
			super();
			
			ASSET_ID		= "screen_title";
			FADE_RGB_USE	= true;
			BG_RGB_USE		= true;
		}
		
		/** @inheritDoc */
		override public function destroy() : void {
			btStart.removeEventListener( MouseEvent.MOUSE_DOWN, onStartClicked);
			btStart.destroy();
			btStart = null;
			
			getHitVoidDispatcher().removeEventListener( MouseEvent.MOUSE_DOWN, onStartClicked);
			getHitVoidDispatcher().buttonMode = false;
			
			super.destroy();
		}
		
		/**
		 * on récupère une réf vers le copnteneur de graphisme du bouton start
		 * @return	conteneur graphique de bouton start
		 */
		protected function getBtStartContainer() : DisplayObjectContainer { return ( getRotContent() as DisplayObjectContainer).getChildByName( "btStart") as DisplayObjectContainer; }
		
		/**
		 * on récupère le dispatcher d'event de click par défaut dans le vide
		 * @return	dispatcher de click par défaut
		 */
		protected function getHitVoidDispatcher() : Sprite { return ( getRotContent() as DisplayObjectContainer).getChildByName( "mcHit") as Sprite; }
		
		/**
		 * on capte le click sur le bouton start
		 * @param	pE	event de souris
		 */
		protected function onStartClicked( pE : MouseEvent) : void { MySystem.traceDebug( "INFO : ScreenTitle::onStartClicked"); }
		
		/** @inheritDoc */
		override protected function launchAfterInit() : void { launchFadeIn(); }
		
		/** @inheritDoc */
		override protected function buildContent() : void {
			btStart = new MyButton( getBtStartContainer());
			btStart.addEventListener( MouseEvent.MOUSE_DOWN, onStartClicked);
			
			getHitVoidDispatcher().addEventListener( MouseEvent.MOUSE_DOWN, onStartClicked);
			getHitVoidDispatcher().buttonMode = true;
		}
	}
}