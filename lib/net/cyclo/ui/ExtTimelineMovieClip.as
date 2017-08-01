package net.cyclo.ui {
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.filters.BlurFilter;
	import flash.utils.getQualifiedClassName;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * place holder de time line externe
	 * ce composant sert de wrapper à la time line chargée
	 * la time line est sous forme d'asset de time line
	 * l'identifiant de liaison de l'instance sert d'id d'asset de time line à récupérer
	 * @author	nico
	 */
	public class ExtTimelineMovieClip extends MovieClip {
		/** l'instance d'asset de time line chargée */
		protected var timeline					: AssetInstance							= null;
		
		/**
		 * construction : on prépare à lancer le remplacement de graphisme quand le contenu sera ajouté à la display list
		 */
		public function ExtTimelineMovieClip() {
			super();
			
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			
			super.stop();
		}
		
		/** @inheritDoc */
		override public function get currentFrame() : int {
			if ( timeline != null) return ( timeline.content as MovieClip).currentFrame;
			else return 1;
		}
		
		/** @inheritDoc */
		override public function get totalFrames() : int {
			if ( timeline != null) return ( timeline.content as MovieClip).totalFrames;
			else return 1;
		}
		
		/** @inheritDoc */
		override public function play() : void { if ( timeline != null) ( timeline.content as MovieClip).play(); }
		
		/** @inheritDoc */
		override public function stop() : void { if ( timeline != null) ( timeline.content as MovieClip).stop(); }
		
		/** @inheritDoc */
		override public function gotoAndPlay( pFr : Object, pSc : String = null) : void { if ( timeline != null) ( timeline.content as MovieClip).gotoAndPlay( pFr, pSc); }
		
		/** @inheritDoc */
		override public function gotoAndStop( pFr : Object, pSc : String = null) : void { if ( timeline != null) ( timeline.content as MovieClip).gotoAndStop( pFr, pSc); }
		
		/** @inheritDoc */
		override public function nextFrame() : void { if ( timeline != null) ( timeline.content as MovieClip).nextFrame(); }
		
		/** @inheritDoc */
		override public function prevFrame() : void { if ( timeline != null) ( timeline.content as MovieClip).prevFrame(); }
		
		/** @inheritDoc */
		override public function get numChildren() : int {
			if ( timeline != null) return ( timeline.content as MovieClip).numChildren;
			else return 0;
		}
		
		/** @inheritDoc */
		override public function getChildAt( pI : int) : DisplayObject {
			if ( timeline != null) return ( timeline.content as MovieClip).getChildAt( pI);
			return null;
		}
		
		/**
		 * le clip est posé sur la scène, on remplace par le graphisme de time line
		 * @param	pE	évènement d'ajout sur scène
		 */
		protected function onAddedToStage( pE : Event) : void {
			removeEventListener( Event.ADDED_TO_STAGE, onAddedToStage);
			
			while ( super.numChildren > 0) UtilsMovieClip.free( super.getChildAt( 0));
			
			timeline = AssetsMgr.getInstance().getAssetInstance( getQualifiedClassName( this));
			addChild( timeline);
			
			UtilsMovieClip.recursivePlay( timeline);
			
			addEventListener( Event.REMOVED_FROM_STAGE, onRemove);
		}
		
		/**
		 * le clip est retiré de la scène, on libère la mémoire
		 * @param	pE	évènement de virage de scène ; peut être levé pour tout enfant du clip, on doit contrôler qu'il s'agit bien de l'instance
		 */
		protected function onRemove( pE : Event) : void {
			if( pE.currentTarget == this){
				removeEventListener( Event.REMOVED_FROM_STAGE, onRemove);
				
				UtilsMovieClip.free( timeline);
				timeline.free();
				timeline = null;
			}
		}
	}
}