package net.cyclo.effect.grove {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.system.ApplicationDomain;
	import net.cyclo.effect.MyFractalRing;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * un anneau de pétales d'un fractal en spiral d'une fleur en bosquet
	 * 
	 * @author nico
	 */
	public class MyGroveFlowerFractalRing extends MyFractalRing {
		/**
		 * on capture le scaleX pour piloter une interpolation sur les timelines des motifs de pétales
		 * @inheritDoc
		 */
		override public function set scaleX( pVal : Number) : void {
			var lRate	: Number	= 1 - Math.max( Math.min( ( relativeStep - mgr.firstStep) / mgr.nbSteps, 1), 0);
			var lMC		: MovieClip;
			var lI		: int;
			
			super.scaleX = pVal;
			
			for ( lI = 0 ; lI < numChildren ; lI++) {
				lMC = ( ( getChildAt( lI) as DisplayObjectContainer).getChildAt( 0)) as MovieClip;
				
				lMC.gotoAndStop( 1 + Math.round( ( lMC.totalFrames - 1) * lRate));
			}
		}
		
		/** @inheritDoc */
		override protected function clearMotif() : void {
			var lCont	: DisplayObjectContainer	= ( getChildAt( 0) as DisplayObjectContainer);
			var lAsset	: DisplayObject				= lCont.getChildAt( 0);
			
			UtilsMovieClip.clearFromParent( lAsset);
			
			UtilsMovieClip.clearFromParent( lCont);
		}
		
		/** @inheritDoc */
		override protected function instanciateMotif( pId : String) : DisplayObject {
			var lMotif	: MovieClip	= new ( ApplicationDomain.currentDomain.getDefinition( pId) as Class)();
			var lRate	: Number	= 1 - Math.max( Math.min( ( relativeStep - mgr.firstStep) / mgr.nbSteps, 1), 0);
			
			lMotif.gotoAndStop( 1 + Math.round( ( lMotif.totalFrames - 1) * lRate));
			
			return lMotif;
		}
	}
}