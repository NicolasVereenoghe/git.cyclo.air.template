package net.cyclo.shell.device {
	CONFIG::AIR { import flash.desktop.NativeApplication; }
	
	CONFIG::AIR { import flash.desktop.SystemIdleMode; }
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import net.cyclo.utils.UtilsMaths;
	
	CONFIG::AIR { import flash.media.AudioPlaybackMode;}
	
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.system.Capabilities;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.Timer;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * gestion de fonctionnalités de devices mobiles
	 * @author nico
	 */
	public class MobileDeviceMgr {
		/** réf sur singleton ; null si non défini */
		protected static var _current		: MobileDeviceMgr		= null;
		
		/** réf sur le stage de l'appli */
		protected var _stage				: Stage					= null;
		
		/** temps d'attente en mode désactivé avant de killer l'appli */
		protected var EXIT_TIMER_DELAY		: int					= 60 * 5 * 1000;
		/** timer en mode désactivé au bout duquel on kill l'appli si pas de réactivation */
		protected var exitTimer				: Timer					= null;
		
		/** fps quand on est désactivé */
		protected var DEACTIVATE_FPS		: Number				= 4;
		/** temporisation d'égalisation de son quand on passe en désactivé */
		protected var tmpDeactivateSnd		: SoundTransform		= null;
		
		/** largeur de base du stage ; on le précise car Stage::width foire sous android */
		protected var _stageWidth			: Number;
		/** hauteur de base du stage ; on le précise car Stage::height foire sous android */
		protected var _stageHeight			: Number;
		
		/** largeur d'écran de device ; laisser -1 pour laisser flash le déterminer, sinon préciser pour forcer une taille fixe d'écran */
		protected var _screenWidth			: Number				= -1;
		/** hauteur d'écran de device ; laisser -1 pour laisser flash le déterminer, sinon préciser pour forcer une taille fixe d'écran */
		protected var _screenHeight			: Number				= -1;
		
		/** le scale de base à appliquer à l'appli pour coller aux contours du fullscreen */
		protected var _baseScale			: Number				= 1;
		/** rectangle de la zone d'affichage dans un conteneur qui match le fullscreen mobile ( voir ::matchMobileFullscreen) ; les dimensions sont bornées par ::MAX_WIDTH et ::MAX_HEIGHT */
		protected var _mobileFullscreenRect	: Rectangle				= null;
		
		/** largeur max théorique de la zone d'affichage qu'on fait matcher en fullscreen */
		protected var MAX_WIDTH				: Number;
		/** hauteur max théorique de la zone d'affichage qu'on fait matcher en fullscreen */
		protected var MAX_HEIGHT			: Number;
		
		/** gestionnaire de fonctionnalités de device mobile du rendu en cours ; null si aucun */
		protected var _deviceCurRenderMgr	: IDeviceCurRenderMgr	= null;
		
		/** flag indiquant si on est désactivé (true) ou pas (false) */
		protected var _isDeactivate			: Boolean				= false;
		
		/** nom d'instance du verrou d'interaction boutons */
		protected var LOCKER_NAME			: String				= "mcLock";
		
		/** épaisseur de bordures */
		protected var BORDER_THICKNESS		: Number				= 500;
		
		/** mode "keep alive" par défaut (voir cstes de SystemIdleMode) */
		CONFIG::AIR { protected var keepAliveMode			: String				= SystemIdleMode.NORMAL;}
		
		/** taille de diagonale limite entre gabarit tablette et téléphone */
		protected var TABLET_DIAG_LIMIT		: Number				= 6.5;
		
		/** rotation en degrés à appliquer au contenu pour suivre l'orientation du device ; sur { -90, 0, 90, 180} */
		protected var _rotContent			: int					= 0;
		/** cos d'angle de rotation à appliquer pour suivre orientation du device */
		protected var _rotContentCos		: Number				= 1;
		/** sin d'angle de rotation à appliquer pour suivre orientation du device */
		protected var _rotContentSin		: Number				= 0;
		
		/**
		 * on récupère le cos d'orientation de device
		 * @return	cos d'angle
		 */
		public function get rotContentCos() : Number { return _rotContentCos; }
		
		/**
		 * on récupère le sin d'orientation de device
		 * @return	sin d'angle
		 */
		public function get rotContentSin() : Number { return _rotContentSin; }
		
		/**
		 * on récupère rotation en degrés à appliquer au contenu pour suivre l'orientation du device
		 * @return	orientation à appliquer en deg dans { -90, 0, 90, 180}
		 */
		public function get rotContent() : int { return _rotContent; }
		
		/**
		 * on définit la rotation en degrés à appliquer au contenu pour suivre l'orientation du device
		 * @param	pRot	orientation à appliquer en deg dans { -90, 0, 90, 180}
		 */
		public function set rotContent( pRot : int) : void {
			var lA	: Number	= -pRot * UtilsMaths.COEF_DEG_2_RAD;
			
			_rotContent		= pRot;
			_rotContentCos	= Math.cos( lA);
			_rotContentSin	= Math.sin( lA);
		}
		
		/**
		 * constructeur : on crée et on initialise le singleton ; attention, une seule instance acceptée, sinon une erreur est levée
		 * @param	pStage			réf sur le stage de l'application
		 * @param	pStageWidth		largeur du stage ; on le précise car Stage::width foire sous android
		 * @param	pStageHeigth	hauteur du stage ; on le précise car Stage::height foire sous android
		 * @param	pMaxWidth		largeur max théorique de la zone d'affichage qu'on fait matcher en fullscreen
		 * @param	pMaxHeight		hauteur max théorique de la zone d'affichage qu'on fait matcher en fullscreen
		 * @param	pFixedScreenW	largeur d'écran de device ; laisser -1 pour laisser flash le déterminer, sinon préciser pour forcer une taille fixe d'écran
		 * @param	pFixedScreenH	hauteur d'écran de device ; laisser -1 pour laisser flash le déterminer, sinon préciser pour forcer une taille fixe d'écran
		 * @throws	Error			erreur si instance déjà déclarée en singleton
		 */
		public function MobileDeviceMgr( pStage : Stage, pStageWidth : Number, pStageHeight : Number, pMaxWidth : Number, pMaxHeight : Number, pFixedScreenW : Number = -1, pFixedScreenH : Number = -1) {
			if ( _current != null) {
				throw new Error( "MobileDeviceMgr::MobileDeviceMgr : il y a déjà une instance de déclarée en singleton");
			}
			
			_current			= this;
			_stage				= pStage;
			_stage.scaleMode	= StageScaleMode.NO_SCALE;
			_stage.align		= StageAlign.TOP_LEFT;
			_stageWidth			= pStageWidth;
			_stageHeight		= pStageHeight;
			_screenWidth		= pFixedScreenW;
			_screenHeight		= pFixedScreenH;
			MAX_WIDTH			= pMaxWidth;
			MAX_HEIGHT			= pMaxHeight;
			
			defineBaseScale();
			setTouchMode();
			registerBrowseEvents();
			initIOSPlaybackMode();
		}
		
		/**
		 * on récupère la réf sur le singleton
		 * @return	réf sur singleton, ou null si pas encore instancié
		 */
		public static function getInstance() : MobileDeviceMgr { return _current; }
		
		/**
		 * on vérifie si le device est désactivé
		 * @return	true si device désactivé, false sinon
		 */
		public function get isDeactivate() : Boolean { return _isDeactivate;}
		
		/**
		 * on récupère la largeur minimum de base définie pour l'appli
		 * @return	largeur minimum de base
		 */
		public function get minStageWidth() : Number { return _stageWidth; }
		
		/**
		 * on récupère la hauteur minimum de base définie pour l'appli
		 * @return	hauteur minimum de base
		 */
		public function get minStageHeight() : Number { return _stageHeight;}
		
		/**
		 * on récupère la largeur maximum de base définie pour l'appli
		 * @return	largeur maximum de base
		 */
		public function get maxStageWidth() : Number { return MAX_WIDTH; }
		
		/**
		 * on récupère la hauteur maximum de base définie pour l'appli
		 * @return	hauteur maximum de base
		 */
		public function get maxStageHeight() : Number { return MAX_HEIGHT;}
		
		/**
		 * on récupère le scale de base à appliqer sur l'appli pour matcher le fullscreen
		 * @return	scale de base
		 */
		public function get baseScale() : Number { return _baseScale;}
		
		/**
		 * on récupère le rectangle de l'affichage dans le repère d'un conteneur qui match le fullscreen ( voir ::matchMobileFullscreen)
		 * @return	rectangle définissant les contours du fullscreen mobile ; on retourne un clone ; les dimensions sont bornées par ::MAX_WIDTH et ::MAX_HEIGHT
		 */
		public function get mobileFullscreenRect() : Rectangle { return _mobileFullscreenRect.clone(); }
		
		/**
		 * on récupère le rectangle de l'affichage dans le repère d'un conteneur sous rotation automatique qui match le fullscreen ( voir ::matchMobileFullscreen)
		 * en prenant en compte le changement d'orientation
		 * @return	rectangle définissant les contours du fullscreen mobile ; on retourne un clone ; origine repère sur centre contenu ; les dimensions sont bornées par ::MAX_WIDTH et ::MAX_HEIGHT ; prend en compte la rotation de contenu auto orienté
		 */
		public function get mobileFullscreenRectRot() : Rectangle {
			if ( rotContent == 0 || rotContent == 180) return new Rectangle( -_mobileFullscreenRect.width / 2, -_mobileFullscreenRect.height / 2, _mobileFullscreenRect.width, _mobileFullscreenRect.height);
			else return new Rectangle( -_mobileFullscreenRect.height / 2, -_mobileFullscreenRect.width / 2, _mobileFullscreenRect.height, _mobileFullscreenRect.width);
		}
		
		/**
		 * on récupère la largeur de l'écran de jeu
		 * @return	largeur d'écran de jeu
		 */
		public function get screenWidth() : Number {
			if ( _screenWidth > 0) return _screenWidth;
			
			CONFIG::Mobile { return _stage.fullScreenWidth; }
			
			return _stage.stageWidth;
		}
		
		/**
		 * on récupère la hauteur de l'écran de jeu
		 * @return	hauteur d'écran de jeu
		 */
		public function get screenHeight() : Number {
			if ( _screenHeight > 0) return _screenHeight;
			
			CONFIG::Mobile { return _stage.fullScreenHeight; }
			
			return _stage.stageHeight;
		}
		
		/**
		 * on match le stage pour s'adapter à l'écran mobile utilisé (à n'utiliser qu'une seule fois sur le conteneur du jeu)
		 * @param	pDisp	objet graphique à faire matcher au fullscreen
		 */
		public function matchMobileFullscreen( pDisp : DisplayObject) : void {
			pDisp.x			= ( screenWidth - _stageWidth * _baseScale) / 2;
			pDisp.y			= ( screenHeight - _stageHeight * _baseScale) / 2;
			pDisp.scaleX	= pDisp.scaleY = _baseScale;
		}
		
		/**
		 * on dessine des bordures épaisses autour de la zone d'affichage pour masquer ce qui est hors affichage
		 * @param	pBorders	conteneur où on va dessiner les bordures ; ce conteneur doit faire partie du contenu matché en fullscreen
		 * @param	pColor		code RGB de la bordure
		 * @param	pThickness	épaisseur de bordure ; laisser -1 pour réglage par défaut (::BORDER_THICKNESS)
		 * @param	pOffset		offset de débordement intérieur de bordure (faire un liseré) ; laisser 0 pour aucun
		 */
		public function drawMobileBorder( pBorders : Sprite, pColor : uint, pThickness : Number = -1, pOffset : Number = 0) : void {
			var lThickness	 : Number	= pThickness > 0 ? pThickness : BORDER_THICKNESS;
			
			pBorders.graphics.beginFill( pColor);
			pBorders.graphics.drawRect( _mobileFullscreenRect.left - lThickness + pOffset, _mobileFullscreenRect.top/* - lThickness*/, lThickness, _mobileFullscreenRect.height /*+ 2 * lThickness*/);// gauche
			pBorders.graphics.endFill();
			
			pBorders.graphics.beginFill( pColor);
			pBorders.graphics.drawRect( _mobileFullscreenRect.right - pOffset, _mobileFullscreenRect.top/* - lThickness*/, lThickness, _mobileFullscreenRect.height/* + 2 * lThickness*/);// droite
			pBorders.graphics.endFill();
			
			pBorders.graphics.beginFill( pColor);
			pBorders.graphics.drawRect( _mobileFullscreenRect.left - lThickness, _mobileFullscreenRect.top - lThickness + pOffset, _mobileFullscreenRect.width + 2 * lThickness, lThickness);
			pBorders.graphics.endFill();
			
			pBorders.graphics.beginFill( pColor);
			pBorders.graphics.drawRect( _mobileFullscreenRect.left - lThickness, _mobileFullscreenRect.bottom - pOffset, _mobileFullscreenRect.width + 2 * lThickness, lThickness);
			pBorders.graphics.endFill();
			
			pBorders.mouseChildren = false;
			pBorders.mouseEnabled = false;
		}
		
		/**
		 * on dessine des bordures épaisses autour de la zone d'affichage pour masquer ce qui est hors affichage ; méthode appliquée à un conteneur non déformé depuis le stage
		 * @param	pBorders	conteneur où on va dessiner les bordures
		 * @param	pColor		code RGB de la bordure
		 */
		public function drawStageBorder( pBorders : Sprite, pColor : uint) : void {
			pBorders.graphics.beginFill( pColor);
			pBorders.graphics.drawRect( -BORDER_THICKNESS, 0, BORDER_THICKNESS, screenHeight);// gauche
			pBorders.graphics.endFill();
			
			pBorders.graphics.beginFill( pColor);
			pBorders.graphics.drawRect( screenWidth, 0, BORDER_THICKNESS, screenHeight);// droite
			pBorders.graphics.endFill();
			
			pBorders.graphics.beginFill( pColor);
			pBorders.graphics.drawRect( -BORDER_THICKNESS, -BORDER_THICKNESS, screenWidth + 2 * BORDER_THICKNESS, BORDER_THICKNESS);
			pBorders.graphics.endFill();
			
			pBorders.graphics.beginFill( pColor);
			pBorders.graphics.drawRect( -BORDER_THICKNESS, screenHeight, screenWidth + 2 * BORDER_THICKNESS, BORDER_THICKNESS);
			pBorders.graphics.endFill();
			
			pBorders.mouseChildren = false;
			pBorders.mouseEnabled = false;
		}
		
		/**
		 * on défint quel est le gestionnaire de fonctionnalités de device mobile du rendu en cours
		 * @param	pDeviceCurRender	gestionnaire de fonctionnalités de device mobile du rendu en cours à utiliser, ou null pour libérer le gestionnaire en cours
		 */
		public function setDeviceCurRenderMgr( pDeviceCurRender : IDeviceCurRenderMgr) : void { _deviceCurRenderMgr	= pDeviceCurRender; }
		
		/**
		 * on verrouille/déverrouille les interactions boutons
		 * @param	pIsLock	true pour verrouiller, false pour déverrouiller
		 */
		public function switchLock( pIsLock : Boolean) : void {
			var lLock	: Sprite	= Sprite( _stage.getChildByName( LOCKER_NAME));
			
			if ( pIsLock && lLock == null) {
				MySystem.traceDebug( "locked");
				
				lLock		= Sprite( _stage.addChild( new Sprite()));
				lLock.name	= LOCKER_NAME;
				
				lLock.graphics.beginFill( 0, 0);
				lLock.graphics.drawRect( 0, 0, screenWidth, screenHeight);
				lLock.graphics.endFill();
			}else if ( ( ! pIsLock) && lLock != null) {
				MySystem.traceDebug( "unlocked");
				
				UtilsMovieClip.free( lLock);
			}
		}
		
		/**
		 * on vérifie si le verrou global des boutons est actif ou pas
		 * @return	true si verrou actif, false sinon
		 */
		public function isLocked() : Boolean { return _stage.getChildByName( LOCKER_NAME) != null;}
		
		/**
		 * on quitte l'appli ; fonctionnel uniquement si device mobile
		 */
		public function exit() : void { CONFIG::AIR { NativeApplication.nativeApplication.exit();}}
		
		/**
		 * on demande garder l'appli "vivante" par défaut
		 */
		public function setDefaultKeepAlive() : void {
			CONFIG::Mobile {
				keepAliveMode = SystemIdleMode.KEEP_AWAKE;
				
				NativeApplication.nativeApplication.systemIdleMode = keepAliveMode;
			}
		}
		
		/**
		 * on demande que par défaut l'appli se mette en veillie
		 */
		public function setDefaultNoKeepAlive() : void {
			CONFIG::Mobile {
				keepAliveMode = SystemIdleMode.NORMAL;
				
				NativeApplication.nativeApplication.systemIdleMode = keepAliveMode;
			}
		}
		
		/**
		 * on vérifie si on est dans un environnement "Mobile"
		 * @return	true si environnement "mobile", false sinon
		 */
		public function isMobile() : Boolean {
			CONFIG::Mobile {
				return true;
			}
			
			return false;
		}
		
		/**
		 * on vérifie si on est sous IOS
		 * @return	true si IOS, false sinon
		 */
		public function isIOS() : Boolean { return Capabilities.os.indexOf( "iP") >= 0; }
		
		/**
		 * on vérifie si le device est une tablette
		 * @return	true si tablette, false sinon
		 */
		public function isTablet() : Boolean {
			if ( isIOS()) return Capabilities.os.indexOf( "iPa") >= 0;
			else return getDeviceDiag() > TABLET_DIAG_LIMIT;
		}
		
		/**
		 * calcul de diagonal d'écran
		 * @return	diagonale d'écran
		 */
		protected function getDeviceDiag() : Number {
			var lX	: Number	= screenWidth / Capabilities.screenDPI;
			var lY	: Number	= screenHeight / Capabilities.screenDPI;
			
			return Math.sqrt( Math.pow( lX, 2) + Math.pow( lY, 2));
		}
		
		/**
		 * on initialise le canal audio pour que sous ios la targette désactive le son ; réactif uniquement sous ios
		 */
		protected function initIOSPlaybackMode() : void { CONFIG::AIR { SoundMixer.audioPlaybackMode = AudioPlaybackMode.AMBIENT;}}
		
		/**
		 * listener d'event de désactivation d'application
		 * @param	pE	event de désactivation
		 */
		protected function onBrowseDeactivate( pE : Event) : void {
			if( ! _isDeactivate){
				_isDeactivate				= true;
				
				exitTimer					= new Timer( EXIT_TIMER_DELAY, 1);
				exitTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onDeactivateComplete);
				exitTimer.start();
				
				if ( _deviceCurRenderMgr != null) _deviceCurRenderMgr.onBrowseDeactivate();
				else trace( "WARNING : MobileDeviceMgr::onBrowseDeactivate : pas de handler défini");
				
				MySystem.forceFPS( DEACTIVATE_FPS);
				
				tmpDeactivateSnd			= SoundMixer.soundTransform;
				SoundMixer.soundTransform	= new SoundTransform( 0);
			}
		}
		
		/**
		 * on capture la fin d'attente de désactivation pour quitter l'appli
		 * @param	pE	event de fin d'attente
		 */
		protected function onDeactivateComplete( pE : TimerEvent) : void { exit();}
		
		/**
		 * listener d'event de réactivation d'application
		 * @param	pE	event de réactivation
		 */
		protected function onBrowseReactivate( pE : Event) : void {
			if( _isDeactivate){
				_isDeactivate				= false;
				
				if ( exitTimer != null) {
					exitTimer.removeEventListener( TimerEvent.TIMER_COMPLETE, onDeactivateComplete);
					exitTimer.stop();
					
					exitTimer = null;
				}
				
				MySystem.restaureFPS();
				
				SoundMixer.soundTransform	= tmpDeactivateSnd;
				
				if ( _deviceCurRenderMgr != null) _deviceCurRenderMgr.onBrowseReactivate();
				else trace( "WARNING : MobileDeviceMgr::onBrowseReactivate : pas de handler défini");
			}
		}
		
		/**
		 * listener d'event de navigation arrière (ex.: bouton back sous android)
		 * @param	pE	event de navigation arrière
		 */
		protected function onBrowseBack( pE : KeyboardEvent) : void {
			if( ! isLocked()){
				if ( _deviceCurRenderMgr != null) _deviceCurRenderMgr.onBrowseBack( pE);
				else trace( "WARNING : MobileDeviceMgr::onBrowseBack : pas de handler défini");
			}else {
				CONFIG::AIR {
					if ( pE.keyCode == Keyboard.BACK || pE.keyCode == Keyboard.MENU) {
						pE.preventDefault();
						pE.stopImmediatePropagation();
					}
				}
			}
		}
		
		/**
		 * on définit le mode d'interaction tactil
		 */
		protected function setTouchMode() : void { Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;}
		
		/**
		 * on enregistre les events de navigation autour de l'appli
		 */
		protected function registerBrowseEvents() : void {
			CONFIG::Mobile {
				NativeApplication.nativeApplication.addEventListener( Event.DEACTIVATE, onBrowseDeactivate);
				NativeApplication.nativeApplication.addEventListener( Event.ACTIVATE, onBrowseReactivate);
				NativeApplication.nativeApplication.addEventListener( KeyboardEvent.KEY_DOWN, onBrowseBack, false, 0, true);
			}
			
			if ( ! isMobile()) {
				_stage.addEventListener( Event.DEACTIVATE, onBrowseDeactivate);
				_stage.addEventListener( Event.ACTIVATE, onBrowseReactivate);
			}
		}
		
		/**
		 * on détermine quelle est la déformation à appliquer à l'application pour matcher la taille de l'écran de jeu ; calcul de propriétés définissant cette déformation
		 */
		protected function defineBaseScale() : void {
			var lFullW	: Number	= screenWidth;
			var lFullH	: Number	= screenHeight;
			var lNewW	: Number	= lFullW;
			var lNewH	: Number	= lFullW * _stageHeight / _stageWidth;
			var lScale	: Number;
			
			if ( lNewH > lFullH) {
				lNewW	= lFullH * _stageWidth  / _stageHeight;
				lNewH	= lFullH;
			}
			
			_baseScale				= lNewW / _stageWidth;
			_mobileFullscreenRect	= new Rectangle(
				Math.max( ( ( _stageWidth * _baseScale - lFullW) / 2) / _baseScale, ( _stageWidth - MAX_WIDTH) / 2),
				Math.max( ( ( _stageHeight * _baseScale - lFullH) / 2) / _baseScale, ( _stageHeight - MAX_HEIGHT) / 2),
				Math.min( lFullW / _baseScale, MAX_WIDTH),
				Math.min( lFullH / _baseScale, MAX_HEIGHT)
			);
			
			MySystem.traceDebug( String( _baseScale));
		}
	}
}