package net.cyclo.mysprite {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.getQualifiedClassName;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsSystem;
	
	public class LvlGroundMgr {
		protected var CELL_MAX_SIZE						: Number						= 100;
		protected var CELL_MIN_SIZE						: Number						= 50;
		
		protected var _CELLS_PER_W						: int							= -1;
		protected var _CELLS_PER_H						: int							= -1;
		
		protected var _COEF_PARALLAXE					: Number						= 1;
		
		/** map de cellules en cours : [ <i modulo: int>][ <j modulo: int>][ <racine id instance: String>] = MyCellDesc */
		protected var cells								: Object						= null;
		protected var ctrCells							: int							= 0;
		
		/** pile de clones de cellule de la map en cours */
		protected var restoreCells						: Array							= null;
		
		protected var _CELL_W							: Number						= -1;
		protected var _CELL_H							: Number						= -1;
		
		protected var GROUND_W							: Number						= -1;
		protected var GROUND_H							: Number						= -1;
		
		protected var _id								: String						= null;
		protected var _lvlId							: String						= null;
		
		protected var _IS_FRONT_GROUND					: Boolean						= false;
		protected var _IS_CYCLE_GROUND					: Boolean						= false;
		/** flag indiquant si le plan décrit n'a aucune gestion de profondeur (true), ou par défaut si ça gère (false) */
		protected var _IS_NO_DEPTH						: Boolean						= false;
		
		public function LvlGroundMgr( pId : String, pLvlId : String, pTmp : DisplayObjectContainer = null) {
			cells			= new Object();
			restoreCells	= new Array();
			_lvlId			= pLvlId;
			
			if ( pId != null) _id = pId;
			if ( pTmp != null) parseLvlGroundTemplate( pTmp);
		}
		
		/**
		 * on restaure la map de cellules comme à l'origine, à partir de ::restoreCells ; on vire l'ancienne map
		 */
		public function reset() : void {
			var lCopy	: Object;
			var lI		: String;
			var lJ		: String;
			var lId		: String;
			var lN		: int;
			
			MySystem.traceDebug( "INFO : LvlGroundMgr::reset : " + _id);
			
			for ( lI in cells) {
				for ( lJ in cells[ lI]) {
					lCopy = new Object();
					
					for ( lId in cells[ lI][ lJ]) lCopy[ lId] = cells[ lI][ lJ][ lId];
					for ( lId in lCopy) remCell( lCopy[ lId] as MyCellDesc);
				}
			}
			
			cells		= new Object();
			ctrCells	= 0;
			
			for ( lN = 0 ; lN < restoreCells.length ; lN++) addCell( ( restoreCells[ lN] as MyCellDesc).clone());
		}
		
		/**
		 * on compte le nombre de cellules décrivant un sprite dont on précise la classe, dans le modèle originale
		 * @param	pClass	classe de sprite cherché
		 * @return	nombre de cellules de ce type trouvées dans le modèle original
		 */
		public function countSpType( pClass : Class) : int {
			var lCtr	: int	= 0;
			var lI		: int;
			
			for ( lI = 0 ; lI < restoreCells.length ; lI++) {
				if ( UtilsSystem.doesInherit( ( restoreCells[ lI] as MyCellDesc).spClass, pClass)) lCtr++;
			}
			
			return lCtr;
		}
		
		/**
		 * on récupère une pile de descripteurs de cellules correspondant à la classe de sprite recherchée, parmi les cellules sauvegardées du level initial
		 * @param	classe de sprite cherché
		 * @return	pile de descripteurs correspondants
		 */
		public function getCellsType( pClass : Class) : Array {
			var lRes	: Array	= new Array();
			var lI		: int;
			
			for ( lI = 0 ; lI < restoreCells.length ; lI++){
				if ( UtilsSystem.doesInherit( ( restoreCells[ lI] as MyCellDesc).spClass, pClass)) lRes.push( restoreCells[ lI]);
			}
			
			return lRes;
		}
		
		public function getCellsAt( pModI : int, pModJ : int) : Object {
			if ( ! cells[ pModI]) return {};
			else if ( ! cells[ pModI][ pModJ]) return {};
			else return cells[ pModI][ pModJ];
		}
		
		public function createCell( pDepth : Number, pX : Number, pY : Number, pCellOffset : Rectangle, pSpID : String = null, pSpClass : Class = null, pInstanceID : String = null, pMtrx : Matrix = null) : MyCellDesc {
			var lModX	: Number		= x2ModX( pX);
			var lModY	: Number		= y2ModY( pY);
			var lI		: int			= x2i( lModX);
			var lJ		: int			= y2j( lModY);
			var lCell	: MyCellDesc	= new MyCellDesc(
				lI,
				lJ,
				lModX - _CELL_W * lI,
				lModY - _CELL_H * lJ,
				pDepth,
				pCellOffset,
				this,
				pInstanceID != null ? pInstanceID : _id + ctrCells,
				pSpID,
				pSpClass,
				pMtrx
			);
			
			addCell( lCell);
			
			return lCell;
		}
		
		public function addCell( pCell : MyCellDesc) : void {
			var lOffset	: Rectangle	= pCell.cellOffset;
			var lMaxI	: int		= lOffset.right + pCell.i;
			var lMaxJ	: int		= lOffset.bottom + pCell.j;
			var lModI	: int;
			var lModJ	: int;
			var lI		: int;
			var lJ		: int;
			
			ctrCells++;
			
			for ( lI = lOffset.left + pCell.i ; lI <= lMaxI ; lI++) {
				lModI	= i2ModI( lI);
				
				if ( ! cells[ lModI]) cells[ lModI] = new Object();
				
				for ( lJ = lOffset.top + pCell.j ; lJ <= lMaxJ ; lJ++) {
					lModJ	= j2ModJ( lJ);
					
					if ( ! cells[ lModI][ lModJ]) cells[ lModI][ lModJ] = new Object();
					
					cells[ lModI][ lModJ][ pCell.instanceId] = pCell;
				}
			}
		}
		
		public function remCell( pCell : MyCellDesc) : void {
			remCellRef( pCell);
			
			pCell.destroy();
		}
		
		public function moveCell( pCell : MyCellDesc, pToXY : Point) : void {
			var lModX	: Number		= x2ModX( pToXY.x);
			var lModY	: Number		= y2ModY( pToXY.y);
			var lI		: int			= x2i( lModX);
			var lJ		: int			= y2j( lModY);
			
			remCellRef( pCell);
			
			addCell( pCell);
		}
		
		public function getGroundOffset( pI : int, pJ : int) : Point {
			if ( _IS_CYCLE_GROUND) return new Point( Math.floor( pI / _CELLS_PER_W), Math.floor( pJ / _CELLS_PER_H));
			else return new Point();
		}
		
		public function getCellGroundOffsetsFrom( pModI : int, pModJ : int, pCell : MyCellDesc) : Rectangle {
			var lOffset	: Rectangle	= pCell.cellOffset;
			var lLeft	: int		= Math.ceil( ( pModI - ( pCell.i + lOffset.right)) / _CELLS_PER_W);
			var lTop	: int		= Math.ceil( ( pModJ - ( pCell.j + lOffset.bottom)) / _CELLS_PER_H);
			var lRight	: int		= Math.floor( ( pModI - ( pCell.i + lOffset.left)) / _CELLS_PER_W);
			var lBot	: int		= Math.floor( ( pModJ - ( pCell.j + lOffset.top)) / _CELLS_PER_H);
			
			if ( lLeft > lRight || lTop > lBot) return null;
			else return new Rectangle( lLeft, lTop, lRight - lLeft, lBot - lTop);
		}
		
		public function get id() : String { return _id; }
		public function get lvlId() : String { return _lvlId; }
		public function get COEF_PARALLAXE() : Number { return _COEF_PARALLAXE; }
		public function get CELL_W() : Number { return _CELL_W; }
		public function get CELL_H() : Number { return _CELL_H; }
		public function get CELLS_PER_W() : Number { return _CELLS_PER_W; }
		public function get CELLS_PER_H() : Number { return _CELLS_PER_H; }
		public function get IS_FRONT_GROUND() : Boolean { return _IS_FRONT_GROUND; }
		public function get IS_CYCLE_GROUND() : Boolean { return _IS_CYCLE_GROUND; }
		public function get IS_NO_DEPTH() : Boolean { return _IS_NO_DEPTH; }
		
		public function x2i( pX : Number) : int { return Math.floor( pX / _CELL_W); }
		public function y2j( pY : Number) : int { return Math.floor( pY / _CELL_H); }
		
		public function x2ModI( pX : Number) : int {
			if ( _IS_CYCLE_GROUND) return i2ModI( x2i( pX));
			else return x2i( pX);
		}
		
		public function y2ModJ( pY : Number) : int {
			if ( _IS_CYCLE_GROUND) return j2ModJ( y2j( pY));
			else return y2j( pY);
		}
		
		public function i2ModI( pI : int) : int {
			if ( _IS_CYCLE_GROUND) return ( ( pI % _CELLS_PER_W) + _CELLS_PER_W) % _CELLS_PER_W;
			else return pI;
		}
		
		public function j2ModJ( pJ : int) : int {
			if ( _IS_CYCLE_GROUND) return ( ( pJ % _CELLS_PER_H) + _CELLS_PER_H) % _CELLS_PER_H;
			else return pJ;
		}
		
		/**
		 * on crée un rectangle d'offset d'indices à partir d'une bounding box de sprite
		 * @param	pRect	bounding box de sprite
		 * @return	rectangle d'offsets d'indices
		 */
		public function getCellOffsetFromRect( pRect : Rectangle) : Rectangle {
			var lFromI	: int	= Math.floor( pRect.left / _CELL_W);
			var lFromJ	: int	= Math.floor( pRect.top / _CELL_H);
			
			return new Rectangle(
				lFromI,
				lFromJ,
				Math.ceil( pRect.right / _CELL_W) - lFromI,
				Math.ceil( pRect.bottom / _CELL_H) - lFromJ
			);
		}
		
		protected function parseLvlGroundTemplate( pTmp : DisplayObjectContainer) : void {
			var lCadre		: DisplayObject		= pTmp.getChildByName( "mcCadre");
			var lTxtCoef	: TextField			= pTmp.getChildByName( "txtCoefParallaxe") as TextField;
			var lTxtIsFront	: TextField			= pTmp.getChildByName( "txtIsFront") as TextField;
			var lTxtIsNoD	: TextField			= pTmp.getChildByName( "txtIsNoD") as TextField;
			var lD			: int;
			var lContent	: DisplayObject;
			
			if ( lTxtCoef != null) _COEF_PARALLAXE	= parseFloat( lTxtCoef.text);
			if ( lTxtIsFront != null) _IS_FRONT_GROUND = ( parseInt( lTxtIsFront.text) == 1);
			if ( lTxtIsNoD != null && parseInt( lTxtIsNoD.text) == 1) {
				_IS_NO_DEPTH		= true;
				_IS_FRONT_GROUND	= false;
			}
			
			if ( lCadre != null) {
				_IS_CYCLE_GROUND	= true;
				
				GROUND_W			= lCadre.width;
				GROUND_H			= lCadre.height;
				
				_CELLS_PER_W		= Math.floor( GROUND_W / Math.max( CELL_MAX_SIZE * _COEF_PARALLAXE, CELL_MIN_SIZE));
				_CELLS_PER_H		= Math.floor( GROUND_H / Math.max( CELL_MAX_SIZE * _COEF_PARALLAXE, CELL_MIN_SIZE));
				
				_CELL_W				= GROUND_W / _CELLS_PER_W;
				_CELL_H				= GROUND_H / _CELLS_PER_H;
			}else {
				_IS_CYCLE_GROUND	= false;
				
				GROUND_W			= GROUND_H = Number.POSITIVE_INFINITY;
				_CELLS_PER_W		= _CELLS_PER_H = int.MAX_VALUE;
				_CELL_W				= _CELL_H = Math.max( CELL_MAX_SIZE * _COEF_PARALLAXE, CELL_MIN_SIZE);
			}
			
			for ( lD = 0 ; lD < pTmp.numChildren ; lD++) {
				lContent	= pTmp.getChildAt( lD);
				
				if ( lContent is MovieClip && Object( lContent).constructor != MovieClip) {
					restoreCells.push(
						onCellParsed( createCell(
							lD,
							lContent.x,
							lContent.y,
							getCellOffsetFromRect( MySprite.getClipRectFromAssetContent( lContent as DisplayObjectContainer)),
							getQualifiedClassName( lContent),
							null,
							_id + lContent.name,
							lContent.transform.matrix
						)).clone()
					);
				}
			}
		}
		
		/**
		 * hook : on capte une cellule après son enregistrement lors du parsing du level
		 * @param	pCell	cellule enregistrée
		 * @return	cette même cellule
		 */
		protected function onCellParsed( pCell : MyCellDesc) : MyCellDesc { return LvlMgr.getInstance().onCellParsed( pCell); }
		
		protected function x2ModX( pX : Number) : Number {
			if ( _IS_CYCLE_GROUND) return ( ( pX % ( GROUND_W)) + GROUND_W) % GROUND_W;
			else return pX;
		}
		
		protected function y2ModY( pY : Number) : Number {
			if ( _IS_CYCLE_GROUND) return ( ( pY % ( GROUND_H)) + GROUND_H) % GROUND_H;
			else return pY;
		}
		
		/**
		 * on retire les références vers la cellule de description de sprite de la matrice
		 * @param	pCell	cellule de description dont on retire la réf
		 */
		protected function remCellRef( pCell : MyCellDesc) : void {
			var lOffset	: Rectangle	= pCell.cellOffset;
			var lMaxI	: int		= lOffset.right + pCell.i;
			var lMaxJ	: int		= lOffset.bottom + pCell.j;
			var lModI	: int;
			var lModJ	: int;
			var lI		: int;
			var lJ		: int;
			
			for ( lI = lOffset.left + pCell.i ; lI <= lMaxI ; lI++) {
				lModI	= i2ModI( lI);
				
				for ( lJ = lOffset.top + pCell.j ; lJ <= lMaxJ ; lJ++) {
					lModJ	= j2ModJ( lJ);
					
					if( cells[ lModI][ lModJ][ pCell.instanceId]){
						cells[ lModI][ lModJ][ pCell.instanceId] = null;
						delete cells[ lModI][ lModJ][ pCell.instanceId];
					}
				}
			}
		}
	}
}