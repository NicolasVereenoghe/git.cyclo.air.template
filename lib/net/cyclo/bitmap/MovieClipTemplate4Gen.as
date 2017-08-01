package net.cyclo.bitmap {
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * modèle de fake movie clip pour générer une animation bmp, avec les méthodes significatives surchargées
	 * à dériver suivant les besoins, en suivant le principe de movie clip (pilotage de frame) pour effectuer l'ordre des rendus
	 * 
	 * @author nico
	 */
	public class MovieClipTemplate4Gen extends MovieClip {
		/** réf sur cadre bitmap généré par le fake mc ; null si pas défini dans le contexte du fake mc */
		protected var cadreMc							: Sprite									= null;
		
		/**
		 * libération mémoire du fake movie clip
		 * @param	pE	event qui déclanche la destruction, null pour ignorer ; attention, de base rien ne déclanche la destruction, on donne un moyen si on veut le faire
		 */
		public function destroy( pE : Event = null) : void {
			MySystem.traceDebug( "INFO : MovieClipTemplate4Gen::destroy");
			
			if( cadreMc != null){
				cadreMc.graphics.clear();
				UtilsMovieClip.clearFromParent( cadreMc);
				cadreMc = null;
			}
		}
		
		/** @inheritDoc */
		override public function get totalFrames() : int {
			MySystem.traceDebug( "INFO : MovieClipTemplate4Gen::totalFrames : 1");
			
			return 1;
		}
		
		/** @inheritDoc */
		override public function get currentFrame() : int {
			MySystem.traceDebug( "INFO : MovieClipTemplate4Gen::currentFrame : 1");
			
			return 1;
		}
		
		/** @inheritDoc */
		override public function gotoAndStop( frame : Object, scene : String = null) : void {
			MySystem.traceDebug( "INFO : MovieClipTemplate4Gen::gotoAndStop : " + frame);
		}
		
		/**
		 * donne les dimensions du cadre bitmap de l'anim générée ; pour simplifier on n'en fait qu'un cadre
		 * @param	rectangle du cadre bitmap ; null si non défini
		 */
		protected function getCadreRect() : Rectangle {
			MySystem.traceDebug( "INFO : MovieClipTemplate4Gen::getCadreRect : null");
			
			return null;
		}
		
		/**
		 * construction du cadre bitmap : penser à l'appeler après la contruction du fils de ce modèle
		 */
		protected function buildCadre() : void {
			var lRect	: Rectangle;
			var lSp		: Sprite;
			
			lRect = getCadreRect();
			if ( lRect != null) {
				lSp			= new Sprite();
				lSp.name	= BitmapMovieClip.CADRE_NAME;
				lSp.visible	= false;
				cadreMc		= addChild( lSp) as Sprite;
				
				lSp.graphics.beginFill( 0, 0);
				lSp.graphics.drawRect( lRect.x, lRect.y, lRect.width, lRect.height);
				lSp.graphics.endFill();
			}
		}
	}
}