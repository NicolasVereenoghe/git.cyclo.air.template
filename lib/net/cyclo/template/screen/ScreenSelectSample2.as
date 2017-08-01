package net.cyclo.template.screen {
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import net.cyclo.paddle.AcceleroMultiMode;
	import net.cyclo.sound.SndMgr;
	import net.cyclo.template.shell.MyShellSample2;
	
	/**
	 * écran de sélection de jeu spécialisé sample 2 : gère l'auto orient
	 * 
	 * @author nico
	 */
	public class ScreenSelectSample2 extends ScreenSelect {
		/** controleur détectant les changements d'orientation ; null si pas actif */
		protected var cont							: AcceleroMultiMode							= null;
		
		/** @inheritDoc */
		public function ScreenSelectSample2() { super(); }
		
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
			
			super.start();
		}
		
		/** @inheritDoc */
		override protected function onEnterFrame( pE : Event) : void {
			super.onEnterFrame( pE);
			
			if ( ! isPause && _selectedIndex != -1) launchFadeOut();
		}
		
		/** @inheritDoc */
		override protected function onBackClicked( pE : MouseEvent) : void { launchFadeOut(); }
		
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