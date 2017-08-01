package net.cyclo.loading.file {
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import net.cyclo.loading.CycloLoaderMgr;
	import net.cyclo.shell.MySystem;
	
	/**
	 * descripteur de chargement de fichier spécialisé pour le son
	 * @author	nico
	 */
	public class LoadingFileSnd extends LoadingFile {
		/** loader du chargement de fichier de display */
		protected var loader				: Sound;
		
		public function LoadingFileSnd( pFile : MyFile) { super( pFile); }
		
		public override function free() : void {
			try {
				loader.close();
			}catch ( pE : Error) {
				MySystem.traceDebug( "WARNING : LoadingFileSnd::free : stream already closed : " + _file.id);
			}
			
			super.free();
			
			loader = null;
		}
		
		public override function get bytesLoaded() : int { return loader.bytesLoaded; }
		
		public override function getLoaderDispatcher() : EventDispatcher { return loader; }
		
		public override function getLoadedContent( pId : String = null) : * {
			var lEmbedContent	: Class		= CycloLoaderMgr.getInstance().getEmbedContent( getEmbedName());
			
			if ( lEmbedContent != null) return new lEmbedContent() as Sound;
			else return loader;
		}
		
		protected override function doLoad() : void {
			if ( CycloLoaderMgr.getInstance().getEmbedContent( getEmbedName()) != null) onLoadComplete( null);
			else loader.load( getUrlRequest());
		}
		
		protected override function buildLoader() : void { loader = new Sound(); }
	}
}