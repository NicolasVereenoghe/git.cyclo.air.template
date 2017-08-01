package net.cyclo.template.screen {
	import com.greensock.TweenMax;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.template.shell.IShell;
	import net.cyclo.template.shell.ShellDefaultRender;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * écran de GUI du jeu géré par la coque du jeu
	 * @author nico
	 */
	public class MyScreen {
		/** nom de scène du contenu orientable */
		protected var ROT_CONTENT_NAME		: String					= "mcRotContent";
		
		/** identifiant d'asset de menu ; null pour ne pas générer d'instance d'asset */
		protected var ASSET_ID				: String					= null;
		
		/** couleur rgb de fade */
		protected var FADE_RGB				: uint						= 0xffffff;
		/** flag indiquant si on utilise le fade rgb (true) ou pas (false) ; util pour avoir une transition clean vers une couleur quand on a des bitmaps qui gèrent mal l'alpha relatif */
		protected var FADE_RGB_USE			: Boolean					= false;
		
		/** couleur rgb de bg */
		protected var BG_RGB				: uint						= 0xffffff;
		/** flag indiquant si on utilise un bg rgb (true) ou pas (false) */
		protected var BG_RGB_USE			: Boolean					= false;
		
		/** conteneur de fade rgb ; null si pas utilisé */
		protected var fadeRGB				: Sprite					= null;
		
		/** conteneur de bg rgb ; null si pas utilisé */
		protected var bgRGB					: Sprite					= null;
		
		/** asset du menu imbriqué dans le contenu (::content) de l'écran ; null pour pas d'asset de menu */
		protected var menuAsset				: AssetInstance				= null;
		
		/** contenu de l'écran ; gestion de l'orientation automatique et éventuel bg RGB */
		protected var content				: DisplayObjectContainer	= null;
		/** conteneur de l'écran */
		protected var container				: DisplayObjectContainer;
		/** conteneur de contenu qui sera fade alpha */
		protected var alphaContainer		: DisplayObjectContainer	= null;
		
		/** le shell qui gère cet écran */
		protected var shell					: IShell;
		
		/** durée de fade en secondes */
		protected var FADE_DURATION			: Number					= .15;
		/** itérateur de tween du fade ; null si pas actif */
		protected var tweenFade				: TweenMax					= null;
		
		/** instance de prochain écran à ouvrir ; null si non défini */
		protected var nextScreen			: MyScreen					= null;
		
		/**
		 * initialisation de l'écran de GUI ; une fois l'init passée, on répond au shell avec la méthode IShell::onScreenReady
		 * @param	pShell		le gestionnaire de coque responsable de cet écran
		 * @param	pContainer	conteneur de l'écran ; doit être viré au destroy de l'écran
		 */
		public function initScreen( pShell : IShell, pContainer : DisplayObjectContainer) : void {
			var lRect	: Rectangle;
			
			shell		= pShell;
			container	= pContainer;
			
			createContentContainer();
			
			if ( BG_RGB_USE) createBgRGB();
			
			if ( ASSET_ID != null) {
				menuAsset = AssetInstance( content.addChild( AssetsMgr.getInstance().getAssetInstance( ASSET_ID)));
				
				if ( menuAsset.desc.file != null && menuAsset.desc.file.isIMG()) {
					lRect = MobileDeviceMgr.getInstance().mobileFullscreenRect;
					
					menuAsset.x	= ( lRect.left + lRect.right - menuAsset.width) / 2;
					menuAsset.y	= ( lRect.top + lRect.bottom - menuAsset.height) / 2;
				}
			}
			
			buildContent();
			
			updateRotContent();
			
			launchAfterInit();
		}
		
		/**
		 * on démarre l'écran ; il a été initialisé au préalable
		 */
		public function start() : void { MySystem.traceDebug( "INFO : MyScreen::start");}
		
		/**
		 * on demande de fermer l'écran
		 * @param	pNext	instance de prochain écran à ouvrir, ou null si non défini
		 */
		public function askClose( pNext : MyScreen = null) : void { launchFadeOut( pNext); }
		
		/**
		 * on est notifié d'une navigation arrière (ex.: bouton back sous android)
		 * @param	pE	event de navigation arrière
		 */
		public function onBrowseBack( pE : KeyboardEvent) : void { MySystem.traceDebug( "INFO : MyScreen::onBrowseBack");}
		
		/**
		 * on demande à l'écran d'activer / désactiver la pause
		 * @param	pIsPause	true pour passer en pause, false sinon
		 */
		public function switchPause( pIsPause : Boolean) : void {
			MySystem.traceDebug( "INFO : MyScreen::switchPause : " + pIsPause);
			
			if ( tweenFade != null) {
				if ( pIsPause && ! tweenFade.paused) tweenFade.pause();
				else if ( tweenFade.paused && ! pIsPause) tweenFade.resume();
			}
		}
		
		/**
		 * on réoriente le contenu orientable de la fenêtre si le le device a été tourné
		 */
		public function updateRotContent() : void {
			var lContent	: DisplayObject	= getRotContent();
			
			if ( lContent != null) lContent.rotation = MobileDeviceMgr.getInstance().rotContent;
		}
		
		/**
		 * destruction, libération mémoire
		 */
		public function destroy() : void {
			if( tweenFade != null) {
				tweenFade.kill();
				
				tweenFade	= null;
			}
			
			if( menuAsset != null){
				UtilsMovieClip.clearFromParent( menuAsset);
				menuAsset.free();
				menuAsset	= null;
			}
			
			freeBgRGB();
			
			freeContentContainer();
			
			freeFadeRGB();
			
			UtilsMovieClip.clearFromParent( container);
			
			nextScreen		= null;
			shell			= null;
			container		= null;
		}
		
		/**
		 * on effectue la construction du contenu de la fenêtre après l'initialisation de sa structure (positionnement)
		 */
		protected function buildContent() : void { MySystem.traceDebug( "INFO : MyScreen::buildContent : void"); }
		
		/**
		 * on effectue la procédure de lancement en fin d'init ; pour l'instant rien ne se passe
		 * redéfinir pour avoir un fade d'ouverture, ou directement dire au shell qu'on est prêt (il est bloqué et attend ce message)
		 */
		protected function launchAfterInit() : void { MySystem.traceDebug( "INFO : MyScreen::launchAfterInit : void"); }
		
		/**
		 * on crée le conteneur de contenu de la fenêtre ; celui-ci est imbriqué pour gérer l'orientation auto
		 */
		protected function createContentContainer() : void {
			var lRot	: DisplayObjectContainer	= new Sprite();
			var lRect	: Rectangle					= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			
			alphaContainer	= container.addChild( new Sprite()) as DisplayObjectContainer;
			lRot.name		= ROT_CONTENT_NAME;
			content			= ( alphaContainer.addChild( lRot) as DisplayObjectContainer).addChild( instanciateContentC()) as DisplayObjectContainer;
			lRot.x			= ( lRect.left + lRect.right) / 2;
			lRot.y			= ( lRect.top + lRect.bottom) / 2;
			content.x		= -lRot.x;
			content.y		= -lRot.y;
		}
		
		/**
		 * on libère le conteneur de contenu de fenêtre
		 */
		protected function freeContentContainer() : void {
			var lRot	: DisplayObjectContainer	= alphaContainer.getChildByName( ROT_CONTENT_NAME) as DisplayObjectContainer;
			
			freeContentC();
			
			UtilsMovieClip.clearFromParent( lRot);
			
			UtilsMovieClip.clearFromParent( alphaContainer);
			alphaContainer = null;
		}
		
		/**
		 * on crée l'instance de contenu d'écran ; util à surcharger pour capter les message d'AutoAsset
		 * @return	contenu d'écran (conteneur)
		 */
		protected function instanciateContentC() : DisplayObjectContainer { return new Sprite(); }
		
		/**
		 * on libère le contenu ; util à surcharger si on a défini un capteur de message d'AutoAsset
		 */
		protected function freeContentC() : void {
			UtilsMovieClip.clearFromParent( content);
			content = null;
		}
		
		/**
		 * on récupère le contenu orientable ; l'asset peut définir un contenu orientable à la place de celui créé par défaut, si c'est le cas on utilise celui-là
		 * @return	contenu orientable, ou null si aucun
		 */
		protected function getRotContent() : DisplayObject {
			var lContent	: DisplayObject;
			
			if ( menuAsset != null && menuAsset.content is DisplayObjectContainer) {
				lContent	= ( menuAsset.content as DisplayObjectContainer).getChildByName( ROT_CONTENT_NAME);
				
				if ( lContent != null) return lContent;
			}
			
			return alphaContainer.getChildByName( ROT_CONTENT_NAME);
		}
		
		/**
		 * on crée le graphisme de bg RGB
		 */
		protected function createBgRGB() : void {
			var lRect	: Rectangle	= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			
			bgRGB = alphaContainer.addChildAt( new Sprite(), 0) as Sprite;
			
			bgRGB.graphics.beginFill( BG_RGB);
			bgRGB.graphics.drawRect( lRect.left, lRect.top, lRect.width, lRect.height);
			bgRGB.graphics.endFill();
		}
		
		/**
		 * on libère le bg RGB si il existe
		 */
		protected function freeBgRGB() : void {
			if ( bgRGB != null) {
				bgRGB.graphics.clear();
				
				UtilsMovieClip.clearFromParent( bgRGB);
				bgRGB = null;
			}
		}
		
		/**
		 * on crée le graphisme de fade rgb
		 */
		protected function createFadeRGB() : void {
			var lRect	: Rectangle	= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			
			fadeRGB	= container.addChild( new Sprite()) as Sprite;
			
			fadeRGB.graphics.beginFill( FADE_RGB);
			fadeRGB.graphics.drawRect( lRect.left, lRect.top, lRect.width, lRect.height);
			fadeRGB.graphics.endFill();
		}
		
		/**
		 * on libère le conteneur de fade rgb si celui-ci est défini
		 */
		protected function freeFadeRGB() : void {
			if ( fadeRGB != null) {
				fadeRGB.graphics.clear();
				UtilsMovieClip.clearFromParent( fadeRGB);;
				fadeRGB = null;
			}
		}
		
		/**
		 * on récupère un enfant que l'on cherche dans le contenu orientable, sinon dans l'asset du menu, sinon il n'existe pas
		 * @param	pName	nom de l'enfant recherché
		 * @return	l'enfant ou null si n'existe pas
		 */
		protected function getMenuChildByName( pName : String) : DisplayObject {
			var lContent	: DisplayObject	= getRotContent();
			
			if ( lContent != null && lContent is DisplayObjectContainer) {
				lContent = ( lContent as DisplayObjectContainer).getChildByName( pName);
				
				if ( lContent != null) return lContent;
			}
			
			if ( menuAsset != null && menuAsset.content is DisplayObjectContainer) {
				return ( menuAsset.content as DisplayObjectContainer).getChildByName( pName);
			}
			
			return null;
		}
		
		/**
		 * on lance la transition d'ouverture en fade in
		 */
		protected function launchFadeIn() : void {
			alphaContainer.alpha = 0;
			
			if ( FADE_RGB_USE) {
				createFadeRGB();
				fadeRGB.alpha = 0;
				
				tweenFade = TweenMax.to(
					fadeRGB,
					FADE_DURATION,
					{
						alpha: 1,
						onComplete: onFadeInRGBComplete
					}
				);
			}else{
				tweenFade = TweenMax.to(
					alphaContainer,
					FADE_DURATION,
					{
						alpha: 1,
						onComplete: onFadeInComplete
					}
				);
			}
		}
		
		/**
		 * call back de fin de transition de fade in rgb
		 */
		protected function onFadeInRGBComplete() : void {
			alphaContainer.alpha = 1;
			
			tweenFade = TweenMax.to(
				fadeRGB,
				FADE_DURATION,
				{
					alpha: 0,
					onComplete: onFadeInComplete
				}
			);
		}
		
		/**
		 * call back de fin de transition d'ouverture
		 */
		protected function onFadeInComplete() : void {
			freeFadeRGB();
			
			tweenFade	= null;
			
			shell.onScreenReady( this);
		}
		
		/**
		 * on lance la transition de fermeture en fade out
		 * @param	pNext	instance de prochain écran à ouvrir, ou null si non défini
		 */
		protected function launchFadeOut( pNext : MyScreen = null) : void {
			nextScreen = pNext;
			
			if ( FADE_RGB_USE) {
				createFadeRGB();
				fadeRGB.alpha = 0;
				
				tweenFade = TweenMax.to(
					fadeRGB,
					FADE_DURATION,
					{
						alpha: 1,
						onComplete: onFadeOutRGBComplete
					}
				);
			}else{
				tweenFade = TweenMax.to(
					alphaContainer,
					FADE_DURATION,
					{
						alpha: 0,
						onComplete: onFadeOutComplete
					}
				);
			}
			
			shell.onScreenClose( this, nextScreen);
		}
		
		/**
		 * call back de fin de transition de fade out rgb
		 */
		protected function onFadeOutRGBComplete() : void {
			alphaContainer.alpha = 0;
			
			tweenFade = TweenMax.to(
				fadeRGB,
				FADE_DURATION,
				{
					alpha: 0,
					onComplete: onFadeOutComplete
				}
			);
		}
		
		/**
		 * call back de fin de fade out
		 */
		protected function onFadeOutComplete() : void {
			tweenFade	= null;
			
			shell.onScreenEnd( this);
		}
	}
}