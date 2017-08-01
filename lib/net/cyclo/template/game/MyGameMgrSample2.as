package net.cyclo.template.game {
	import flash.geom.Point;
	import net.cyclo.assets.PatternAsset;
	import net.cyclo.paddle.AcceleroMultiMode;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.sound.SndMgr;
	import net.cyclo.template.game.MyGameMgrSample1;
	import net.cyclo.template.shell.MyShellSample2;
	
	/**
	 * sample 2 de gestionnaire de jeu, enrichissement du sample 1
	 * 
	 * @author nico
	 */
	public class MyGameMgrSample2 extends MyGameMgrSample1 {
		/** suffix identifiant de jeu */
		protected var _gameId						: String							= "";
		
		/** contrôleur de démo */
		protected var cont							: AcceleroMultiMode					= null;
		
		/** compteur de démo */
		protected var ctrFrame						: int								= 0;
		
		/**
		 * construction : on précise l'identifiant de jeu pour les chargement d'assets
		 * @param	pGameId	suffixe identifiant de jeu
		 */
		public function MyGameMgrSample2( pGameId : String) {
			super();
			
			_gameId = pGameId;
		}
		
		/** @inheritDoc */
		override public function destroy() : void {
			// démo auto control
			MobileDeviceMgr.getInstance().setDefaultNoKeepAlive();
			if ( cont != null) {
				cont.destroy();
				cont = null;
			}
			
			super.destroy();
		}
		
		/** @inheritDoc */
		override public function get gameId() : String { return _gameId; }
		
		/** @inheritDoc */
		override public function startGame() : void {
			super.startGame();
			
			shell.enableGameHUD( null);
			
			// démo auto control
			cont = new AcceleroMultiMode( null, -1, -1, ( shell as MyShellSample2).contRefXYZ);
			cont.switchLock( true);
		}
		
		/** @inheritDoc */
		override public function reset() : void {
			super.reset();
			
			// démo auto control
			MobileDeviceMgr.getInstance().setDefaultNoKeepAlive();
			if ( cont != null) {
				cont.destroy();
				cont = null;
			}
		}
		
		/** @inheritDoc */
		override public function switchPause( pIsPause : Boolean) : void {
			super.switchPause( pIsPause);
			
			// démo auto control
			if ( pIsPause) MobileDeviceMgr.getInstance().setDefaultNoKeepAlive();
			
			else MobileDeviceMgr.getInstance().setDefaultKeepAlive();
			if ( ! pIsPause) cont.forceRef( ( shell as MyShellSample2).contRefXYZ);
			
			cont.switchPause( pIsPause);
		}
		
		/** @inheritDoc */
		override protected function switchSndPause( pIsPause : Boolean) : void { SndMgr.getInstance().switchPause( pIsPause, null, MyShellSample2.SND_BUTTON); }
		
		/** @inheritDoc */
		override protected function stopSnd() : void { SndMgr.getInstance().stop( null, MyShellSample2.SND_BUTTON); }
		
		/** @inheritDoc */
		override protected function getGamePatternAsset( pIsLoad : Boolean = true) : Array {
			var lRes	: Array	= super.getGamePatternAsset();
			
			lRes.push( new PatternAsset( GAME_GROUP_ASSET_RADIX, PatternAsset.FIND_ON_GROUP, PatternAsset.MATCH_ALL));
			
			return lRes;
		}
		
		/** @inheritDoc */
		override protected function setModeGame() : void {
			super.setModeGame();
			
			// démo game over
			ctrFrame = 150;
		}
		
		/** @inheritDoc */
		override protected function doModeGame( pDT : int) : void {
			var lIncl	: Point		= cont.getInclinaison();
			
			// démo auto control
			if ( lIncl.length > .25) lIncl.normalize( .25);
			
			_camera.slideTo( new Point( _camera.screenMidX - lIncl.x * 1000, _camera.screenMidY + lIncl.y * 1000));
			
			super.doModeGame( pDT);
			
			// démo game over
			if ( ctrFrame-- <= 0) shell.onGameover( null, savedDatas);
		}
	}
}