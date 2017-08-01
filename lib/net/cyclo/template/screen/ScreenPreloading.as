package net.cyclo.template.screen {
	
	/**
	 * classe mère d'écran de preloading
	 * 
	 * @author	nico
	 */
	public class ScreenPreloading extends ScreenLoading {
		/** @inheritDoc */
		override protected function launchAfterInit() : void { launchFadeIn(); }
		
		/** @inheritDoc */
		override protected function doFinal() : void {
			super.doFinal();
			
			launchFadeOut();
		}
	}
}