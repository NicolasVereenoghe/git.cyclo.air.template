package net.cyclo.template.game.hud {
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.template.shell.IGameShell;
	import net.cyclo.ui.MyButton;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * avec boutons home et help (btHome / htHelp) callés automatiquement suivant l'orientation en TL et TR
	 * 
	 * @author	nico
	 */
	public class MyHUD extends Sprite implements IMyHUD {
		/** nom d'asset du HUD */
		protected var ASSET_ID								: String									= "nav_hud";
		
		/** le shell qui gère le jeu dont on pilote le HUD */
		protected var shell									: IGameShell								= null;
		
		/** conteneur de rotation ; on le tourne si il y a changement d'orientation */
		protected var asset									: AssetInstance								= null;
		
		/** bouton home */
		protected var homeBt								: MyButton									= null;
		/** bouton help */
		protected var helpBt								: MyButton									= null;
		
		/** @inheritDoc */
		public function init( pShell : IGameShell, pContainer : DisplayObjectContainer, pType : String) : void {
			var lRect	: Rectangle	= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			
			pContainer.addChild( this);
			
			asset	= addChild( AssetsMgr.getInstance().getAssetInstance( ASSET_ID)) as AssetInstance;
			asset.x	= ( lRect.left + lRect.right) / 2;
			asset.y	= ( lRect.top + lRect.bottom) / 2;
			
			shell	= pShell;
			
			initContent();
			
			updateRotContent();
		}
		
		/**
		 * initialisation du contenu du hud
		 */
		protected function initContent() : void {
			homeBt	= new MyButton( getBtHomeContainer());
			helpBt	= new MyButton( getBtHelpContainer());
			
			homeBt.addEventListener( MouseEvent.MOUSE_DOWN, onHomeClicked);
			helpBt.addEventListener( MouseEvent.MOUSE_DOWN, onHelpClicked);
		}
		
		/** @inheritDoc */
		public function destroy() : void {
			homeBt.removeEventListener( MouseEvent.MOUSE_DOWN, onHomeClicked);
			helpBt.removeEventListener( MouseEvent.MOUSE_DOWN, onHelpClicked);
			
			homeBt.destroy();
			helpBt.destroy();
			
			homeBt	= null;
			helpBt	= null;
			
			UtilsMovieClip.clearFromParent( asset);
			asset.free();
			asset = null;
			
			UtilsMovieClip.clearFromParent( this);
			
			shell = null;
		}
		
		/** @inheritDoc */
		public function switchPause( pPause : Boolean) : void { }
		
		/** @inheritDoc */
		public function updateRotContent() : void {
			var lRect	: Rectangle	= MobileDeviceMgr.getInstance().mobileFullscreenRectRot;
			
			asset.rotation			= MobileDeviceMgr.getInstance().rotContent;
			
			getBtHomeContainer().x	= lRect.left;
			getBtHomeContainer().y	= lRect.top;
			
			getBtHelpContainer().x	= lRect.right;
			getBtHelpContainer().y	= lRect.top;
		}
		
		/**
		 * on capte le click sur bouton home
		 * @param	pE	event de click
		 */
		protected function onHomeClicked( pE : MouseEvent) : void { MySystem.traceDebug( "INFO : MyHUD::onHomeClicked"); }
		
		/**
		 * on capte le click sur bouton help
		 * @param	pE	event de click
		 */
		protected function onHelpClicked( pE : MouseEvent) : void { MySystem.traceDebug( "INFO : MyHUD::onHelpClicked"); }
		
		/**
		 * on récupère le conteneur du bouton home
		 * @return	clip conteneur de bouton
		 */
		protected function getBtHomeContainer() : DisplayObjectContainer { return ( asset.content as DisplayObjectContainer).getChildByName( "btHome") as DisplayObjectContainer; }
		
		/**
		 * on récupère le conteneur du bouton help
		 * @return	clip conteneur de bouton
		 */
		protected function getBtHelpContainer() : DisplayObjectContainer { return ( asset.content as DisplayObjectContainer).getChildByName( "btHelp") as DisplayObjectContainer; }
	}
}