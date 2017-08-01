package net.cyclo.mysprite {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * classe de base d'un sprite d'un plan de sprites géré par un gestionnaire de sprites (voir net.cyclo.mysprite.MySpriteMgr)
	 * 
	 * @author	nico
	 */
	public class MySprite extends Sprite {
		/** le gestionnaire de sprite en charge de ce sprite */
		protected var mgr								: MySpriteMgr						= null;
		/** descripteur de sprite, null si pas défini pour des sprites sans cellule de référencement */
		protected var _desc								: MyCellDesc						= null;
		
		/** instance d'asset du sprite */
		protected var assetSp							: AssetInstance						= null;
		
		/** flag indiquant si le sprite est inactif (true) ou actif (true) */
		protected var isInactive						: Boolean							= false;
		
		/**
		 * on récupère la boite englobante du contenu de l'asset d'un sprite
		 * @param	pContent	contenu de l'asset d'un sprite
		 * @return	rectangle de la boite englobante du sprite, relatif au sprite (et pas au plan de sprites)
		 */
		public static function getClipRectFromAssetContent( pContent : DisplayObjectContainer) : Rectangle {
			var lZone	: DisplayObject	= getClip( pContent);
			var lRect	: Rectangle;
			
			if ( lZone != null) {
				if ( pContent.parent is AssetInstance) {
					lRect	= lZone.getRect( pContent.parent.parent.parent);
					lRect.x	-= pContent.parent.parent.x;
					lRect.y -= pContent.parent.parent.y;
				}else{
					lRect	= lZone.getRect( pContent.parent);
					lRect.x	-= pContent.x;
					lRect.y	-= pContent.y;
				}
				
				return lRect;
			}else return new Rectangle();
		}
		
		public function init( pMgr : MySpriteMgr, pDesc : MyCellDesc = null) : void {
			mgr		= pMgr;
			_desc	= pDesc;
			
			initAssetSp();
		}
		
		/**
		 * on libère l'instance de sprite
		 */
		public function destroy() : void {
			if ( assetSp != null) freeAssetSp();
			
			if ( _desc != null) {
				_desc.freeInstance( this);
				_desc = null;
			}
			
			mgr = null;
		}
		
		/**
		 * on rend le sprite inactif, par exemple il ne devrait plus réagir aux effets
		 */
		public function setInactive() : void { isInactive = true; }
		
		/**
		 * on vérifie si on peut cliper le sprite, et donc si il peut virer de l'affichage car hors écran
		 * @return	true si peut être clipé, false si verrouillé à l'affichage
		 */
		public function isClipable() : Boolean { return true; }
		
		/**
		 * un autre sprite demande résoudre un effet d'interaction
		 * @param	pSp		sprite à l'origine de la demande d'effet
		 * @param	pXY		coordonnées de scène de jeu du contact de l'interaction ; null si pas défini
		 * @param	pGXY	coordonnées globales du contact de l'interaction ; null si pas défini
		 * @return	true si l'effet est résolu, false si non résolu et pourrait faire l'objet d'autres appels à d'autres coordonnées pour voir si ça le résoud
		 */
		public function doEffect( pSp : MySprite, pXY : Point = null, pGXY : Point = null) : Boolean { return true; }
		
		/**
		 * on teste la collision d'un point de contact d'un autre sprite
		 * @param	pSp		le sprite qui demande le test de collision
		 * @param	pGXY	coordonnées globales du point de contact
		 * @param	pXY		coordonnées relatives à plan du sprite, peut être obligatoire suivant l'implémentation du jeu
		 * @return	true si on touche notre instance, false sinon
		 */
		public function testBounce( pSp : MySprite, pGXY : Point, pXY : Point = null) : Boolean { return false; }
		
		public function get desc() : MyCellDesc { return _desc; }
		
		public function get unwindedPos() : Point { return new Point( x, y).add( mgr.windMgr.getGroundOffset( mgr.getSpGround( this))); }
		
		public function getSpDHint( pGrndMgr : GroundMgr, pDHint : Number) : Number { return pDHint; }
		
		public function switchPause( pIsPause : Boolean) : void { }
		
		/**
		 * on récupère la zone qui délimite la zone de clip du sprite
		 * @param	pContent	contenu de l'asset d'un sprite
		 * @return	zone délimitant le clip du sprite, null si pas définie
		 */
		protected static function getClip( pContent : DisplayObjectContainer) : DisplayObject { return pContent.getChildByName( "mcClip"); }
		
		/**
		 * on construit l'instance d'asset du sprite
		 */
		protected function initAssetSp() : void {
			if ( _desc != null) assetSp = addChild( AssetsMgr.getInstance().getAssetInstance( _desc.spId)) as AssetInstance;
		}
		
		/**
		 * on libère l'asset du sprite
		 */
		protected function freeAssetSp() : void {
			assetSp.free();
			UtilsMovieClip.clearFromParent( assetSp);
			assetSp = null;
		}
		
		/**
		 * on retourne le descripteur de plan où rechercher à résoudre les effets
		 * @return	descripteur de plan, null si non défini
		 */
		protected function getEffectLvlGround() : LvlGroundMgr {
			if ( desc != null) return desc.lvlGroundMgr;
			else return null;
		}
		
		/**
		 * on recherche à résoudre toutes les interactions avec les autres sprites ; si le le sprite est inactif, la recherche s'arrête
		 * par défaut on recherche tout ce qu'il y a de référencé sous les coordonnées du sprite
		 */
		protected function seekEffect() : void {
			var lLvl	: LvlGroundMgr	= getEffectLvlGround();
			var lXY		: Point			= new Point( x, y);
			var lGXY	: Point			= parent.localToGlobal( lXY);
			var lIJ		: Point			= new Point( lLvl.x2i( x), lLvl.y2j( y));
			var lCells	: Object		= lLvl.getCellsAt( lLvl.x2ModI( x), lLvl.y2ModJ( y));
			var lCell	: MyCellDesc;
			var lSps	: Array;
			var lSp		: MySprite;
			var lI		: int;
			
			for each( lCell in lCells) {
				lSps	= mgr.getSpriteCell( lCell, lIJ);
				
				for ( lI = 0 ; lI < lSps.length && ! isInactive ; lI++) {
					lSp = lSps[ lI];
					
					if( lSp != this) lSp.doEffect( this, lXY, lGXY);
				}
			}
		}
	}
}