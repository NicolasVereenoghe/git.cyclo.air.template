package net.cyclo.loading.file {
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import net.cyclo.loading.CycloLoaderMgr;
	import net.cyclo.utils.UtilsMovieClip;
	
	import net.cyclo.shell.MySystem;
	
	/**
	 * descripteur de chargement de fichier spécialisé pour les fichiers de display (swf/images)
	 * 
	 * @author	nico
	 */
	public class LoadingFileDisplay extends LoadingFile {
		/** loader du chargement de fichier de display */
		protected var loader				: Loader;
		
		public function LoadingFileDisplay( pFile : MyFile) { super( pFile);}
		
		public override function free() : void {
			if ( loader.content is Bitmap) ( loader.content as Bitmap).bitmapData.dispose();
			
			loader.unloadAndStop();
			
			super.free();
			
			loader = null;
		}
		
		public override function get bytesLoaded() : int { return loader.contentLoaderInfo.bytesLoaded;}
		
		public override function getLoaderDispatcher() : EventDispatcher { return loader.contentLoaderInfo;}
		
		public override function getLoadedContent( pId : String = null) : * {
			var lEmbedId		: String	= getEmbedName();
			var lEmbedContent	: Class;
			
			if ( pId != null) {
				lEmbedId		+= "_" + pId;
				lEmbedContent	= CycloLoaderMgr.getInstance().getEmbedContent( lEmbedId);
				
				if ( lEmbedContent != null) return new lEmbedContent() as DisplayObject;
				else return new ( _file.applicationDomain.getDefinition( pId) as Class)() as DisplayObject;
			}else {
				lEmbedContent	= CycloLoaderMgr.getInstance().getEmbedContent( lEmbedId);
				
				if ( lEmbedContent != null) return new lEmbedContent() as DisplayObject;
				else return loader.content;
			}
		}
		
		protected override function doLoad() : void {
			if ( CycloLoaderMgr.getInstance().getEmbedContent( getEmbedName()) != null) onLoadComplete( null);
			else {
				loader.load(
					getUrlRequest(),
					new LoaderContext(
						false,
						_file.applicationDomain,
						MySystem.isHttp() ? SecurityDomain.currentDomain : null
					)
				);
			}
		}
		
		protected override function onLoadComplete( pE : Event) : void {
			var lContent	: DisplayObject;
			
			super.onLoadComplete( pE);
			
			if ( CycloLoaderMgr.getInstance().getEmbedContent( getEmbedName()) == null) {
				lContent = loader.content;
				
				if ( lContent is DisplayObjectContainer) UtilsMovieClip.recursiveGotoAndStop( lContent as DisplayObjectContainer, 1);
			}
		}
		
		protected override function buildLoader() : void { loader = new Loader(); }
		
		override protected function addLoaderListener() : void {
			var lEvtDisp	: EventDispatcher	= getLoaderDispatcher();
			
			lEvtDisp.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onLoadIOError);
			
			super.addLoaderListener();
		}
		
		override protected function removeLoaderListener() : void {
			var lEvtDisp	: EventDispatcher	= getLoaderDispatcher();
			
			lEvtDisp.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onLoadIOError);
			
			super.removeLoaderListener();
		}
	}
}