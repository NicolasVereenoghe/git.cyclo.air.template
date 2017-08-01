package net.cyclo.effect.grove {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.system.ApplicationDomain;
	import net.cyclo.bitmap.MovieClipTemplate4Gen;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * pré-générateur de fractal fleuri
	 * 
	 * @author	nico
	 */
	public class MyFlowerGen extends MovieClipTemplate4Gen {
		/** scale global appliqué au rendu de fleur généré */
		protected var FLOWER_SCALE						: Number									= 1;
		
		/** identifiant de liaison de modèle de fleur (bg et mcFlower conteneur du fractal fleuri) */
		protected var FLOWER_MODEL_ID					: String									= "flower_model";
		/** identifiant de liaison de pétal de fleur (avec une interpo de couleur) */
		protected var FLOWER_MOTIF_ID					: String									= "flower_motif";
		/** nombre de motifs pétal par anneau de fractal */
		protected var FLOWER_NB_MOTIF					: int										= 4;
		/** côté du motif pétal */
		protected var FLOWER_MOTIF_SIDE					: Number									= 30;
		/** distance en dessous de laquelle on ignore le rendu fractal du motif pétal */
		protected var FLOWER_MIN_DIST					: Number									= .1;
		
		/** angle d'ouverture du motif pétal quand la fleur est fermée, en rad */
		protected var FLOWER_A_CLOSED					: Number									= 5 * Math.PI / 12;
		/** distance max des motifs pétal par rapport au centre du fractal, quand la fleur est fermée */
		protected var FLOWER_MAX_DIST_CLOSED			: Number									= 1;
		/** étape de rendu fractal spiral pour la fleur fermée */
		protected var FLOWER_STEP_CLOSED				: Number									= 1.03;
		/** orientation du fractal fleuri quand la fleur est fermée, en deg */
		protected var FLOWER_ROTATION_CLOSED			: Number									= 0;
		/** scale appliqué au rendu fractal spiral quand la fleur est fermée */
		protected var FLOWER_SCALE_CLOSED				: Number									= 2;
		
		/** angle d'ouverture du motif pétal quand la fleur est ouverte, en rad */
		protected var FLOWER_A_OPEN						: Number									= 2 * Math.PI / 9;
		/** distance max des motifs pétal par rapport au centre du fractal, quand la fleur est ouverte */
		protected var FLOWER_MAX_DIST_OPEN				: Number									= 15;
		/** étape de rendu fractal spiral pour la fleur ouverte */
		protected var FLOWER_STEP_OPEN					: Number									= .66;
		/** orientation du fractal fleuri quand la fleur est ouverte, en deg */
		protected var FLOWER_ROTATION_OPEN				: Number									= 45;
		/** scale appliqué au rendu fractal spiral quand la fleur est ouverte */
		protected var FLOWER_SCALE_OPEN					: Number									= 1.25;
		
		/** nombre de frames de rendu du fractal fleuri */
		protected var FLOWER_TRANS_DELAY				: int										= 20;
		
		/** fleur verrouillée à son motif max lors de l'init (true) ou libre (false) */
		protected var FLOWER_LOCKED						: Boolean									= false;
		
		/** calculateur de rendu de fractal fleuri */
		protected var flower							: MyGroveFlowerFractal						= null;
		/** le modèle de la fleur (bg et mcFlower conteneur du fractal fleuri) */
		protected var model								: DisplayObjectContainer					= null;
		
		/** frame de rendu courrante (1..n) */
		protected var flowerCtr							: int										= 1;
		
		/**
		 * initialisation : on effectue le rendu de frame 1
		 */
		public function init() : void {
			model		= addChild( new ( ApplicationDomain.currentDomain.getDefinition( FLOWER_MODEL_ID) as Class)()) as DisplayObjectContainer;
			flower		= getFlowerContainer().addChild( new MyGroveFlowerFractal()) as MyGroveFlowerFractal;
			
			model.scaleX = model.scaleY = FLOWER_SCALE;
			flower.scaleX = flower.scaleY = FLOWER_SCALE_CLOSED;
			flower.rotation = FLOWER_ROTATION_CLOSED;
			
			flower.init(
				FLOWER_A_CLOSED,
				FLOWER_NB_MOTIF,
				true,
				FLOWER_MIN_DIST,
				FLOWER_MAX_DIST_CLOSED,
				FLOWER_MOTIF_ID,
				null,
				0,
				FLOWER_MOTIF_SIDE,
				0,
				0,
				0,
				FLOWER_STEP_CLOSED,
				false,
				true,
				FLOWER_LOCKED
			);
		}
		
		/** @inheritDoc */
		override public function destroy( pE : Event = null) : void {
			flower.destroy();
			UtilsMovieClip.clearFromParent( flower);
			flower = null;
			
			UtilsMovieClip.clearFromParent( model);
			model = null;
			
			super.destroy( pE);
		}
		
		/**
		 * on récupère le conteneur de fractal fleuri dans le modèle de fleur
		 * @return	conteneur de fractal fleuri
		 */
		protected function getFlowerContainer() : DisplayObjectContainer { return model.getChildByName( "mcFlower") as DisplayObjectContainer; }
		
		/** @inheritDoc */
		override public function gotoAndStop( frame : Object, scene : String = null) : void {
			var lFrame	: int			= frame as int;
			var lRate	: Number;
			
			if ( flowerCtr != lFrame) {
				flowerCtr		= lFrame;
				lRate			= ( lFrame - 1) / ( FLOWER_TRANS_DELAY - 1);
				flower.scaleX	= flower.scaleY = FLOWER_SCALE_CLOSED + ( FLOWER_SCALE_OPEN - FLOWER_SCALE_CLOSED) * lRate;
				flower.rotation = FLOWER_ROTATION_CLOSED + ( FLOWER_ROTATION_OPEN - FLOWER_ROTATION_CLOSED) * lRate;
				
				flower.doFrame(
					FLOWER_STEP_CLOSED + ( FLOWER_STEP_OPEN - FLOWER_STEP_CLOSED) * lRate,
					FLOWER_A_CLOSED + ( FLOWER_A_OPEN - FLOWER_A_CLOSED) * lRate,
					true,
					FLOWER_MAX_DIST_CLOSED + ( FLOWER_MAX_DIST_OPEN - FLOWER_MAX_DIST_CLOSED) * lRate
				);
			}
		}
		
		/** @inheritDoc */
		override public function get currentFrame() : int { return flowerCtr; }
		
		/** @inheritDoc */
		override public function get totalFrames() : int { return FLOWER_TRANS_DELAY; }
	}
}