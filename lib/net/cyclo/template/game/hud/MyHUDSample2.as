package net.cyclo.template.game.hud {
	import flash.events.MouseEvent;
	import net.cyclo.sound.SndMgr;
	import net.cyclo.template.shell.MyShellSample2;
	
	/**
	 * HUD spécialisé sample 2 pour répondre au shell
	 * 
	 * @author nico
	 */
	public class MyHUDSample2 extends MyHUD {
		/** @inheritDoc */
		override protected function onHomeClicked( pE : MouseEvent) : void {
			SndMgr.getInstance().play( MyShellSample2.SND_BUTTON);
			
			shell.onGameAborted();
		}
		
		/** @inheritDoc */
		override protected function onHelpClicked( pE : MouseEvent) : void {
			SndMgr.getInstance().play( MyShellSample2.SND_BUTTON);
			
			( shell as MyShellSample2).askPopHelp();
		}
	}
}