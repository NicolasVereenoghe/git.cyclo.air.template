package net.cyclo.template.screen {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.ui.MyButton;
	import net.cyclo.ui.VScroll;
	
	/**
	 * écran de sélection de jeu
	 * contient un bouton retour btBack et un ascenseur de rubriques mcScroll
	 * 
	 * @author nico
	 */
	public class ScreenSelect extends MyScreen {
		/** bouton start */
		protected var btBack									: MyButton										= null;
		
		/** ascenseur de sélection */
		protected var vScroll									: VScroll										= null;
		
		/** itérateur de frame */
		protected var framer									: MovieClip										= null;
		/** flag indiquant si on est en pause (true) ou pas (false) */
		protected var isPause									: Boolean										= false;
		
		/** index d'item sélectionné ( 0 .. n-1) ; -1 si aucun de sélectionné */
		protected var _selectedIndex							: int											= -1;
		
		/**
		 * getter d'index sélectionné
		 * @return	index ( 0 .. n-1) ou -1 si aucune sélection
		 */
		public function get selectedIndex() : int { return _selectedIndex; }
		
		/**
		 * construction
		 */
		public function ScreenSelect() {
			super();
			
			ASSET_ID		= "screen_select";
			FADE_RGB_USE	= true;
			BG_RGB_USE		= true;
		}
		
		/** @inheritDoc */
		override public function start() : void {
			framer			= new MovieClip();
			framer.addEventListener( Event.ENTER_FRAME, onEnterFrame);
		}
		
		/** @inheritDoc */
		override public function destroy() : void {
			btBack.removeEventListener( MouseEvent.MOUSE_DOWN, onBackClicked);
			btBack.destroy();
			btBack = null;
			
			vScroll.destroy();
			vScroll = null;
			
			if ( framer != null) {
				framer.removeEventListener( Event.ENTER_FRAME, onEnterFrame);
				framer = null;
			}
			
			super.destroy();
		}
		
		/** @inheritDoc */
		override public function switchPause( pIsPause : Boolean) : void {
			super.switchPause( pIsPause);
			
			isPause = pIsPause;
			
			vScroll.switchPause( pIsPause);
		}
		
		/** @inheritDoc */
		override public function updateRotContent() : void {
			var lRect	: Rectangle		= MobileDeviceMgr.getInstance().mobileFullscreenRectRot;
			var lBt		: DisplayObject	= getBtBackContainer();
			
			super.updateRotContent();
			
			lBt.x	= lRect.left;
			lBt.y	= lRect.top;
			
			getVScrollContainer().y = MobileDeviceMgr.getInstance().mobileFullscreenRectRot.top;
			
			vScroll.updateDScrollY( lRect.height);
		}
		
		/**
		 * on instancie un ascenseur de rubriques
		 * @return	instance d'ascenseur de rubriques à utiliser pour la liste des jeux de la sélection
		 */
		protected function instanciateVScroll() : VScroll { return new VScroll(); }
		
		/**
		 * on récupère une réf vers le copnteneur de graphisme du bouton start
		 * @return	conteneur graphique de bouton start
		 */
		protected function getBtBackContainer() : DisplayObjectContainer { return ( getRotContent() as DisplayObjectContainer).getChildByName( "btBack") as DisplayObjectContainer; }
		
		/**
		 * on récupère une réf sur le conteneur de scroll
		 * @return	conteneur de scroll
		 */
		protected function getVScrollContainer() : DisplayObjectContainer { return ( getRotContent() as DisplayObjectContainer).getChildByName( "mcScroll") as DisplayObjectContainer; }
		
		/**
		 * on capte le click sur le bouton start
		 * @param	pE	event de souris
		 */
		protected function onBackClicked( pE : MouseEvent) : void { MySystem.traceDebug( "INFO : ScreenSelect::onBackClicked"); }
		
		/**
		 * on capte l'itération de frame : on itère le vscroll
		 * @param	pE	event d'itération de frame
		 */
		protected function onEnterFrame( pE : Event) : void {
			if ( ! isPause) {
				_selectedIndex = vScroll.selectedGameIndex;
				
				vScroll.doFrame();
			}
		}
		
		/** @inheritDoc */
		override protected function buildContent() : void {
			btBack = new MyButton( getBtBackContainer());
			btBack.addEventListener( MouseEvent.MOUSE_DOWN, onBackClicked);
			
			vScroll	= instanciateVScroll();
			vScroll.init( getVScrollContainer(), MobileDeviceMgr.getInstance().mobileFullscreenRectRot.height);
		}
		
		/** @inheritDoc */
		override protected function launchAfterInit() : void { launchFadeIn(); }
		
		/** @inheritDoc */
		override protected function launchFadeOut( pNext : MyScreen = null) : void {
			if ( framer != null) {
				framer.removeEventListener( Event.ENTER_FRAME, onEnterFrame);
				framer = null;
			}
			
			super.launchFadeOut( pNext);
		}
	}
}