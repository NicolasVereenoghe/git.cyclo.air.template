package net.cyclo.loading.file {
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.utils.ByteArray;
	import net.cyclo.loading.CycloLoaderMgr;
	import net.cyclo.shell.MySystem;
	
	/**
	 * descripteur de chargement de fichier spécialisé pour les fichiers de contenu texte (xml/texte/binaire)
	 * 
	 * @author	nico
	 */
	public class LoadingFileTxt extends LoadingFile {
		/** loader du chargement de fichier de données */
		protected var loader				: URLLoader;
		
		public function LoadingFileTxt( pFile : MyFile) { super( pFile);}
		
		public override function free() : void {
			try {
				loader.close();
			}catch( pE : Error){
				MySystem.traceDebug( "WARNING : LoadingFileTxt::free : stream already closed : " + _file.id);
			}
			
			super.free();
			
			loader = null;
		}
		
		public override function get bytesLoaded() : int { return loader.bytesLoaded;}
		
		public override function getLoaderDispatcher() : EventDispatcher { return loader; }
		
		public override function getLoadedContent( pId : String = null) : * {
			var lEmbedContent	: Class		= CycloLoaderMgr.getInstance().getEmbedContent( getEmbedName());
			var lData			: ByteArray;
			
			if ( lEmbedContent != null) {
				lData	= new lEmbedContent() as ByteArray;
				
				return lData.readUTFBytes( lData.length);
			}else return loader.data as String;
		}
		
		protected override function doLoad() : void {
			if ( CycloLoaderMgr.getInstance().getEmbedContent( getEmbedName()) != null) onLoadComplete( null);
			else loader.load( getUrlRequest());
		}
		
		protected override function buildLoader() : void {
			loader				= new URLLoader();
			loader.dataFormat	= URLLoaderDataFormat.TEXT;
		}
	}
}