package net.cyclo.template.screen {
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * écran générique de loading ; gère anim d'attente (mcWait) / final (mcFinal), barre de loading (mcBar) masquée (mcMask) si définis
	 * 
	 * @author nico
	 */
	public class ScreenLoading extends MyScreen {
		/** nombre de points de progression pris au max lors d'une itération de frame ; points de pourcentage sur ] 0 .. 1] */
		protected var MAX_POINTS_PER_FRAME				: Number						= .05;// .015;
		/** taux visible minimum de progression de la barre de loading ; taux sur ] 0 .. 1] */
		protected var MIN_RATE							: Number						= .005;
		
		/** taux de progression de loading apparent ; [ 0 .. 1] */
		protected var curRate							: Number						= 0;
		/** taux de progression effectif à atteindre par interpolation ; [ 0 .. 1] */
		protected var toRate							: Number						= 0;
		
		/** itérateur de frames du loading */
		protected var framer							: EventDispatcher				= null;
		/** mode d'itération du loading */
		protected var doMode							: Function						= null;
		
		/**
		 * construction
		 */
		public function ScreenLoading() {
			super();
			
			ASSET_ID		= "screen_loading";
			FADE_RGB_USE	= true;
			BG_RGB_USE		= true;
		}
		
		/**
		 * on notifie de la progression effective du loading
		 * @param	pLoadRate	taux de loading effectif, que l'on doit atteindre par interpolation ; [ 0 .. 1]
		 */
		public function onLoadProgress( pLoadRate : Number) : void {
			if ( framer == null) {
				framer = new Sprite();
				framer.addEventListener( Event.ENTER_FRAME, doFrame);
				
				setModeProgress();
			}
			
			toRate	= pLoadRate;
		}
		
		/** @inheritDoc */
		override public function destroy() : void {
			if ( framer != null) {
				if ( framer.hasEventListener( Event.ENTER_FRAME)) framer.removeEventListener( Event.ENTER_FRAME, doFrame);
				
				framer = null;
			}
			
			doMode = null;
			
			if ( getBarMc() != null) getBarMc().mask = null;
			
			if ( getAnimWait() != null) UtilsMovieClip.recursiveGotoAndStop( getAnimWait(), 1);
			if ( getAnimFinal() != null) UtilsMovieClip.recursiveGotoAndStop( getAnimFinal(), 1);
			
			super.destroy();
		}
		
		/** @inheritDoc */
		override public function switchPause( pIsPause : Boolean) : void {
			super.switchPause( pIsPause);
			
			if ( getAnimWait() != null && getAnimWait().visible) {
				if ( pIsPause) UtilsMovieClip.recursiveStop( getAnimWait());
				else UtilsMovieClip.recursivePlay( getAnimWait());
			}
			
			if ( getAnimFinal() != null && getAnimFinal().visible) {
				if ( pIsPause) UtilsMovieClip.recursiveStop( getAnimFinal());
				else UtilsMovieClip.recursivePlay( getAnimFinal());
			}
			
			if ( framer != null) {
				if ( pIsPause) {
					if ( framer.hasEventListener( Event.ENTER_FRAME)) framer.removeEventListener( Event.ENTER_FRAME, doFrame);
				}else if( ! framer.hasEventListener( Event.ENTER_FRAME)) framer.addEventListener( Event.ENTER_FRAME, doFrame);
			}
		}
		
		/** @inheritDoc */
		override protected function buildContent() : void {
			if ( getBarMaskMc() != null) getBarMaskMc().visible = false;
			
			if ( getBarMc() != null) getBarMc().visible = false;
			
			if ( getAnimWait() != null) {
				getAnimWait().visible = true;
				UtilsMovieClip.recursiveGotoAndStop( getAnimWait(), 1);
				UtilsMovieClip.recursivePlay( getAnimWait());
			}
			
			if ( getAnimFinal() != null) {
				getAnimFinal().visible = false;
				UtilsMovieClip.recursiveGotoAndStop( getAnimFinal(), 1);
			}
		}
		
		/**
		 * on récupère le mask de la barre de loading
		 * @return	mask de la barre de loading, null si pas défini
		 */
		protected function getBarMaskMc() : DisplayObject { return getMenuChildByName( "mcMask"); }
		
		/**
		 * on récupère la barre de loading à masquer
		 * @return	barre de loading, null si pas défini
		 */
		protected function getBarMc() : DisplayObject { return getMenuChildByName( "mcBar"); }
		
		/**
		 * on récupère l'anim d'attente
		 * @return	anim d'attente, null si pas défini
		 */
		protected function getAnimWait() : MovieClip { return getMenuChildByName( "mcWait") as MovieClip; }
		
		/**
		 * on récupère l'anim finale
		 * @return	anim finale, null si pas défini
		 */
		protected function getAnimFinal() : MovieClip { return getMenuChildByName( "mcFinal") as MovieClip; }
		
		/**
		 * finalise l'itération de loading en libérant l'itérateur ; la fenêtre reste en l'état, redéfinir pour ajouter une transition
		 */
		protected function doFinal() : void {
			if ( framer != null) {
				if ( framer.hasEventListener( Event.ENTER_FRAME)) framer.removeEventListener( Event.ENTER_FRAME, doFrame);
				
				framer = null;
			}
			
			doMode = null;
		}
		
		/**
		 * itération de loading
		 * @param	pE	event d'itération de frame
		 */
		protected function doFrame( pE : Event) : void { if( doMode != null) doMode(); }
		
		/**
		 * on passe en mode d'itération de progression de la barre de loading
		 */
		protected function setModeProgress() : void {
			if ( getBarMaskMc() != null) {
				getBarMaskMc().visible	= true;
				getBarMaskMc().scaleX	= MIN_RATE;
			}
			
			if ( getBarMc() != null) {
				getBarMc().visible = true;
				
				if ( getBarMaskMc() != null) getBarMc().mask = getBarMaskMc();
				else getBarMc().scaleX = MIN_RATE;
			}
			
			doMode = doModeProgress;
		}
		
		/**
		 * on itère en mode progression de la barre de loading
		 */
		protected function doModeProgress() : void {
			if( curRate < toRate){
				curRate += Math.min( toRate - curRate, MAX_POINTS_PER_FRAME);
				
				if ( getBarMaskMc() != null) getBarMaskMc().scaleX = Math.max( curRate, MIN_RATE);
				else if( getBarMc() != null) getBarMc().scaleX = Math.max( curRate, MIN_RATE);
			}else if ( toRate == 1) setModeFinal();
		}
		
		/**
		 * on passe en mode d'itération de fin de chargement
		 */
		protected function setModeFinal() : void {
			if ( getAnimFinal() != null) {
				if ( getAnimWait() != null) {
					getAnimWait().visible = false;
					UtilsMovieClip.recursiveGotoAndStop( getAnimWait(), 1);
				}
				
				getAnimFinal().visible = true;
				UtilsMovieClip.recursiveGotoAndStop( getAnimFinal(), 1);
				UtilsMovieClip.recursivePlay( getAnimFinal());
				
				doMode = doModeFinal;
			}else doFinal();
		}
		
		/**
		 * on itère en mode fin de chargement
		 */
		protected function doModeFinal() : void {
			if ( UtilsMovieClip.isCurrentFrameAtTotal( getAnimFinal())) {
				UtilsMovieClip.recursiveStop( getAnimFinal());
				
				doFinal();
			}
		}
	}
}