package net.cyclo.template.game {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	import net.cyclo.mycam.MyCamera;
	import net.cyclo.mysprite.LvlMgr;
	import net.cyclo.mysprite.MySpFrameAnim;
	import net.cyclo.mysprite.MySpSkewBox;
	import net.cyclo.mysprite.MySpDecorFront;
	import net.cyclo.mysprite.MySpLimitBot;
	import net.cyclo.mysprite.MySpLimitLeft;
	import net.cyclo.mysprite.MySpLimitRight;
	import net.cyclo.mysprite.MySpLimitTop;
	import net.cyclo.mysprite.MySpriteMgr;
	import net.cyclo.mysprite.MySpSkew;
	import net.cyclo.mysprite.MySpSkewFrontBox;
	import net.cyclo.mysprite.MySpWall;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.sound.SndMgr;
	import net.cyclo.template.shell.datas.SavedDatas;
	import flash.display.DisplayObjectContainer;
	import net.cyclo.template.shell.IGameShell;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * exemple de gestionnaire de jeu avec moteur de sprites
	 * 
	 * @author nico
	 */
	public class MyGameMgrSample1 extends GameMgrAssets {
		/** fps de jeu */
		protected var FPS									: int								= 30;
		
		/** couleur RGB de bg du jeu */
		protected var BG_COL								: uint								= 0xffffff;
		
		/** conteneur utilisé par le moteur de sprites */
		protected var spriteContainer						: DisplayObjectContainer			= null;
		/** conteneur du bg RGB du jeu */
		protected var bg									: Sprite							= null;
		
		/** moteur de sprites */
		protected var _spriteMgr							: MySpriteMgr						= null;
		/** caméra du moteur de sprites */
		protected var _camera								: MyCamera							= null;
		
		/** itérateur de frame du jeu */
		protected var framer								: MovieClip							= null;
		/** dernier moment d'itération de jeu (getTimer) */
		protected var lastTime								: int								= -1;
		/** jeu en pause (true) ou pas (false) */
		protected var isPause								: Boolean							= false;
		/** méthode de mode d'itération ; prend en paramètres le dt en ms depuis la dernière itération */
		protected var doMode								: Function							= null;
		
		/** réf sur la caméra du moteur de sprites */
		public function get camera() : MyCamera { return _camera; }
		
		/** réf sur le moteur de sprites du jeu */
		public function get spriteMgr() : MySpriteMgr { return _spriteMgr; }
		
		/** @inheritDoc */
		override public function get gameId() : String { return ""; }
		
		/** @inheritDoc */
		override public function init( pShell : IGameShell, pGameContainer : DisplayObjectContainer, pSavedDatas : SavedDatas = null) : void {
			var lRect	: Rectangle	= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			
			bg				= pGameContainer.addChild( new Sprite()) as Sprite;
			bg.graphics.beginFill( BG_COL);
			bg.graphics.drawRect( lRect.x, lRect.y, lRect.width, lRect.height);
			bg.graphics.endFill();
			
			_camera = instanciateCamera();
			_camera.init(
				INIT_X,
				INIT_Y,
				( lRect.left + lRect.right) / 2,
				( lRect.top + lRect.bottom) / 2,
				lRect.width,
				lRect.height
			);
			
			initSpriteContainer( pGameContainer);
			_spriteMgr		= getSpMgrInstance();
			_spriteMgr.init( spriteContainer, this, _camera);
			
			setModeVoid();
			
			super.init( pShell, pGameContainer, pSavedDatas);
			
			MySpDecorFront;
			MySpLimitLeft;
			MySpLimitRight;
			MySpLimitTop;
			MySpLimitBot;
			MySpSkew;
			MySpSkewBox;
			MySpSkewFrontBox;
			MySpWall;
			MySpFrameAnim;
		}
		
		/** @inheritDoc */
		override public function destroy() : void {
			stopSnd();
			
			freeFrame();
			
			_spriteMgr.destroy();
			_spriteMgr = null;
			
			_camera = null;
			
			freeSpriteContainer();
			
			UtilsMovieClip.clearFromParent( bg);
			bg.graphics.clear();
			bg = null;
			
			super.destroy();
		}
		
		/** @inheritDoc */
		override public function startGame() : void {
			initFrame();
			
			setModeGame();
			
			_spriteMgr.setInitView();
			
			// TODO : ajouter le player
		}
		
		/** @inheritDoc */
		override public function reset() : void {
			var lRect	: Rectangle	= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			
			stopSnd();
			
			_spriteMgr.destroy();
			_spriteMgr = getSpMgrInstance();
			
			_camera	= instanciateCamera();
			_camera.init(
				INIT_X,
				INIT_Y,
				( lRect.left + lRect.right) / 2,
				( lRect.top + lRect.bottom) / 2,
				lRect.width,
				lRect.height
			);
			
			_spriteMgr.init( spriteContainer, this, _camera);
			
			setModeVoid();
		}
		
		/** @inheritDoc */
		override public function switchPause( pIsPause : Boolean) : void {
			isPause	= pIsPause;
			
			if ( ! pIsPause) {
				lastTime = getTimer();
				MySystem.forceFPS( FPS);	
			}else MySystem.restaureFPS();
			
			switchSndPause( pIsPause);
			_spriteMgr.switchPause( pIsPause);
		}
		
		/**
		 * libération du conteneur de sprites
		 */
		protected function freeSpriteContainer() : void {
			UtilsMovieClip.clearFromParent( spriteContainer);
			spriteContainer = null;
		}
		
		/**
		 * initialisation du conteneur de sprites
		 * @param	pGameContainer	conteneur de jeu (pas encore affecté à GameMgrAssets::gameContainer)
		 */
		protected function initSpriteContainer( pGameContainer : DisplayObjectContainer) : void {
			spriteContainer	= pGameContainer.addChild( new Sprite()) as DisplayObjectContainer;
		}
		
		/**
		 * on crée l'instance de caméra
		 * @return	instance de caméra du jeu
		 */
		protected function instanciateCamera() : MyCamera { return new MyCamera(); }
		
		/**
		 * abscisse du point de vue initial à partir des données de lvl ; la vue initiale doit être définie
		 * @return	abscisse
		 */
		protected function get INIT_X() : Number {
			return parseFloat( LvlMgr.getInstance().getLvlData( LvlMgr.DATA_INIT_X, gameId != "" ? gameId : null));
		}
		
		/**
		 * ordonnée du point de vue initial à partir des données de lvl ; la vue initiale doit être définie
		 * @return	ordonnée
		 */
		protected function get INIT_Y() : Number {
			return parseFloat( LvlMgr.getInstance().getLvlData( LvlMgr.DATA_INIT_Y, gameId != "" ? gameId : null));
		}
		
		/**
		 * on bascule la pause des sons
		 */
		protected function switchSndPause( pIsPause : Boolean) : void { SndMgr.getInstance().switchPause( pIsPause); }
		
		/**
		 * on arrête les sons de jeu
		 */
		protected function stopSnd() : void { SndMgr.getInstance().stop(); }
		
		/**
		 * on crée une instance de moteur de sprites ; util à redéfinir pour fournir un moteur spécialisé
		 * @return	instance de moteur de sprites
		 */
		protected function getSpMgrInstance() : MySpriteMgr { return new MySpriteMgr( gameId); }
		
		/**
		 * initialisation de l'itérateur de frames du jeu
		 */
		protected function initFrame() : void {
			if ( framer == null) framer = new MovieClip();
			
			if ( ! framer.hasEventListener( Event.ENTER_FRAME)) framer.addEventListener( Event.ENTER_FRAME, doFrame);
			
			lastTime = getTimer();
		}
		
		/**
		 * on libère l'itération de frames
		 */
		protected function freeFrame() : void {
			if ( framer != null) {
				if ( framer.hasEventListener( Event.ENTER_FRAME)) framer.removeEventListener( Event.ENTER_FRAME, doFrame);
				
				framer = null;
			}
		}
		
		/**
		 * on effectue l'iration de frame du jeu
		 * @param	pE	event de framing
		 */
		protected function doFrame( pE : Event) : void {
			var lTime : int = getTimer();
			
			if ( ! isPause) doMode( lTime - lastTime);
			
			lastTime = lTime;
		}
		
		/**
		 * on passe en mode d'itération vide
		 */
		protected function setModeVoid() : void { doMode = doModeVoid;}
		
		/**
		 * on agit en mode d'itération vide
		 * @param	pDT	dt en ms depuis dernière itération
		 */
		protected function doModeVoid( pDT : int) : void { }
		
		/**
		 * on passe en mode d'itération de jeu
		 */
		protected function setModeGame() : void { doMode = doModeGame;}
		
		/**
		 * on agit en mode d'itération de jeu
		 * @param	pDT	dt en ms depuis dernière itération
		 */
		protected function doModeGame( pDT : int) : void {
			_spriteMgr.doFrame( pDT);
			
			// TODO : itération des instances du jeu
		}
	}
}