package {
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	/**
	 * preloader de la version jeu stand alone web
	 * @author	nico
	 */
	public class Preloader extends MovieClip {
		public static var SCREEN_WIDTH				: Number				= 960;
		public static var SCREEN_HEIGHT				: Number				= 640;
		
		protected var loadBG						: Sprite;
		protected var loadBar						: Sprite;
		
		protected var doMode						: Function;
		
		protected var loadBarToRate					: Number;
		protected var loadBarCurRate				: Number;
		
		protected var lastTime						: int;
		
		protected var MIN_PROGRESS_TIME				: Number				= 1000;
		protected var PROGRESS_INERTIA				: Number				= .333;
		protected var PROGRESS_MIN_DX				: Number				= 1;
		
		/** délai de fade en ms */
		protected var FADE_DURATION					: int					= 300;
		
		protected var LOADING_BAR_HEIGHT			: Number				= 5;
		
		protected var main							: Object;
		
		public function Preloader() {
			super();
			
			if ( stage) {
				stage.scaleMode 	= StageScaleMode.NO_SCALE;
				stage.align			= StageAlign.TOP_LEFT;
				stage.quality		= StageQuality.HIGH;
			}
			
			//scrollRect = new Rectangle( 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
			
			initLoading();
		}
		
		/**
		 * setter d'alpha du contenu du preloader
		 * @param	pAlpha	valeur d'alpha à appliquer ; [ 0 .. 1]
		 */
		public function set alphaContent( pAlpha : Number) : void { loadBG.alpha = loadBar.alpha = pAlpha; }
		
		/**
		 * getter d'alpha du contenu du preloader
		 * @return	valeur d'alpha appliquée au contenu ; [ 0 .. 1]
		 */
		public function get alphaContent() : Number { return loadBar.alpha; }
		
		/**
		 * on nétoie le contenu de loading
		 */
		public function clearContent() : void {
			removeChild( loadBG);
			loadBG = null;
			
			removeChild( loadBar);
			loadBar = null;
			
			removeEventListener( Event.ENTER_FRAME, doFrame);
		}
		
		/**
		 * initialisation du loading
		 */
		protected function initLoading() : void {
			loadBG				= new Sprite();
			addChild( loadBG);
			loadBG.graphics.beginFill( 0xFFFFFF);
			loadBG.graphics.drawRect( 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
			loadBG.graphics.endFill();
			
			loadBar				= new Sprite();
			addChild( loadBar);
			loadBar.graphics.beginFill( 0);
			loadBar.graphics.drawRect( -SCREEN_WIDTH, 0/*SCREEN_HEIGHT - LOADING_BAR_HEIGHT*/, SCREEN_WIDTH, LOADING_BAR_HEIGHT);
			loadBar.graphics.endFill();
			
			loaderInfo.addEventListener( ProgressEvent.PROGRESS, progress);
			loaderInfo.addEventListener( IOErrorEvent.IO_ERROR, ioError);
			addEventListener( Event.ENTER_FRAME, doFrame);
			
			setModeProgress();
		}
		
		/**
		 * méthode générique de progression de barre de loading
		 * @param	pFullX		dx max de progression
		 * @param	pFromRate	taux de progression de départ ; [ 0 .. 1]
		 * @return true si progression finie, false sinon
		 */
		protected function doProgressGeneric( pFullX : Number, pFromRate : Number) : Boolean {
			var lTime		: int		= getTimer();
			var lDT			: int		= lTime - lastTime;
			var lMaxDRate	: Number	= lDT / MIN_PROGRESS_TIME;
			var lToRate		: Number	= loadBarToRate - loadBarCurRate > lMaxDRate ? loadBarCurRate + lMaxDRate : loadBarToRate;
			var lX			: Number	= pFromRate * SCREEN_WIDTH + lToRate * pFullX;
			var lToX		: Number	= loadBar.x + ( lX - loadBar.x) * PROGRESS_INERTIA;
			
			loadBarCurRate	= lToRate;
			lastTime		= lTime;
			
			if ( lToX - lX <= PROGRESS_MIN_DX) loadBar.x = lX;
			else loadBar.x = lToX;
			
			return ( Math.round( loadBar.x) == Math.round( pFromRate * SCREEN_WIDTH + pFullX));
		}
		
		/**
		 * remise à zéro des propriétés de progression de la barre de loading
		 */
		protected function resetProgParams() : void {
			loadBarToRate	= 0;
			loadBarCurRate	= 0;
			lastTime		= getTimer();
		}
		
		/**
		 * itération de frame
		 * @param	pE	event d'itération de frame
		 */
		protected function doFrame( pE : Event) : void { doMode();}
		
		/**
		 * on passe en mode suivi de progression de la barre de loading du preload initial
		 */
		protected function setModeProgress() : void {
			resetProgParams();
			doMode = doModeProgress;
		}
		
		/**
		 * on agit en mode suivi de progression de la barre de loading de preload initial
		 */
		protected function doModeProgress() : void {
			if ( currentFrame == totalFrames) {
				stop();
				loadBarToRate = 1;
				
				if ( doProgressGeneric( 1 * SCREEN_WIDTH, 0)) loadingFinished();
			}else doProgressGeneric( 1 * SCREEN_WIDTH, 0);
		}
		
		/**
		 * on passe en mode fondu
		 */
		protected function setModeFade() : void {
			lastTime = getTimer();
			
			doMode = doModeFade;
		}
		
		/**
		 * on agit en mode fade
		 */
		protected function doModeFade() : void {
			var lRate	: Number	= Math.max( 0, 1 - ( getTimer() - lastTime) / FADE_DURATION);
			
			alphaContent = lRate;
			
			if ( lRate == 0) clearContent();
		}
		
		private function ioError( e : IOErrorEvent):void { trace( e.text);}
		private function progress( e : ProgressEvent) : void { loadBarToRate = e.bytesLoaded / e.bytesTotal;}
		
		/**
		 * procédure de fin de progression de preload initial : on libère le loading, on se prépare à la progression d'allocation mémorie, on démarre l'appli
		 */
		private function loadingFinished() : void {
			loaderInfo.removeEventListener( ProgressEvent.PROGRESS, progress);
			loaderInfo.removeEventListener( IOErrorEvent.IO_ERROR, ioError);
			
			startup();
			
			setModeFade();
		}
		
		/**
		 * procédure de démarrage d'appli
		 */
		private function startup() : void {
			var mainClass : Class = getDefinitionByName( "MainWeb") as Class;
			main = addChildAt( new mainClass() as DisplayObject, 0);
		}
	}
}