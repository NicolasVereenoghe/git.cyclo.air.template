package net.cyclo.template.game.hud {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.template.screen.ScreenDisplay;
	import net.cyclo.ui.MyCounter;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * un feed back de jeu
	 * 
	 * @author nico
	 */
	public class Feedback extends Sprite {
		/** identifiant d'asset de feedback par défaut */
		protected var ASSET_ID										: String													= "feedback";
		
		/** délai de l'anim d'apparition en frames */
		protected var OPEN_ANIM_DELAY								: int														= 10;
		/** degré de progression du nombre max de frames de l'anim en fonction du lvl de chaîne */
		protected var ANIM_GROW_DEG									: Number													= 1.2;
		/** délai d'attente avec tout d'affiché en frames */
		protected var WAIT_DELAY									: int														= 45;
		
		/** pourcentage de total de nombre de chaîne pour majorer le calcul de frame de départ */
		protected var MIN_FRAME_TOTAL_RATE							: Number													= .38;
		
		/** nombre total de frames lues dans l'anim d'ouverture */
		protected var animTotalFrames								: int														= 0;
		
		/** gestionnaire feedback responsable de cette instance */
		protected var mgr											: FeedbackDisplayMgr										= null;
		
		/** identifiant d'event de jeu ; prévu comme identifiant de feedback de chaîne / combo */
		protected var _id											: String													= null;
		/** niveau de chaîne / combo [ 0 .. n-1] */
		protected var _lvl											: int														= 0;
		/** valeur entière associé à l'évent ; prévue pour un score */
		protected var _val											: int														= 0;
		
		/** config d'affichage écran ; null si pas défini ou pour config par défaut au centre */
		protected var dispConfig									: ScreenDisplay												= null;
		
		/** compteur d'état du feedback */
		protected var ctr											: int														= 0;
		
		/** asset du feedback */
		protected var asset											: AssetInstance												= null;
		
		/** composant de score */
		protected var score											: MyCounter													= null;
		/** 2ème compteur pour effet d'affichage ; null si pas utilisé */
		protected var score2										: MyCounter													= null;
		
		/**
		 * récupère l'id de feedback
		 * @return	id de feedback, null si rien de défini
		 */
		public function get id() : String { return _id; }
		
		/**
		 * niveau de chaîne
		 * @return	niveau [ 0 .. n-1]
		 */
		public function get lvl() : int { return _lvl; }
		
		/**
		 * récupère la valeur entière associée au feedback
		 * @return	valeur assoicée, 0 si rien d edéfini
		 */
		public function get val() : int { return _val; }
		
		/**
		 * éloignement du contenu en x par rapport à l'origine
		 * @return	distance en x
		 */
		public function get posX() : Number { return getPos() != null ? getPos().x : 0; }
		
		/**
		 * éloignement du contenu en y par rapport à l'origine
		 * @return	distance en y
		 */
		public function get posY() : Number { return getPos() != null ? getPos().y : 0; }
		
		/**
		 * construction
		 */
		public function Feedback() { super(); }
		
		/**
		 * initialisation
		 * @param	pMgr		gestionnaire feedback responsable de cette instance
		 * @param	pEvtId		identifiant d'event de jeu ; prévu comme identifiant de feedback de chaîne / combo ; si null on prend valeur par défaut
		 * @param	pDispConfig	config d'affichage écran ; null pour config par défaut au centre
		 * @param	pChainStep	étape de chaîne [ 0 .. n-1] ; la valeur sera majorée par le nombre max de chaînes gérées par l'affichage ( ::_maxNbChain)
		 * @param	pVal		valeur entière associé à l'évent ; prévue pour un score
		 */
		public function init( pMgr : FeedbackDisplayMgr, pEvtId : String = null, pDispConfig : ScreenDisplay = null, pChainStep : int = 0, pVal : int = 0) : void {
			mgr			= pMgr;
			_lvl		= pChainStep;
			_val		= pVal;
			dispConfig	= pDispConfig;
			
			if ( pEvtId != null) _id = pEvtId;
			else _id = ASSET_ID;
			
			buildContent();
		}
		
		/**
		 * destruction
		 */
		public function destroy() : void {
			score.destroy();
			score = null;
			
			if ( score2 != null) {
				score2.destroy();
				score2 = null;
			}
			
			UtilsMovieClip.clearFromParent( asset);
			asset.free();
			asset = null;
			
			mgr = null;
		}
		
		/**
		 * on demande une mise à jour de l'affichage écran, suite à l'init ou à un changement d'orientation
		 */
		public function updateScreenDisplay() : void { ScreenDisplay.doPos( this, dispConfig); }
		
		/**
		 * itération d'affichage de frame
		 * @return	true si l'affichage continue, false si le feedback se finit et qu'il doit être retiré
		 */
		public function doFrame() : Boolean {
			if ( ++ctr < OPEN_ANIM_DELAY) {
				getMcAnim().gotoAndStop( Math.round( ( ctr / OPEN_ANIM_DELAY) * ( animTotalFrames - 1)) + 1);
				if ( getMcAnim2() != null) getMcAnim2().gotoAndStop( getMcAnim().currentFrame);
			}else if ( ctr < OPEN_ANIM_DELAY + WAIT_DELAY) {
				getContent().visible = true;
				
				getMcAnim().gotoAndStop( animTotalFrames);
				if ( getMcAnim2() != null) getMcAnim2().gotoAndStop( animTotalFrames);
			}else return false;
			
			return true;
		}
		
		/**
		 * on construit le contenu du feedback
		 */
		protected function buildContent() : void {
			asset = addChild( AssetsMgr.getInstance().getAssetInstance( _id + _lvl)) as AssetInstance;
			
			animTotalFrames = getTotalFramesAtStep( _lvl);
			
			getContent().visible = false;
			getMcAnim().gotoAndStop( 1);
			if ( getMcAnim2() != null) getMcAnim2().gotoAndStop( 1);
			
			score = new MyCounter( getScoreContent(), _val);
			if( getScoreContent2() != null) score2 = new MyCounter( getScoreContent2(), _val);
		}
		
		/**
		 * 
		 * @param	pStepI	étape de chaîne [ 0 .. n-1]
		 * @return	frame de rendu max sur la time line de l'anim
		 */
		protected function getTotalFramesAtStep( pStepI : int) : int {
			var lTotal	: int	= getMcAnim().totalFrames;
			var lMinFr	: int	= Math.round( ( lTotal - 1) * 1 / ( mgr.maxNbChain * MIN_FRAME_TOTAL_RATE)) + 1;
			var lDeltFr	: int	= lTotal - lMinFr;
			
			return lMinFr + Math.round( lDeltFr * Math.pow( pStepI / ( mgr.maxNbChain - 1), ANIM_GROW_DEG));
		}
		
		/**
		 * on récupère le conteneur du contenu affiché, hors anim de bg ; ce contenu est invisible tant que anim pas finie
		 * @return	conteneur de contenu affiché hors bg (mcScore + txt divers)
		 */
		protected function getContent() : DisplayObjectContainer { return ( asset.content as DisplayObjectContainer).getChildByName( "mcContent") as DisplayObjectContainer; }
		
		/**
		 * on récupère le conteneur de score dans le contenu
		 * @return	conteneur score
		 */
		protected function getScoreContent() : DisplayObjectContainer { return getContent().getChildByName( "mcScore") as DisplayObjectContainer; }
		
		/**
		 * on récupère le conteneur de score 2 dans le contenu
		 * @return	conteneur score 2, null si pas présent
		 */
		protected function getScoreContent2() : DisplayObjectContainer { return getContent().getChildByName( "mcScore2") as DisplayObjectContainer; }
		
		/**
		 * on récupère une réf sur l'anim d'apparition du feedback
		 * @return	time line d'anime
		 */
		protected function getMcAnim() : MovieClip { return ( asset.content as DisplayObjectContainer).getChildByName( "mcAnim") as MovieClip; }
		
		/**
		 * on récupère une réf sur l'anim doublée d'apparition du feedback
		 * @return	time line d'anime, ou null si pas définie
		 */
		protected function getMcAnim2() : MovieClip { return ( asset.content as DisplayObjectContainer).getChildByName( "mcAnim2") as MovieClip; }
		
		/**
		 * on récupère une réf sur le clip de position du contenu dans le repère centré
		 * @return	clip de position, null si pas défini
		 */
		protected function getPos() : DisplayObject { return ( asset.content as DisplayObjectContainer).getChildByName( "mcPos"); }
	}
}