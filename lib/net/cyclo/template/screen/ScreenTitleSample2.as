package net.cyclo.template.screen {
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import net.cyclo.paddle.AcceleroMultiMode;
	import net.cyclo.sound.SndMgr;
	import net.cyclo.template.shell.MyShellSample2;
	
	/**
	 * écran titre spécialisé du sample 2 : gère l'auto orientation
	 * 
	 * @author nico
	 */
	public class ScreenTitleSample2 extends ScreenTitle {
		/** contrpoleur détectant les changements d'orientation ; null si pas actif */
		protected var cont							: AcceleroMultiMode							= null;
		
		/** @inheritDoc */
		public function ScreenTitleSample2() { super(); }
		
		/** @inheritDoc */
		override public function onBrowseBack( pE : KeyboardEvent) : void { launchFadeOut(); }
		
		/** @inheritDoc */
		override public function switchPause( pIsPause : Boolean) : void {
			super.switchPause( pIsPause);
			
			if ( cont != null) cont.switchPause( pIsPause);
		}
		
		/** @inheritDoc */
		override public function start() : void {
			cont = new AcceleroMultiMode(
				( shell as MyShellSample2).orientSwitcher,
				-1,
				-1,
				( shell as MyShellSample2).contRefXYZ
			);
			
			cont.switchPause( false);
		}
		
		/** @inheritDoc */
		override protected function onStartClicked( pE : MouseEvent) : void {
			SndMgr.getInstance().play( MyShellSample2.SND_BUTTON);
			
			launchFadeOut();
		}
		
		/** @inheritDoc */
		override protected function launchFadeOut( pNext : MyScreen = null) : void {
			if ( cont != null) {
				cont.destroy();
				cont = null;
			}
			
			super.launchFadeOut( pNext);
		}
	}
}