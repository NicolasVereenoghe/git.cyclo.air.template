package net.cyclo.mysprite {
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.cyclo.mycam.MyCamera;
	import net.cyclo.shell.MySystem;
	import net.cyclo.template.game.IGameMgr;
	import net.cyclo.utils.UtilsMovieClip;
	
	public class MySpriteMgr {
		protected var container						: DisplayObjectContainer			= null;
		
		protected var defaultContainer				: DisplayObjectContainer			= null;
		
		protected var GROUNDS_LVL					: Object							= {};	// layers invisibles : <I:int>:true
		
		protected var NB_DECOR_FOREGROUND			: int								= 1;
		
		protected var grounds						: Object							= null;
		
		protected var _sprites						: Object							= null;
		protected var spFrames						: Object							= null;
		protected var pauses						: Object							= null;
		
		protected var _gMgr							: IGameMgr							= null;
		protected var _camera						: MyCamera							= null;
		
		protected var WIND_INCLUDE_I				: Object							= {};	// layers qui subissent le "vent" : <ID:String>:true
		
		protected var _windMgr						: WindManager						= null;
		
		protected var SPRITE_RADIX					: String							= "sp";
		
		protected var ctrSprite						: int								= 0;
		
		protected var _ctrTime						: int								= 0;
		protected var _ctrFrame						: int								= 0;
		protected var _isPause						: Boolean							= false;
		
		/** identifiant de level, ou null si level par défaut */
		protected var _lvlId						: String							= null;
		
		/**
		 * construction : on spécifie un identifiant de level pour construire la vua
		 * @param	pLvlId	indentifiant de niveau, ou laisser null ou "" pour prendre le level par défaut
		 */
		public function MySpriteMgr( pLvlId : String = null) {
			if ( pLvlId != null && pLvlId != "") _lvlId = pLvlId;
		}
		
		/**
		 * getter d'identifiant de level
		 * @return	identifiant de level ou null si level par défaut
		 */
		public function get lvlId() : String { return _lvlId; }
		
		public function init( pContainer : DisplayObjectContainer, pGMgr : IGameMgr, pCamera : MyCamera) : void {
			container			= pContainer;
			_gMgr				= pGMgr;
			_camera				= pCamera;
			_sprites			= new Object();
			spFrames			= new Object();
			pauses				= new Object();
			
			initGrounds();
			
			initContainers();
		}
		
		public function setInitView() : void {
			var lGround	: GroundMgr;
			
			container.x			= _camera.x;
			container.y			= _camera.y;
			
			_windMgr.initView( _camera.x, _camera.y);
			
			for each( lGround in grounds) lGround.setInitView();
		}
		
		public function destroy() : void {
			var lList	: Object	= new Object();
			var lId		: String;
			
			for ( lId in _sprites) lList[ lId] = _sprites[ lId];
			for ( lId in lList) {
				if( _sprites[ lId]) remSpriteDisplay( lList[ lId] as MySprite);
			}
			_sprites = null;
			
			freeGrounds();
			
			freeContainers();
			
			spFrames	= null;
			pauses		= null;
			container	= null;
			_gMgr		= null;
			_camera		= null;
		}
		
		public function get ctrTime() : int { return _ctrTime; }
		public function get ctrFrame() : int { return _ctrFrame; }
		public function get isPause() : Boolean { return _isPause; }
		
		public function get camera() : MyCamera { return _camera; }
		public function get gMgr() : IGameMgr { return _gMgr; }
		public function get windMgr() : WindManager { return _windMgr; }
		public function get sprites() : Object { return pauses; }
		
		/**
		 * on ajoute un sprite au level en lui créant une cellule de description dans un plan de level
		 * @param	pGroundId		identifiant de plan de level où ajouter le nouveau sprite
		 * @param	pDepth			profondeur du sprite
		 * @param	pX				abscisse du sprite
		 * @param	pY				ordonnée du sprite
		 * @param	pCellOffset		rectangle d'offsets d'indices du sprite
		 * @param	pSpID			identifiant de sprite ; laisser null si non défini, /!\ on doit du coup forcément définir la classe
		 * @param	pSpClass		sous-classe de MySprite qui gère ce sprite ; laisser null pour aller chercher la classe dans le descripteur d'asset désigné par pSpID
		 * @param	pInstanceID		identifiant d'instance de sprite ; null pour avoir un nom automatique
		 * @param	pMtrx			matrice de transformation à appliquer au sprite ; null si aucune
		 * @param	pForceDisplay	true pour forcer l'affichage du sprite sans test de clipping ; false pour afficher uniquement si test de clipping ok
		 * @return	la cellule de sprite créée
		 */
		public function addSpriteCell( pGroundId : String, pDepth : Number, pX : Number, pY : Number, pCellOffset : Rectangle, pSpID : String = null, pSpClass : Class = null, pInstanceID : String = null, pMtrx : Matrix = null, pForceDisplay : Boolean = false) : MyCellDesc {
			return ( grounds[ pGroundId] as GroundMgr).addSpriteCell( pDepth, pX, pY, pCellOffset, pSpID, pSpClass, pInstanceID, pMtrx, pForceDisplay);
		}
		
		public function remSpriteCell( pDesc : MyCellDesc) : void {
			( grounds[ pDesc.lvlGroundMgr.id] as GroundMgr).remSpriteCell( pDesc);
		}
		
		public function getSpriteCell( pDesc : MyCellDesc, pIJ : Point = null) : Array {
			return ( grounds[ pDesc.lvlGroundMgr.id] as GroundMgr).getSpriteCell( pDesc, pIJ);
		}
		
		/**
		 * on enregistre un sprite à l'itération de frame
		 * @param	pSp	sprite itéré à la frame
		 */
		public function regSpFrame( pSp : MySpFrame) : void { spFrames[ pSp.name] = pSp;}
		
		/**
		 * on retire un sprite de l'itération de frame
		 * @param	pSp	sprite itéré à la frame
		 */
		public function remSpFrame( pSp : MySpFrame) : void {
			if( spFrames[ pSp.name]){
				spFrames[ pSp.name] = null;
				delete spFrames[ pSp.name];
			}
		}
		
		public function addSpriteDisplay( pSp : MySprite, pX : Number, pY : Number, pID : String = null, pDesc : MyCellDesc = null) : void {
			if ( pDesc != null && pDesc.lvlGroundMgr != null) {
				( grounds[ pDesc.lvlGroundMgr.id] as GroundMgr).addSpriteDisplay( pSp, pX, pY, pID, pDesc);
			}else {
				ctrSprite++;
				
				pSp.x		= pX;
				pSp.y		= pY;
				pSp.name	= pID == null ? SPRITE_RADIX + ctrSprite : pID;
				
				_sprites[ pSp.name] = pSp;
				
				addSpToContainer( pSp);
				
				pSp.init( this, pDesc);
			}
			
			pauses[ pSp.name] = pSp;
		}
		
		public function remSpriteDisplay( pSp : MySprite) : void {
			pauses[ pSp.name] = null;
			delete pauses[ pSp.name];
			
			if ( pSp.desc != null && pSp.desc.lvlGroundMgr != null) {
				( grounds[ pSp.desc.lvlGroundMgr.id] as GroundMgr).remSpriteDisplay( pSp);
			}else {
				UtilsMovieClip.clearFromParent( pSp);
				
				pSp.destroy();
				
				_sprites[ pSp.name] = null;
				delete _sprites[ pSp.name];
			}
		}
		
		public function getSprite( pName : String) : MySprite { return _sprites[ pName]; }
		
		/**
		 * on récupère un plan du moteur de sprites
		 * @param	pGID	identifiant de plan
		 * @return	réf sur le plan de sprites
		 */
		public function getGround( pGID : String) : GroundMgr { return grounds[ pGID]; }
		
		public function getSpGround( pSp : MySprite) : GroundMgr {
			if ( pSp.desc != null && pSp.desc.lvlGroundMgr != null) return grounds[ pSp.desc.lvlGroundMgr.id];
			else return null;
		}
		
		public function doesWindIgnoreGround( pId : String) : Boolean { return WIND_INCLUDE_I[ pId] != true; }
		
		public function doFrame( pDT : int) : void {
			var lSps		: Object		= new Object();
			var lSp			: MySpFrame;
			var lId			: String;
			
			_ctrTime += pDT;
			_ctrFrame++;
			
			slideToCamera();
			
			for ( lId in spFrames) lSps[ lId] = spFrames[ lId];
			for each( lSp in lSps) {
				if( spFrames[ lSp.name]) lSp.doFrame();
			}
		}
		
		public function switchPause( pIsPause : Boolean) : void {
			var lPauses	: Object	= new Object();
			var lId		: String;
			var lSp		: MySprite;
			
			_isPause = pIsPause;
			
			for ( lId in pauses) lPauses[ lId] = pauses[ lId];
			for each( lSp in lPauses) lSp.switchPause( pIsPause);
		}
		
		protected function slideToCamera() : void {
			var lGround	: GroundMgr;
			
			container.x		= _camera.x;
			container.y		= _camera.y;
			
			_windMgr.slideView( _camera.x, _camera.y);
			
			for each( lGround in grounds) lGround.slideToCamera( _windMgr.getNUpdateView( lGround));
		}
		
		protected function initContainers() : void { defaultContainer = container.addChild( new Sprite()) as DisplayObjectContainer; }
		
		protected function freeContainers() : void {
			UtilsMovieClip.clearFromParent( defaultContainer);
			defaultContainer = null;
		}
		
		protected function addSpToContainer( pSp : MySprite) : void { defaultContainer.addChild( pSp); }
		
		protected function freeGrounds() : void {
			var lId		: String;
			
			_windMgr.destroy();
			_windMgr = null;
			
			for ( lId in grounds) ( grounds[ lId] as GroundMgr).destroy();
			
			grounds = null;
		}
		
		/**
		 * on construit et initialise tous les plans d'affichage qui constituent ce gestionnaire de sprite du level ::_lvlId
		 */
		protected function initGrounds() : void {
			var lI			: int			= 0;
			var lLvlGround	: LvlGroundMgr	= LvlMgr.getInstance().getLvlGroundMgr( 0, _lvlId);
			
			grounds		= new Object();
			_windMgr	= instanciateWindMgr();
			
			while ( lLvlGround != null) {
				grounds[ lLvlGround.id] = addGround( lI, lLvlGround);
				
				if( ! doesWindIgnoreGround( lLvlGround.id)) _windMgr.pushGround( grounds[ lLvlGround.id]);
				
				lLvlGround = LvlMgr.getInstance().getLvlGroundMgr( ++lI, _lvlId);
			}
		}
		
		/**
		 * on instancie un gestionnaire de plan d'affichage, et ajoute au conteneur d'affichage (::container) le conteneur de ce plan
		 * appelé par ordre de profondeur des plans qui constituent ce gestionnaire de sprites (de derrière à devant)
		 * @param	pI			indice de profondeur du plan d'affichage ( 0 .. n-1)
		 * @param	pLvlGround	gestionnaire de matrice de données du plan d'affichage
		 * @return	instance de plan d'affichage créée
		 */
		protected function addGround( pI : int, pLvlGround : LvlGroundMgr) : GroundMgr {
			var lCont	: DisplayObjectContainer	= container.addChild( new Sprite()) as DisplayObjectContainer;
			var lIsV	: Boolean					= ( GROUNDS_LVL[ pI] == undefined);
			
			if ( pLvlGround.IS_NO_DEPTH) return new GroundMgrNoDepth( lCont, pLvlGround, this, lIsV);
			else if ( pLvlGround.IS_FRONT_GROUND) return new GroundMgrFront( lCont, pLvlGround, this, lIsV);
			else return new GroundMgr( lCont, pLvlGround, this, lIsV);
		}
		
		protected function instanciateWindMgr() : WindManager { return new WindManager(); }
	}
}