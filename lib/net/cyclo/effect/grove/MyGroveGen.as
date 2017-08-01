package net.cyclo.effect.grove {
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import net.cyclo.bitmap.MovieClipTemplate4Gen;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * pré-générateur de fractal bosquet fleuri ; on utilise en motif un fractal fleuri qui est censé déjà avoir été pré-généré
	 * 
	 * @author	nico
	 */
	public class MyGroveGen extends MovieClipTemplate4Gen {
		/** nombre de frames de rendu du fractal bosquet */
		protected var GROVE_TRANS_DELAY					: int										= 60;
		
		/** identifiant d'asset de fractal fleuri, servant de motif au fractal étoilé */
		protected var FLOWER_ASSET_ID					: String									= "flower";
		
		/** rayon du motif du fractal bosquet */
		protected var STAR_RAY							: Number									= 18;// 20;//30;//37.5;
		/** nombre de branches du fractal bosquet */
		protected var STAR_NB_BRANCH					: int										= 7;// 7;
		/** récursion max de motifs du fractal bosquet */
		protected var STAR_RECUR_MAX					: int										= 3;
		/** taux d'écrasement des motifs quand on passe d'un niveau de récursion à l'autre [ 0..1] */
		protected var STAR_SHRINK_RATE					: Number									= 0;
		/** taux de disparité quand on s'éloigne de l'axe directeur d'une branche de motifs */
		protected var STAR_DISPARITY_RATE				: Number									= 0;//.5;// 0;
		/** écart d'angle max de rendu de motifs autour de l'axe directeur d'une branche de motifs, en deg */
		protected var STAR_MAX_A						: Number									= 108;// 129;
		
		/** scale global appliqué au rendu de bosquet */
		protected var GLOBAL_SCALE						: Number									= 1.5;
		
		/** conteneur du rendu de bosquet */
		protected var groveCont							: DisplayObjectContainer					= null;
		/** le calculateur de rendu de bosquet */
		protected var grove								: MyGroveMgr								= null;
		
		/** frame de rendu courrante (1..n) */
		protected var groveCtr							: int										= 1;
		
		/**
		 * initialisation : on effectue le rendu de frame 1
		 */
		public function init() : void {
			groveCont = addChild( new Sprite()) as DisplayObjectContainer;
			grove = groveCont.addChild( new MyGroveMgr( STAR_MAX_A)) as MyGroveMgr;
			
			groveCont.scaleX = groveCont.scaleY = GLOBAL_SCALE;
			
			grove.init(
				STAR_RAY,
				STAR_SHRINK_RATE,
				0,
				STAR_DISPARITY_RATE,
				STAR_NB_BRANCH,
				FLOWER_ASSET_ID,
				-1,
				-1,
				-1,
				STAR_RECUR_MAX
			);
		}
		
		/** @inheritDoc */
		override public function destroy( pE : Event = null) : void {
			grove.destroy();
			UtilsMovieClip.clearFromParent( grove);
			grove = null;
			
			UtilsMovieClip.clearFromParent( groveCont);
			groveCont = null;
			
			super.destroy( pE);
		}
		
		/** @inheritDoc */
		override public function gotoAndStop( frame : Object, scene : String = null) : void {
			var lFrame	: int		= frame as int;
			var lRate	: Number;
			
			if ( groveCtr != lFrame) {
				groveCtr	= lFrame;
				lRate		= ( lFrame - 1) / ( GROVE_TRANS_DELAY - 1);
				
				grove.doRender(
					STAR_SHRINK_RATE,
					lRate,
					STAR_DISPARITY_RATE,
					STAR_NB_BRANCH
				);
			}
		}
		
		/** @inheritDoc */
		override public function get currentFrame() : int { return groveCtr; }
		
		/** @inheritDoc */
		override public function get totalFrames() : int { return GROVE_TRANS_DELAY; }
	}
}