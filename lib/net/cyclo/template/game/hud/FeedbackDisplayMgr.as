package net.cyclo.template.game.hud {
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.template.game.IGameMgr;
	import net.cyclo.template.screen.ScreenDisplay;
	import net.cyclo.utils.UtilsMovieClip;
	import net.cyclo.utils.UtilsSystem;
	
	/**
	 * gestionnaire de petites pop-in temporaires qui s'empilent, pour faire un feed back rapide en jeu
	 * gestion de 2 types dans la même display list de manière indépendante  : Feedback "classique" pour les chaînes, FeedbackPush pour des event de type push
	 * 
	 * @author nico
	 */
	public class FeedbackDisplayMgr extends Sprite {
		/** gestionnaire de jeu utilisé pour signaler la fin d'une pop in */
		protected var mgr												: IGameMgr												= null;
		
		/** nombre max de chaîne qu'on gère */
		protected var _maxNbChain										: int													= 7;
		
		/** pile de params de feedback exclusifs de push temporisés, indexés du plus prioritaire vers le plus récent : { evtId : String, chainStep : int, val : int, altClass : Class, dispConfig : ScreenDisplay} */
		protected var tmpFeedbackPush									: Array													= null;
		
		/**
		 * on récupère le nombre de chaînes max gérées par l'affichage
		 * @return	nombre de chaînes max
		 */
		public function get maxNbChain() : int { return _maxNbChain; }
		
		/**
		 * constructeur
		 */
		public function FeedbackDisplayMgr() { super(); }
		
		/**
		 * initialisation, sans affichage
		 * @param	pMgr		gestionnaire de jeu utilisé pour signaler le score en différé
		 * @param	pMaxChain	nombre max de chaînes gérées par l'affichage, laisser -1 pour valeur par défaut
		 */
		public function init( pMgr : IGameMgr, pMaxChain : int = -1) : void {
			mgr				= pMgr;
			tmpFeedbackPush	= new Array();
			
			if ( pMaxChain > 0) _maxNbChain = pMaxChain;
			// TODO !!
		}
		
		/**
		 * destruction
		 */
		public function destroy() : void {
			reset();
			
			mgr = null;
			tmpFeedbackPush = null;
		}
		
		/**
		 * on démarre le gestionnaire, suite à un ::init ou un ::reset
		 */
		public function start() : void {
			// TODO !!
		}
		
		/**
		 * on réinitialise le gestionnaire pour qu'il soit à nouveau dispo comme à l'init
		 */
		public function reset() : void {
			var lFeed	: Feedback;
			
			while ( numChildren > 0) {
				lFeed = getChildAt( 0) as Feedback;
				
				lFeed.destroy();
				
				UtilsMovieClip.clearFromParent( lFeed);
			}
			
			tmpFeedbackPush = new Array();
		}
		
		/**
		 * on signale le changement d'orientation du device
		 */
		public function updateRotContent() : void {
			var lI		: int;
			
			for ( lI = numChildren - 1 ; lI >= 0 ; lI--) ( getChildAt( lI) as Feedback).updateScreenDisplay();
		}
		
		/**
		 * on demande le pop d'une popin
		 * @param	pEvtId			identifiant d'event de jeu ; prévu comme identifiant de feedback de chaîne / combo
		 * @param	pChainStep		étape de chaîne [ 0 .. n-1] ; la valeur sera majorée par le nombre max de chaînes gérées par l'affichage ( ::_maxNbChain)
		 * @param	pVal			valeur entière associé à l'évent ; prévue pour un score
		 * @param	pAltClass		classe alternative de feedback, doit dériver de Feedback ; laisser null pour utiliser Feedback
		 * @param	pIsExclusive	une popin exclusive ferme toute les autres précédentes, sinon mettre false pour permettre l'empilement
		 * @param	pDispConfig		config d'affichage écran ; null pour config par défaut au centre
		 */
		public function pop( pEvtId : String = null, pChainStep : int = 0, pVal : int = 0, pAltClass : Class = null, pIsExclusive : Boolean = true, pDispConfig : ScreenDisplay = null) : void {
			var lRect		: Rectangle	= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			var lInstance	: Feedback;
			var lI			: int;
			
			pChainStep = Math.min( pChainStep, _maxNbChain - 1);
			
			if ( pAltClass != null && UtilsSystem.doesInherit( pAltClass, FeedbackPush)) {
				if ( pIsExclusive && ( isFeedbackPushInDisplay() || tmpFeedbackPush.length > 0)) {
					tmpFeedbackPush.push( {
						evtId: pEvtId,
						chainStep: pChainStep,
						val: pVal,
						altClass: pAltClass,
						dispConfig: pDispConfig
					});
					
					return;
				}
				
				lInstance = new ( pAltClass)() as Feedback;
			}else{
				if ( pIsExclusive) {
					lI = 0;
					
					while ( numChildren > lI) {
						lInstance = getChildAt( lI) as Feedback;
						
						if ( lInstance is FeedbackPush) lI++;
						else {
							sendFeedbackEnd( lInstance);
							
							lInstance.destroy();
							
							UtilsMovieClip.clearFromParent( lInstance);
						}
					}
				}
				
				if ( pAltClass != null) lInstance = new ( pAltClass)() as Feedback;
				else lInstance = new Feedback();
			}
			
			addChild( lInstance);
			
			lInstance.init( this, pEvtId, pDispConfig, pChainStep, pVal);
			lInstance.updateScreenDisplay();
		}
		
		/**
		 * on itère le gestionnaire à la frame
		 */
		public function doFrame() : void {
			var lFeed	: Feedback;
			var lI		: int;
			var lParams	: Object;
			
			for ( lI = numChildren - 1 ; lI >= 0 ; lI--) {
				lFeed = getChildAt( lI) as Feedback;
				
				if ( ! lFeed.doFrame()) {
					sendFeedbackEnd( lFeed);
					
					lFeed.destroy();
					
					UtilsMovieClip.clearFromParent( lFeed);
					
					if ( ( lFeed is FeedbackPush) && ( ! isFeedbackPushInDisplay()) && tmpFeedbackPush.length > 0) {
						lParams		= tmpFeedbackPush.shift();
						lFeed		= new ( lParams.altClass as Class)() as Feedback;
						
						addChild( lFeed);
						
						lFeed.init( this, lParams.evtId as String, lParams.dispConfig as ScreenDisplay, lParams.chainStep as int, lParams.val as int);
						lFeed.updateScreenDisplay();
					}
				}
			}
		}
		
		/**
		 * on vérifie si la display list contient un feedback de type push (FeedbackPush)
		 * @return	true si une instance de FeedbackPush trouvée, false sinon
		 */
		protected function isFeedbackPushInDisplay() : Boolean {
			var lI	: int	= 0;
			
			for ( ; lI < numChildren ; lI++) {
				if ( getChildAt( lI) is FeedbackPush) return true;
			}
			
			return false;
		}
		
		/**
		 * on effectue le signalement de fin d'un feedback
		 * @param	pFeed	instance de feedback dont on fait le signalement de fin
		 */
		protected function sendFeedbackEnd( pFeed : Feedback) : void {
			mgr.onFeedbackEnd(
				pFeed.id,
				pFeed.lvl,
				pFeed.val,
				new Point(
					pFeed.x + pFeed.posX * MobileDeviceMgr.getInstance().rotContentCos + pFeed.posY * MobileDeviceMgr.getInstance().rotContentSin,
					pFeed.y + pFeed.posY * MobileDeviceMgr.getInstance().rotContentCos - pFeed.posX * MobileDeviceMgr.getInstance().rotContentSin
				)
			);
		}
	}
}