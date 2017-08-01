package {
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.system.Capabilities;
	import net.cyclo.bitmap.BitmapMovieClipMgr;
	import net.cyclo.loading.CycloLoaderMgr;
	import net.cyclo.loading.file.MyFile;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.template.shell.MyShellSample2;
	import net.cyclo.template.shell.ShellDefaultRender;
	
	/**
	 * lanceur d'application web
	 * @author	nico
	 */
	[Frame(factoryClass="Preloader")]
	public class MainWeb extends Sprite {
		[Embed(source = "../bin/assets.xml", mimeType = "application/octet-stream")]
		public static const assets_xml						: Class;
		
		[Embed(source = "../bin/local_fr.xml", mimeType = "application/octet-stream")]
		public static const local_fr_xml					: Class;
		
		[Embed(source = "../bin/local_en.xml", mimeType = "application/octet-stream")]
		public static const local_en_xml					: Class;
		
		[Embed(source = "../bin/splash.png")]
		public static const splash_png						: Class;
		
		[Embed(source = "../bin/button.mp3")]
		public static const button_mp3						: Class;
		
		/** le fichier de description des assets */
		protected static const assetsFile					: MyFile				= new MyFile( "assets.xml");
		
		/** le fichier de localisation FR */
		protected static const _localFileFR					: MyFile				= new MyFile( "local_fr.xml");
		/** le fichier de localisation EN */
		protected static const _localFileEN					: MyFile				= new MyFile( "local_en.xml");
		
		/** ref sur le manager de la coque du jeu */
		protected var _shell								: ShellDefaultRender;
		
		/**
		 * on réucpère le descripteur de fichier de localisation utlisé pour l'appli
		 * @return	descripteur de fichier de localisation
		 */
		protected static function get localFile() : MyFile {
			if ( Capabilities.language == "fr") return _localFileFR;
			else return _localFileEN;
		}
		
		public function MainWeb() {
			super();
			
			if ( stage) init();
			else addEventListener( Event.ADDED_TO_STAGE, init);
		}
		
		protected function init( pE : Event = null) : void {
			removeEventListener( Event.ADDED_TO_STAGE, init);
			
			doInit();
		}
		
		protected function doInit() : void {
			var lDeviceMgr	: MobileDeviceMgr;
			
			stage.quality	= StageQuality.MEDIUM;
			
			MySystem.stage	= stage;
			lDeviceMgr		= new MobileDeviceMgr( stage, 960, 640, 1136, 720, Preloader.SCREEN_WIDTH, Preloader.SCREEN_HEIGHT);
			
			lDeviceMgr.matchMobileFullscreen( this);
			lDeviceMgr.drawMobileBorder( Sprite( addChild( new Sprite())), 0x000000);
			BitmapMovieClipMgr.setBaseScale( lDeviceMgr.baseScale);
			
			CycloLoaderMgr.getInstance().embed = MainWeb;
			
			_shell = new MyShellSample2();
			
			lDeviceMgr.setDeviceCurRenderMgr( _shell);
			
			_shell.initShell( addChildAt( new Sprite(), 0) as DisplayObjectContainer, null, null, localFile, assetsFile);
		}
	}
}