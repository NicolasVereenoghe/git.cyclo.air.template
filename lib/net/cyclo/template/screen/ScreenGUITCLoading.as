package net.cyclo.template.screen {
	
	/**
	 * classe mère d'écran de loading de GUI + TC, on quitte le jeu pour revenir au GUI + TC
	 * 
	 * @author	nico
	 */
	public class ScreenGUITCLoading extends ScreenLoading {
		/** @inheritDoc */
		override protected function launchAfterInit() : void { launchFadeIn(); }
		
		/** @inheritDoc */
		override protected function doFinal() : void {
			super.doFinal();
			
			launchFadeOut();
		}
	}
}