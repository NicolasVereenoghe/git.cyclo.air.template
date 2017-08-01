package net.cyclo.mysprite {
	import flash.display.DisplayObjectContainer;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.cyclo.display.DepthMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMovieClip;
	
	public class GroundMgr {
		public static var REVEAL_ALPHA_PER_FRAME	: Number								= .027;
		
		protected var NB_CELLS_W					: int									= -1;
		protected var NB_CELLS_H					: int									= -1;
		
		protected var COEF_P						: Number								= 0;
		
		protected var container						: DisplayObjectContainer				= null;
		protected var _lvlGround					: LvlGroundMgr							= null;
		protected var spMgr							: MySpriteMgr							= null;
		
		protected var depthMgr						: DepthMgr								= null;
		
		protected var sprites						: Object								= null;
		
		protected var curI							: int									= 0;
		protected var curJ							: int									= 0;
		
		protected var isReverse						: Boolean								= false;
		
		protected var clipRectIn					: Function								= null;
		protected var clipRectOut					: Function								= null;
		
		public var addSpriteCell					: Function								= null;
		public var remSpriteCell					: Function								= null;
		
		public var getSpriteCell					: Function								= null;
		
		public function GroundMgr( pContainer : DisplayObjectContainer, pLvlGround : LvlGroundMgr, pSpMgr : MySpriteMgr, pVisible : Boolean = true) {
			_lvlGround	= pLvlGround;
			spMgr		= pSpMgr;
			
			if ( _lvlGround.IS_CYCLE_GROUND) {
				clipRectIn		= clipRectInCycle;
				clipRectOut		= clipRectOutCycle;
				
				addSpriteCell	= addSpriteCellCycle;
				remSpriteCell	= remSpriteCellCycle;
				
				getSpriteCell	= getSpriteCellCycle;
			}else {
				clipRectIn		= clipRectInRegular;
				clipRectOut		= clipRectOutRegular;
				
				addSpriteCell	= addSpriteCellRegular;
				remSpriteCell	= remSpriteCellRegular;
				
				getSpriteCell	= getSpriteCellRegular;
			}
			
			buildContainer( pContainer);
			
			COEF_P		= _lvlGround.COEF_PARALLAXE - 1;
			
			sprites		= new Object();
			
			procNbCells();
			
			container.visible = pVisible;
		}
		
		/**
		 * on effectue le calcul du gabarit des nombres de cellules nécessaires pour englober l'écran
		 */
		protected function procNbCells() : void {
			NB_CELLS_W	= Math.floor( spMgr.camera.SCREEN_W / _lvlGround.CELL_W) + 2;
			NB_CELLS_H	= Math.floor( spMgr.camera.SCREEN_H / _lvlGround.CELL_H) + 2;
		}
		
		public function destroy() : void {
			var lList	: Object	= new Object();
			var lId		: String;
			
			for ( lId in sprites) lList[ lId] = sprites[ lId];
			for ( lId in lList) spMgr.remSpriteDisplay( lList[ lId] as MySprite);
			sprites = null;
			
			freeContainer();
			
			_lvlGround.reset();
			
			_lvlGround	= null;
			spMgr		= null;
		}
		
		public function get lvlGround() : LvlGroundMgr { return _lvlGround; }
		
		/**
		 * on récupère une réf sur le conteneur des sprites de ce plan
		 * @return	réf sur conteneur
		 */
		public function get gContainer() : DisplayObjectContainer { return container; }
		
		public function reveal() : void {
			if ( ! container.visible) {
				container.visible = true;
				container.alpha = 0;
			}
			
			isReverse = false;
		}
		
		public function hide() : void {
			if ( container.visible) isReverse = true;
		}
		
		public function updateSpDepth( pSp : MySprite, pDHint : Number) : void { depthMgr.updateDepth( pSp, pDHint); }
		
		public function addSpriteCellRegular( pDepth : Number, pX : Number, pY : Number, pCellOffset : Rectangle, pSpID : String = null, pSpClass : Class = null, pInstanceID : String = null, pMtrx : Matrix = null, pForceDisplay : Boolean = false) : MyCellDesc {
			var lCell			: MyCellDesc	= _lvlGround.createCell( pDepth, pX, pY, pCellOffset, pSpID, pSpClass, pInstanceID, pMtrx);
			var lCellClipRIJ	: Rectangle		= lCell.cellOffset.clone();
			var lClipRIJ		: Rectangle		= new Rectangle( curI, curJ, NB_CELLS_W - 1, NB_CELLS_H - 1);
			var lI				: int			= _lvlGround.x2i( pX);
			var lJ				: int			= _lvlGround.y2j( pY);
			
			lCellClipRIJ.offset( lI, lJ);
			
			if ( pForceDisplay || lClipRIJ.left <= lCellClipRIJ.right && lClipRIJ.right >= lCellClipRIJ.left && lClipRIJ.top <= lCellClipRIJ.bottom && lClipRIJ.bottom >= lCellClipRIJ.top) {
				spMgr.addSpriteDisplay(
					lCell.instanciate(),
					pX,
					pY,
					lCell.instanceId,
					lCell
				);
			}
			
			return lCell;
		}
		
		public function addSpriteCellCycle( pDepth : Number, pX : Number, pY : Number, pCellOffset : Rectangle, pSpID : String = null, pSpClass : Class = null, pInstanceID : String = null, pMtrx : Matrix = null, pForceDisplay : Boolean = false) : MyCellDesc {
			var lCell			: MyCellDesc	= _lvlGround.createCell( pDepth, pX, pY, pCellOffset, pSpID, pSpClass, pInstanceID, pMtrx);
			var lOffsets		: Rectangle		= getCellCameraOffsets( lCell);
			var lGroundOffset	: Point;
			var lOffset			: Point;
			var lI				: int;
			var lJ				: int;
			
			if ( lOffsets != null) {
				lGroundOffset	= _lvlGround.getGroundOffset( curI, curJ);
				
				for ( lI = lOffsets.left ; lI <= lOffsets.right ; lI++) {
					for ( lJ = lOffsets.top ; lJ <= lOffsets.bottom ; lJ++) {
						lOffset	= lGroundOffset.add( new Point( lI, lJ));
						
						spMgr.addSpriteDisplay(
							lCell.instanciate(),
							( lOffset.x * _lvlGround.CELLS_PER_W + lCell.i) * _lvlGround.CELL_W + lCell.dx,
							( lOffset.y * _lvlGround.CELLS_PER_H + lCell.j) * _lvlGround.CELL_H + lCell.dy,
							getInstanceQualifiedGroundName( lCell, lOffset),
							lCell
						);
					}
				}
			}
			
			return lCell;
		}
		
		public function remSpriteCellCycle( pDesc : MyCellDesc) : void {
			var lOffsets		: Rectangle		= getCellCameraOffsets( pDesc);
			var lGroundOffset	: Point;
			var lI				: int;
			var lJ				: int;
			
			if ( lOffsets != null) {
				lGroundOffset	= _lvlGround.getGroundOffset( curI, curJ);
				
				for ( lI = lOffsets.left ; lI <= lOffsets.right ; lI++) {
					for ( lJ = lOffsets.top ; lJ <= lOffsets.bottom ; lJ++) {
						spMgr.remSpriteDisplay( sprites[ getInstanceQualifiedGroundName( pDesc, lGroundOffset.add( new Point( lI, lJ)))] as MySprite);
					}
				}
			}
			
			_lvlGround.remCell( pDesc);
		}
		
		public function remSpriteCellRegular( pDesc : MyCellDesc) : void {
			if ( sprites[ pDesc.instanceId]) spMgr.remSpriteDisplay( sprites[ pDesc.instanceId] as MySprite);
			
			_lvlGround.remCell( pDesc);
		}
		
		public function getSpriteCellRegular( pDesc : MyCellDesc, pIJ : Point = null) : Array {
			if ( sprites[ pDesc.instanceId]) return [ sprites[ pDesc.instanceId]];
			else return [];
		}
		
		public function getSpriteCellCycle( pDesc : MyCellDesc, pIJ : Point = null) : Array {
			var lOffsets		: Rectangle	= _lvlGround.getCellGroundOffsetsFrom( _lvlGround.i2ModI( pIJ.x), _lvlGround.j2ModJ( pIJ.y), pDesc);
			var lGroundOffset	: Point		= _lvlGround.getGroundOffset( pIJ.x, pIJ.y);
			var lRes			: Array		= new Array();
			var lI				: int;
			var lJ				: int;
			var lName			: String;
			
			for ( lI = lOffsets.left ; lI <= lOffsets.right ; lI++) {
				for ( lJ = lOffsets.top ; lJ <= lOffsets.bottom ; lJ++) {
					lName	= getInstanceQualifiedGroundName( pDesc, lGroundOffset.add( new Point( lI, lJ)));
					
					if ( sprites[ lName]) lRes.push( sprites[ lName]);
				}
			}
			
			return lRes;
		}
		
		public function addSpriteDisplay( pSp : MySprite, pX : Number, pY : Number, pID : String, pDesc : MyCellDesc) : void {
			pSp.x			= pX;
			pSp.y			= pY;
			pSp.name		= pID;
			
			sprites[ pID]	= pSp;
			
			addSpToContainer( pSp, pDesc.dHint);
			
			pSp.init( spMgr, pDesc);
		}
		
		public function remSpriteDisplay( pSp : MySprite) : void {
			pSp.destroy();
			
			remSpFromContainer( pSp);
			
			sprites[ pSp.name]	= null;
			delete sprites[ pSp.name];
		}
		
		public function setInitView() : void {
			var lClipR			: Rectangle		= spMgr.camera.clipRect.clone();
			var lDX				: Number		= -spMgr.camera.screenMidX * COEF_P;
			var lDY				: Number		= -spMgr.camera.screenMidY * COEF_P;
			var lI				: int;
			var lJ				: int;
			
			lClipR.x		-= lDX;
			lClipR.y		-= lDY;
			
			container.x		= lDX;
			container.y		= lDY;
			
			curI			= _lvlGround.x2i( lClipR.left);
			curJ			= _lvlGround.y2j( lClipR.top);
			
			clipRectIn( curI, curJ, NB_CELLS_W, NB_CELLS_H);
		}
		
		public function getCurCamClipR() : Rectangle {
			var lClipR	: Rectangle		= spMgr.camera.clipRect.clone();
			
			lClipR.x	-= container.x;
			lClipR.y	-= container.y;
			
			return lClipR;
		}
		
		public function slideToCamera( pOffset : Point) : void {
			var lClipR			: Rectangle		= spMgr.camera.clipRect.clone();
			var lDX				: Number		= -spMgr.camera.screenMidX * COEF_P + pOffset.x * ( COEF_P + 1);
			var lDY				: Number		= -spMgr.camera.screenMidY * COEF_P + pOffset.y * ( COEF_P + 1);
			var lOldNbCellsW	: int			= NB_CELLS_W;
			var lOldNbCellsH	: int			= NB_CELLS_H;
			var lClipRIJ		: Rectangle;
			var lINew			: int;
			var lJNew			: int;
			var lDI				: int;
			var lDJ				: int;
			
			procNbCells();
			
			lClipR.x		-= lDX;
			lClipR.y		-= lDY;
			
			container.x		= lDX;
			container.y		= lDY;
			
			lINew			= _lvlGround.x2i( lClipR.left);
			lJNew			= _lvlGround.y2j( lClipR.top);
			lClipRIJ		= new Rectangle( lINew, lJNew, NB_CELLS_W - 1, NB_CELLS_H - 1);
			
			lDI = lINew - curI;
			if ( lDI > 0) {
				clipRectOut( curI, curJ, Math.min( lDI, lOldNbCellsW), lOldNbCellsH, lClipRIJ);
			}else if ( lDI < 0) {
				clipRectIn( lINew, lJNew, Math.min( -lDI, NB_CELLS_W), NB_CELLS_H);
			}
			
			lDI = ( lINew + NB_CELLS_W) - ( curI + lOldNbCellsW);
			if ( lDI > 0){
				clipRectIn( Math.max( curI + lOldNbCellsW, lINew), lJNew, Math.min( lDI, NB_CELLS_W), NB_CELLS_H);
			}else if ( lDI < 0){
				clipRectOut( Math.max( curI, lINew + NB_CELLS_W), curJ, Math.min( -lDI, lOldNbCellsW), lOldNbCellsH, lClipRIJ);
			}
			
			if ( lINew < curI + lOldNbCellsW && curI < lINew + NB_CELLS_W){
				lDI = Math.min( curI + lOldNbCellsW, lINew + NB_CELLS_W) - Math.max( curI, lINew);
				
				lDJ = lJNew - curJ;
				if ( lDJ > 0) {
					clipRectOut( Math.max( curI, lINew), curJ, lDI, Math.min( lDJ, lOldNbCellsH), lClipRIJ);
				}else if ( lDJ < 0) {
					clipRectIn( Math.max( curI, lINew), lJNew, lDI, Math.min( -lDJ, NB_CELLS_H));
				}
				
				lDJ = ( lJNew + NB_CELLS_H) - ( curJ + lOldNbCellsH);
				if ( lDJ > 0) {
					clipRectIn( Math.max( curI, lINew), Math.max( curJ + lOldNbCellsH, lJNew), lDI, Math.min( lDJ, NB_CELLS_H));
				}else if ( lDJ < 0) {
					clipRectOut( Math.max( curI, lINew), Math.max( lJNew + NB_CELLS_H, curJ), lDI, Math.min( -lDJ, lOldNbCellsH), lClipRIJ);
				}
			}
			
			curI			= lINew;
			curJ			= lJNew;
			
			doReveal();
		}
		
		protected function doReveal() : void {
			if ( container.visible) {
				if ( isReverse) {
					if ( container.alpha > 0) container.alpha -= REVEAL_ALPHA_PER_FRAME;
					else container.visible = false;
				}else {
					if( container.alpha < 1) container.alpha += REVEAL_ALPHA_PER_FRAME;
				}
			}
		}
		
		protected function buildContainer( pContainer : DisplayObjectContainer) : void {
			container	= pContainer;
			depthMgr	= new DepthMgr( container);
		}
		
		protected function freeContainer() : void {
			UtilsMovieClip.clearFromParent( container);
			container	= null;
			depthMgr	= null;
		}
		
		protected function addSpToContainer( pSp : MySprite, pDHint : Number) : void {
			container.addChild( pSp);
			depthMgr.setDepth( pSp, pSp.getSpDHint( this, pDHint));
		}
		
		protected function remSpFromContainer( pSp : MySprite) : void {
			depthMgr.freeDepth( pSp);
			UtilsMovieClip.clearFromParent( pSp);
		}
		
		protected function clipRectOutRegular( pI : int, pJ : int, pW : int, pH : int, pClipRIJ : Rectangle) : void {
			var lDone			: Object		= new Object();
			var lIMax			: int			= pI + pW;
			var lJMax			: int			= pJ + pH;
			var lI				: int			= pI;
			var lJ				: int;
			var lDescs			: Object;
			var lDesc			: MyCellDesc;
			var lCellClipRIJ	: Rectangle;
			var lSp				: MySprite;
			
			for ( ; lI < lIMax ; lI++) {
				for ( lJ = pJ ; lJ < lJMax ; lJ++) {
					lDescs	= _lvlGround.getCellsAt( lI, lJ);
					
					for each( lDesc in lDescs) {
						if ( ! lDone[ lDesc.instanceId]) {
							lDone[ lDesc.instanceId] = true;
							lSp = sprites[ lDesc.instanceId] as MySprite;
							
							if ( lSp && lSp.isClipable()) {
								lCellClipRIJ	= lDesc.cellOffset.clone();
								lCellClipRIJ.offset( lDesc.i, lDesc.j);
								
								if( pClipRIJ.left > lCellClipRIJ.right || pClipRIJ.right < lCellClipRIJ.left || pClipRIJ.top > lCellClipRIJ.bottom || pClipRIJ.bottom < lCellClipRIJ.top){
									spMgr.remSpriteDisplay( lSp);
								}
							}
						}
					}
				}
			}
		}
		
		protected function clipRectOutCycle( pI : int, pJ : int, pW : int, pH : int, pClipRIJ : Rectangle) : void {
			var lDone			: Object		= new Object();
			var lIMax			: int			= pI + pW;
			var lJMax			: int			= pJ + pH;
			var lI				: int			= pI;
			var lJ				: int;
			var lIMod			: int;
			var lJMod			: int;
			var lDescs			: Object;
			var lGroundOffset	: Point;
			var lOffset			: Point;
			var lDesc			: MyCellDesc;
			var lName			: String;
			var lCellClipRIJ	: Rectangle;
			var lOffsets		: Rectangle;
			var lIO				: int;
			var lJO				: int;
			var lSp				: MySprite;
			
			for ( ; lI < lIMax ; lI++) {
				lIMod	= _lvlGround.i2ModI( lI);
				
				for ( lJ = pJ ; lJ < lJMax ; lJ++) {
					lJMod			= _lvlGround.j2ModJ( lJ);
					lDescs			= _lvlGround.getCellsAt( lIMod, lJMod);
					lGroundOffset	= _lvlGround.getGroundOffset( lI, lJ);
					
					for each( lDesc in lDescs) {
						lOffsets	= _lvlGround.getCellGroundOffsetsFrom( lIMod, lJMod, lDesc);
						
						for ( lIO = lOffsets.left ; lIO <= lOffsets.right ; lIO++) {
							for ( lJO = lOffsets.top ; lJO <= lOffsets.bottom ; lJO++) {
								lOffset	= new Point( lIO + lGroundOffset.x, lJO + lGroundOffset.y);
								lName	= getInstanceQualifiedGroundName( lDesc, lOffset);
								
								if ( ! lDone[ lName]) {
									lDone[ lName] = true;
									lSp = sprites[ lName] as MySprite;
									
									if ( lSp && lSp.isClipable()) {
										lCellClipRIJ	= lDesc.cellOffset.clone();
										lCellClipRIJ.offset( lOffset.x * _lvlGround.CELLS_PER_W + lDesc.i, lOffset.y * _lvlGround.CELLS_PER_H + lDesc.j);
										
										if ( pClipRIJ.left > lCellClipRIJ.right || pClipRIJ.right < lCellClipRIJ.left || pClipRIJ.top > lCellClipRIJ.bottom || pClipRIJ.bottom < lCellClipRIJ.top) {
											spMgr.remSpriteDisplay( lSp);
										}
									}
								}
							}
						}
					}
				}
			}
		}
		
		protected function clipRectInRegular( pI : int, pJ : int, pW : int, pH : int) : void {
			var lIMax			: int			= pI + pW;
			var lJMax			: int			= pJ + pH;
			var lI				: int			= pI;
			var lJ				: int;
			var lDescs			: Object;
			var lDesc			: MyCellDesc;
			
			for ( ; lI < lIMax ; lI++) {
				for ( lJ = pJ ; lJ < lJMax ; lJ++) {
					lDescs	= _lvlGround.getCellsAt( lI, lJ);
					
					for each( lDesc in lDescs) {
						if ( ! sprites[ lDesc.instanceId]) {
							spMgr.addSpriteDisplay(
								lDesc.instanciate(),
								lDesc.i * _lvlGround.CELL_W + lDesc.dx,
								lDesc.j * _lvlGround.CELL_H + lDesc.dy,
								lDesc.instanceId,
								lDesc
							);
						}
					}
				}
			}
		}
		
		protected function clipRectInCycle( pI : int, pJ : int, pW : int, pH : int) : void {
			var lIMax			: int			= pI + pW;
			var lJMax			: int			= pJ + pH;
			var lI				: int			= pI;
			var lJ				: int;
			var lIMod			: int;
			var lJMod			: int;
			var lDescs			: Object;
			var lGroundOffset	: Point;
			var lOffset			: Point;
			var lDesc			: MyCellDesc;
			var lName			: String;
			var lOffsets		: Rectangle;
			var lIO				: int;
			var lJO				: int;
			
			for ( ; lI < lIMax ; lI++) {
				lIMod	= _lvlGround.i2ModI( lI);
				
				for ( lJ = pJ ; lJ < lJMax ; lJ++) {
					lJMod			= _lvlGround.j2ModJ( lJ);
					lDescs			= _lvlGround.getCellsAt( lIMod, lJMod);
					lGroundOffset	= _lvlGround.getGroundOffset( lI, lJ);
					
					for each( lDesc in lDescs) {
						lOffsets	= _lvlGround.getCellGroundOffsetsFrom( lIMod, lJMod, lDesc);
						
						for ( lIO = lOffsets.left ; lIO <= lOffsets.right ; lIO++) {
							for ( lJO = lOffsets.top ; lJO <= lOffsets.bottom ; lJO++) {
								lOffset	= new Point( lIO + lGroundOffset.x, lJO + lGroundOffset.y);
								lName	= getInstanceQualifiedGroundName( lDesc, lOffset);
								
								if ( ! sprites[ lName]) {
									spMgr.addSpriteDisplay(
										lDesc.instanciate(),
										( lOffset.x * _lvlGround.CELLS_PER_W + lDesc.i) * _lvlGround.CELL_W + lDesc.dx,
										( lOffset.y * _lvlGround.CELLS_PER_H + lDesc.j) * _lvlGround.CELL_H + lDesc.dy,
										lName,
										lDesc
									);
								}
							}
						}
					}
				}
			}
		}
		
		protected function getCellCameraOffsets( pCell : MyCellDesc) : Rectangle {
			var lOffset	: Rectangle	= pCell.cellOffset;
			var lModI	: int		= _lvlGround.i2ModI( curI);
			var lModJ	: int		= _lvlGround.j2ModJ( curJ);
			var lLeft	: int		= Math.ceil( ( lModI - ( pCell.i + lOffset.right)) / _lvlGround.CELLS_PER_W);
			var lTop	: int		= Math.ceil( ( lModJ - ( pCell.j + lOffset.bottom)) / _lvlGround.CELLS_PER_H);
			var lRight	: int		= Math.floor( ( _lvlGround.i2ModI( lModI + NB_CELLS_W - 1) - ( pCell.i + lOffset.left)) / _lvlGround.CELLS_PER_W) + Math.floor( ( lModI + NB_CELLS_W - 1) / _lvlGround.CELLS_PER_W);
			var lBot	: int		= Math.floor( ( _lvlGround.j2ModJ( lModJ + NB_CELLS_H - 1) - ( pCell.j + lOffset.top)) / _lvlGround.CELLS_PER_H) + Math.floor( ( lModJ + NB_CELLS_H - 1) / _lvlGround.CELLS_PER_H);
			
			if ( lLeft > lRight || lTop > lBot) return null;
			else return new Rectangle( lLeft, lTop, lRight - lLeft, lBot - lTop);
		}
		
		protected function getInstanceQualifiedGroundName( pCell : MyCellDesc, pGroundOffset : Point) : String { return "_" + pGroundOffset.x + "_" + pGroundOffset.y + pCell.instanceId; }
	}
}