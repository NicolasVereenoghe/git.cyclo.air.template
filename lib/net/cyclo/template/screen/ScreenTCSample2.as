package net.cyclo.template.screen {
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import net.cyclo.paddle.AcceleroMultiMode;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.sound.SndMgr;
	import net.cyclo.template.shell.MyShellSample2;
	import net.cyclo.template.shell.MyShellSample3;
	/**
	 * écran de sélection de jeu spécialisé sample 2 ; auto orient quand loadé ; sélection d'asset en fonction d'un suffix de tc
	 * 
	 * @author nico
	 */
	public class ScreenTCSample2 extends ScreenTC {
		/** contrpoleur détectant les changements d'orientation ; null si pas actif */
		protected var cont							: AcceleroMultiMode							= null;
		
		/**
		 * construction
		 * @param	pTCSuffix	suffixe de tc, modificateur de nom d'asset
		 */
		public function ScreenTCSample2( pTCSuffix : String) {
			super();
			
			ASSET_ID	+= pTCSuffix;
		}
		
		/** @inheritDoc */
		override public function onBrowseBack( pE : KeyboardEvent) : void {
			if ( shell is MyShellSample3) MobileDeviceMgr.getInstance().exit();
			else launchFadeOut();
		}
		
		/** @inheritDoc */
		override public function switchPause( pIsPause : Boolean) : void {
			super.switchPause( pIsPause);
			
			if ( cont != null) cont.switchPause( pIsPause);
		}
		
		/** @inheritDoc */
		override public function updateRotContent() : void {
			super.updateRotContent();
			
			getTopMc().y = MobileDeviceMgr.getInstance().mobileFullscreenRectRot.top;
		}
		
		/** @inheritDoc */
		override protected function onBackClicked( pE : MouseEvent) : void { launchFadeOut(); }
		
		/** @inheritDoc */
		override protected function onPlayClicked( pE : MouseEvent) : void {
			super.onPlayClicked( pE);
			
			launchFadeOut();
		}
		
		/** @inheritDoc */
		override protected function buildContent() : void {
			super.buildContent();
			
			getLoadingMcTxt().visible = true;
		}
		
		/** @inheritDoc */
		override protected function doFinal() : void {
			super.doFinal();
			
			if( getBtBackContainer() != null) getBtBackContainer().visible = ! ( shell is MyShellSample3);
			
			getLoadingMcTxt().visible = false;
			
			cont = new AcceleroMultiMode(
				( shell as MyShellSample2).orientSwitcher,
				-1,
				-1,
				( shell as MyShellSample2).contRefXYZ
			);
			
			cont.switchPause( false);
		}
		
		/** @inheritDoc */
		override protected function launchFadeOut( pNext : MyScreen = null) : void {
			SndMgr.getInstance().play( MyShellSample2.SND_BUTTON);
			
			if ( cont != null) {
				cont.destroy();
				cont = null;
			}
			
			super.launchFadeOut( pNext);
		}
		
		/**
		 * on récupère une réf vers le contenu haut
		 * @return	clip contenu haut
		 */
		protected function getTopMc() : DisplayObject { return ( getRotContent() as DisplayObjectContainer).getChildByName( "mcTop"); }
		
		/**
		 * on récupère une réf vers l'intitulé de loading
		 * @return	clip représentant l'intitulé de loading
		 */
		protected function getLoadingMcTxt() : DisplayObject { return ( getRotContent() as DisplayObjectContainer).getChildByName( "mcLoading"); }
	}
}