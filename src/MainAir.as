package {
	CONFIG::AIR { import flash.desktop.NativeApplication; }
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.display.StageQuality;
	import flash.events.KeyboardEvent;
	import flash.system.Capabilities;
	import net.cyclo.bitmap.BitmapMovieClipMgr;
	import net.cyclo.loading.file.MyFile;
	import net.cyclo.shell.MySystem;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.sound.SndMgr;
	import net.cyclo.template.shell.MyShellSample2;
	import net.cyclo.template.shell.ShellDefaultRender;
	
	/**
	 * lanceur d'application
	 * @author nico
	 */
	public class MainAir extends Sprite {
		/** le fichier de description des assets */
		protected static const assetsFile		: MyFile				= new MyFile( "assets.xml");
		
		/** le fichier de localisation FR */
		protected static const _localFileFR		: MyFile				= new MyFile( "local_fr.xml");
		/** le fichier de localisation EN */
		protected static const _localFileEN		: MyFile				= new MyFile( "local_en.xml");
		
		/**
		 * on réucpère le descripteur de fichier de localisation utlisé pour l'appli
		 * @return	descripteur de fichier de localisation
		 */
		protected static function get localFile() : MyFile {
			if ( Capabilities.language == "fr") return _localFileFR;
			else return _localFileEN;
		}
		
		/** ref sur le manager de la coque du jeu */
		protected var _shell					: ShellDefaultRender;
		
		public function MainAir() {
			var lDeviceMgr	: MobileDeviceMgr;
			
			super();
			
			stage.quality		= StageQuality.MEDIUM;
			stage.displayState	= StageDisplayState.FULL_SCREEN_INTERACTIVE;
			
			NativeApplication.nativeApplication.addEventListener( KeyboardEvent.KEY_DOWN, onKeyDown);
			
			MySystem.stage	= stage;
			lDeviceMgr		= new MobileDeviceMgr( stage, 960, 640, 1136, 720);
			
			lDeviceMgr.matchMobileFullscreen( this);
			lDeviceMgr.drawMobileBorder( Sprite( addChild( new Sprite())), 0x000000);
			BitmapMovieClipMgr.setBaseScale( lDeviceMgr.baseScale);
			
			CONFIG::AIR { MySystem.traceDebug( NativeApplication.nativeApplication.runtimeVersion.toString());}
			
			_shell = new MyShellSample2();
			
			lDeviceMgr.setDeviceCurRenderMgr( _shell);
			
			_shell.initShell( addChildAt( new Sprite(), 0) as DisplayObjectContainer, null, null, localFile, assetsFile);
		}
		
		protected function onKeyDown( pE : KeyboardEvent) : void {
			if ( pE.keyCode == 27) {
				pE.preventDefault();
				
				MobileDeviceMgr.getInstance().exit();
			}
		}
	}
}