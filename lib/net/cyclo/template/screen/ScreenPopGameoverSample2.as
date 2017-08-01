package net.cyclo.template.screen {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	import net.cyclo.paddle.AcceleroMultiMode;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.sound.SndMgr;
	import net.cyclo.template.shell.MyShellSample2;
	
	/**
	 * spécialisation sample 2 de pop up game over ; auto orient quand prête
	 * @author nico
	 */
	public class ScreenPopGameoverSample2 extends ScreenPopGameover {
		/** contrpoleur détectant les changements d'orientation ; null si pas actif */
		protected var cont							: AcceleroMultiMode							= null;
		
		/** @inheritDoc */
		public function ScreenPopGameoverSample2() { super(); }
		
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
		override public function start() : void {
			super.start();
			
			cont = new AcceleroMultiMode(
				( shell as MyShellSample2).orientSwitcher,
				-1,
				-1,
				( shell as MyShellSample2).contRefXYZ
			);
			
			cont.switchPause( false);
		}
		
		/**
		 * on récupère une réf vers le contenu haut
		 * @return	clip contenu haut
		 */
		protected function getTopMc() : DisplayObject { return ( getRotContent() as DisplayObjectContainer).getChildByName( "mcTop"); }
		
		/** @inheritDoc */
		override protected function onBtNextClicked( pE : MouseEvent) : void { launchFadeOut(); }
		
		/** @inheritDoc */
		override protected function onBtReplayClicked( pE : MouseEvent) : void {
			super.onBtReplayClicked( pE);
			
			launchFadeOut();
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
	}
}