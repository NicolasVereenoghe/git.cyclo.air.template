package net.cyclo.mysprite {
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;
	import net.cyclo.assets.AssetsMgr;
	
	/**
	 * descripteur d'un sprite de plan de clipping
	 * 
	 * @author	nico
	 */
	public class MyCellDesc {
		protected var _i								: int								= 0;
		protected var _j								: int								= 0;
		protected var _dx								: Number							= 0;
		protected var _dy								: Number							= 0;
		protected var _mtrx								: Matrix							= null;
		protected var _dHint							: int								= 0;
		protected var _cellOffset						: Rectangle							= null;
		protected var _instanceId						: String							= null;
		protected var _spId								: String							= null;
		protected var _spClass							: Class								= null;
		protected var _lvlGroundMgr						: LvlGroundMgr						= null;
		
		/** collection d'instances de sprites actifs de la cellule ; indexés par instance même de MySprite */
		protected var _sprites							: Dictionary						= null;
		
		/** map de données persistantes de ce descripteur de sprite, valeurs de type String indexée par id de donnée */
		protected var datas								: Object							= null;
		
		public function get i() : int { return _i; }
		public function get j() : int { return _j; }
		public function get dx() : Number { return _dx; }
		public function get dy() : Number { return _dy; }
		public function get mtrx() : Matrix { return _mtrx; }
		public function get dHint() : Number { return _dHint; }
		public function get cellOffset() : Rectangle { return _cellOffset; }
		public function get instanceId() : String { return _instanceId; }
		public function get spId() : String { return _spId; }
		public function get spClass() : Class { return _spClass; }
		public function get lvlGroundMgr() : LvlGroundMgr { return _lvlGroundMgr; }
		
		/**
		 * accès à la collection d'instances actives de cette cellule
		 * @return	collection de sprites
		 */
		public function get sprites() : Dictionary { return _sprites; }
		
		public function MyCellDesc( pI : int, pJ : int, pDX : Number, pDY : Number, pD : int, pCellOffset : Rectangle, pLvlGroundMgr : LvlGroundMgr, pInstanceId : String = null, pSpId : String = null, pSpClass : Class = null, pMtrx : Matrix = null) {
			_i				= pI;
			_j				= pJ;
			_dx				= pDX;
			_dy				= pDY;
			_dHint			= pD;
			_cellOffset		= pCellOffset;
			_instanceId		= pInstanceId;
			_spId			= pSpId;
			_spClass		= pSpClass != null ? pSpClass : ApplicationDomain.currentDomain.getDefinition( AssetsMgr.getInstance().getAssetDescById( pSpId).getData( "spClass")) as Class;
			_lvlGroundMgr	= pLvlGroundMgr;
			_mtrx			= pMtrx;
			
			datas			= new Object();
			
			_sprites		= new Dictionary();
		}
		
		public function clone() : MyCellDesc {
			var lDesc	: MyCellDesc	= new MyCellDesc(
				_i,
				_j,
				_dx,
				_dy,
				_dHint,
				_cellOffset.clone(),
				_lvlGroundMgr,
				_instanceId,
				_spId,
				_spClass,
				_mtrx.clone()
			);
			
			lDesc.cloneDatas( datas);
			
			return lDesc;
		}
		
		/**
		 * on met à jour la position du sprite décrit
		 * @param	pI	nouvel indice i de cellule de référencement
		 * @param	pJ	nouvel indice j de cellule de référencement
		 * @param	pDX	offset en x de position du sprite par rapport à l'origine de sa cellule
		 * @param	pDY	offset en y de position du sprite par rapport à l'origine de sa cellule
		 */
		public function updatePos( pI : int, pJ : int, pDX : Number, pDY : Number) : void {
			_i	= pI;
			_j	= pJ;
			_dx	= pDX;
			_dy	= pDY;
		}
		
		/**
		 * on crée une instance de sprite décrit par cette cellule, avec la transformation géométrique voulue
		 * attention, l'instance est enregistrée, il faudra la libérer (::freeInstance)
		 * @return	instance de sprite
		 */
		public function instanciate() : MySprite {
			var lSp	: MySprite	= ( new _spClass()) as MySprite;
			
			if ( _mtrx != null) lSp.transform.matrix = _mtrx;
			
			_sprites[ lSp] = lSp;
			
			return lSp;
		}
		
		/**
		 * on libère une instance de sprite précédemment créée depuis ::instanciate
		 */
		public function freeInstance( pSp : MySprite) : void {
			_sprites[ pSp] = null;
			delete _sprites[ pSp];
		}
		
		public function destroy() : void {
			_cellOffset		= null;
			_spClass		= null;
			_lvlGroundMgr	= null;
			_mtrx			= null;
			
			datas			= null;
			
			_sprites		= null;
		}
		
		/**
		 * on clone une source de données persistante de cellule
		 * @param	pDatas	données persistantes brutes à cloner
		 */
		public function cloneDatas( pDatas : Object) : void {
			var lId	: String;
			
			for ( lId in pDatas) datas[ lId] = pDatas[ lId];
		}
		
		/**
		 * on sauvegarde des données persistantes pour ce descripteur de sprite
		 * @param	pKey	identifiant de données
		 * @param	pVal	valeur de données
		 */
		public function setData( pKey : String, pVal : String) : void { datas[ pKey] = pVal; }
		
		/**
		 * on récupère une valeur persistante à partir de sa clef
		 * @param	pKey	identifiant de données
		 * @return	valeur associée, null si pas défini
		 */
		public function getData( pKey : String) : String { return datas[ pKey]; }
	}
}