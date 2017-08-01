package net.cyclo.template.screen {
	
	/**
	 * fade utilisé pour regénérer le jeu en cours (replay)
	 * 
	 * @author nico
	 */
	public class ScreenReplayFade extends MyScreen {
		/**
		 * construction
		 */
		public function ScreenReplayFade() {
			super();
			
			FADE_RGB_USE	= true;
			BG_RGB_USE		= true;
		}
		
		/** @inheritDoc */
		override protected function launchAfterInit() : void { super.launchFadeIn(); }
	}
}