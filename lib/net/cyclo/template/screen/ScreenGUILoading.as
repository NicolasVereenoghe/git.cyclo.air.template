package net.cyclo.template.screen {
	
	/**
	 * classe mère d'écran de loading de GUI
	 * 
	 * @author	nico
	 */
	public class ScreenGUILoading extends ScreenLoading {
		/** @inheritDoc */
		override protected function launchAfterInit() : void { launchFadeIn(); }
		
		/** @inheritDoc */
		override protected function doFinal() : void {
			super.doFinal();
			
			launchFadeOut();
		}
	}
}