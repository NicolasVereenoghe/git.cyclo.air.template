package net.cyclo.effect {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMaths;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * gestionnaire de fractal étoilé
	 * 
	 * @author	nico
	 */
	public class MyFractal2Mgr extends Sprite {
		/** nombre min de branches */
		public static const NB_BRANCH_MIN					: int									= 3;
		
		/** racine de nom d'asset de motif */
		protected var MOTIF_ASSET_RADIX						: String								= "fractal2_motif_";
		/** suffix de nom d'asset de motif de base */
		protected var BASE_ASSET_SUFFIX						: String								= "_base";
		/** suffix de nom d'asset de motif de branche */
		protected var BRANCH_ASSET_SUFFIX					: String								= "_branch";
		
		/** scale min de la base 0 ] 0 .. 1 [ */
		protected var BASE0_SCALE_MIN						: Number								= .5;
		/** écrasement min (scale) d'une branche ] 0 .. 1] */
		protected var BRANCH_SHRINK_MIN						: Number								= .05;
		/** limite de scale du support à partir de laquelle, les branches poussent sur le support ] 0 .. 1 [ */
		protected var NEXT_BRANCH_SCALE_LIMIT				: Number								= .8;
		/** nombre max de récursions du fractal */
		protected var RECUR_MAX								: int									= 5;
		/** scale min pour un taux de disparité max */
		protected var DISPARITY_MIN_SCALE					: Number								= .1;
		
		/** scale global limite en dessous duquel on ne fait plus de rendu */
		protected var MICRO_SCALE							: Number								= .005;
		
		/** demi amplitude max d'un arc de branche en deg */
		protected var MAX_A_BRANCH							: Number								= 90;
		
		/** rayon du fractal étoilé */
		protected var _ray									: Number								= 100;
		/** nombre de branches du fractal étoilé ; min = NB_BRANCH_MIN ; 0 si pas encore défini */
		protected var _nbBranch								: int									= 0;
		/** scale de récursion, déduit du nombre de branche ] 0 .. 1] */
		protected var scaleRecur							: Number								= 1;
		/** écrasement (scale) déduit du scale de récursion et du taux d'écrasement du dernier rendu [ 0 .. 1] */
		protected var shrinkRecur							: Number								= 1;
		
		/**
		 * construction
		 */
		public function MyFractal2Mgr() { super(); }
		
		/**
		 * initialisation, construction de la vue initiale
		 * @param	pStarRay				rayon du motif de base du fractal étoile ; 100 par défaut
		 * @param	pInitShrinkRate			taux d'écrasement initial des branches [ 0 .. 1] ; 0 par défaut (pas écrasé)
		 * @param	pInitExpandRate			taux initial d'expansion du fractal étoilé [ 0 .. 1] ; 0 par défaut
		 * @param	pInitDisparityRate		taux de disparité des branches en fonction de leur écart de l'axe principal de pousse, [ 0 .. 1 ] ; par défaut disparité max de 1
		 * @param	pInitNbBranch			nombre de branches à l'init ] ::NB_BRANCH_MIN .. n] ; laisser -1 pour valeur par défaut min ::NB_BRANCH_MIN
		 * @param	pAssetRadix				racine de nom d'asset de motif de base/branche ; laisser null pour valeur par défaut ::MOTIF_ASSET_RADIX
		 * @param	pBranchShrinkMin		écrasement min (scale) d'une branche ] 0 .. 1] ; -1 pour valeur par défaut ::BRANCH_SHRINK_MIN
		 * @param	pNextBranchScaleLimit	limite de scale du support à partir de laquelle, les branches poussent sur le support ] 0 .. 1 [ ; laisser -1 pour valeur par défaut ::NEXT_BRANCH_SCALE_LIMIT
		 * @param	pBase0ScaleMin			scale min de la base 0 ] 0 .. 1 [ ; -1 pour valeur par défaut ::BASE0_SCALE_MIN
		 * @param	pRecurMax				nombre max de récursions du fractal ; -1 pour valeur par défaut ::RECUR_MAX
		 * @param	pDisparityMinScale		scale min pour un taux de disparité max ] 0 .. 1] ; -1 pour valeur par défaut ::DISPARITY_MIN_SCALE
		 */
		public function init( pStarRay : Number = 100, pInitShrinkRate : Number = 0, pInitExpandRate : Number = 0, pInitDisparityRate : Number = 1, pInitNbBranch : int = -1, pAssetRadix : String = null, pBranchShrinkMin : Number = -1, pNextBranchScaleLimit : Number = -1, pBase0ScaleMin : Number = -1, pRecurMax : int = -1, pDisparityMinScale : Number = -1) : void {
			if ( pAssetRadix != null) MOTIF_ASSET_RADIX = pAssetRadix;
			if ( pBranchShrinkMin > 0) BRANCH_SHRINK_MIN = pBranchShrinkMin;
			if ( pNextBranchScaleLimit > 0) NEXT_BRANCH_SCALE_LIMIT = pNextBranchScaleLimit;
			if ( pBase0ScaleMin > 0) BASE0_SCALE_MIN = pBase0ScaleMin;
			if ( pRecurMax >= 0) RECUR_MAX = pRecurMax;
			if ( pInitNbBranch < NB_BRANCH_MIN) pInitNbBranch = NB_BRANCH_MIN;
			if ( pDisparityMinScale > 0) DISPARITY_MIN_SCALE = pDisparityMinScale;
			
			_ray = pStarRay;
			
			addChild( new Sprite());
			addChild( new Sprite());
			
			doRender( pInitShrinkRate, pInitExpandRate, pInitDisparityRate, pInitNbBranch);
		}
		
		/**
		 * destruction
		 */
		public function destroy() : void { freeBranch( this); }
		
		/**
		 * on récupère le nombres de branches en cours
		 * @return	nombre de branche du fractal étoilé
		 */
		public function get nbBranch() : int { return _nbBranch; }
		
		/**
		 * on effectue le rendu du fractal étoilé
		 * @param	pShrinkRate		taux d'écrasement des branches [ 0 .. 1] ; 0 <=> pas écrasé
		 * @param	pExpandRate		taux d'expansion du fractal étoilé [ 0 .. 1]
		 * @param	pDisparityRate	taux de disparité suivant l'écart de l'axe principal d'une branche [ 0 .. 1] ; 0 <=> pas de disparité, croissance identique
		 * @param	pNb				nombre de branches à faire afficher au gestionnaire ; si < ::NB_BRANCH_MIN, on garde ::NB_BRANCH_MIN ; si nombre inchangé par rapport à la dernière itération, on ne touche pas
		 */
		public function doRender( pShrinkRate : Number, pExpandRate : Number, pDisparityRate : Number, pNb : int) : void {
			var lCont	: DisplayObjectContainer;
			var lDisp	: DisplayObject;
			var lRate	: Number;
			var lI		: int;
			var lA		: Number;
			
			if ( pNb < NB_BRANCH_MIN) pNb = NB_BRANCH_MIN;
			
			if ( _nbBranch != pNb) {
				if ( _nbBranch != 0) freeBranch( this);
				
				addChild( new Sprite());
				addChild( new Sprite());
				
				_nbBranch = pNb;
				
				procScaleRecur();
				
				getBaseCont( this).addChild( instanciateBase( 0));
			}
			
			lRate	= getBase0ScaleFromExpandRate( pExpandRate);
			scaleX	= scaleY = lRate;
			
			onBaseAtRate( getBaseCont( this), 0, lRate);
			
			if ( lRate > NEXT_BRANCH_SCALE_LIMIT && RECUR_MAX > 0) {
				procShrinkRecur( pShrinkRate);
				
				for ( lI = 0 ; lI < _nbBranch ; lI++) {
					lA = lI * 360 / _nbBranch;
					
					updateBranch( pExpandRate, pDisparityRate, getBranchCont( this), lRate, 1, lI, 1, -MAX_A_BRANCH, MAX_A_BRANCH);
				}
			}else {
				lCont = getBranchCont( this);
				
				while ( lCont.numChildren > 0) {
					lDisp = ( lCont.getChildAt( 0) as DisplayObjectContainer).getChildAt( 0);
					freeBranch( lDisp as DisplayObjectContainer);
					UtilsMovieClip.clearFromParent( lDisp.parent);
					UtilsMovieClip.clearFromParent( lDisp);
				}
			}
		}
		
		/**
		 * calcul du scale de récursion (set ::scaleRecur) ; appel suite à une mise à jour du nombre de branches (::_nbBranch)
		 */
		protected function procScaleRecur() : void {
			if ( _nbBranch <= 4) scaleRecur = 1;
			else scaleRecur = Math.tan( Math.PI / _nbBranch);
		}
		
		/**
		 * calcul de l'écrasement (scale) (set ::shrinkRecur) déduit du scale de récursion et du taux d'écrasement du rendu encours d'exe
		 * @param	pShrinkRate		taux d'écrasement des branches [ 0 .. 1] du rendu en cours d'exe ; 0 <=> pas écrasé
		 */
		protected function procShrinkRecur( pShrinkRate : Number) : void { shrinkRecur = BRANCH_SHRINK_MIN + ( scaleRecur - BRANCH_SHRINK_MIN) * ( 1 - pShrinkRate); }
		
		/**
		 * on réupère le conteneur de base
		 * @param	pCont	conteneur de couple base / branch
		 * @return	contenbeur graphique
		 */
		protected function getBaseCont( pCont : DisplayObjectContainer) : DisplayObjectContainer { return pCont.getChildAt( 1) as DisplayObjectContainer; }
		
		/**
		 * on récupère le conteneur de branches
		 * @param	pCont	conteneur de couple base / branch
		 * @return	conteneur graphique
		 */
		protected function getBranchCont( pCont : DisplayObjectContainer) : DisplayObjectContainer { return pCont.getChildAt( 0) as DisplayObjectContainer; }
		
		/**
		 * on calcule le scale de la base 0 en fonction du taux d'expansion
		 * @param	pExpandRate	taux d'expansion [ 0 .. 1]
		 * @return	scale de la base [ ::BASE0_SCALE_MIN .. 1]
		 */
		protected function getBase0ScaleFromExpandRate( pExpandRate : Number) : Number {
			var lMid	: Number		= 1 / ( 2 * ( RECUR_MAX + 1));
			
			if ( pExpandRate < lMid) return BASE0_SCALE_MIN + ( NEXT_BRANCH_SCALE_LIMIT - BASE0_SCALE_MIN) * pExpandRate / lMid;
			else if ( pExpandRate < 2 * lMid) return NEXT_BRANCH_SCALE_LIMIT + ( 1 - NEXT_BRANCH_SCALE_LIMIT) * ( pExpandRate - lMid) / lMid;
			else return 1;
		}
		
		/**
		 * on calcule le scale de la base n en fonction du taux d'expansion
		 * @param	pRecurLvl	niveau de récursion [ 1 .. n]
		 * @param	pExpandRate	taux d'expansion [ 0 .. 1]
		 * @return	scale de la base [ 0 .. 1]
		 */
		protected function getBaseNScaleFromExpandRate( pRecurLvl : int, pExpandRate : Number) : Number {
			var lMaxR	: int		= RECUR_MAX + 1;
			var lDelt	: Number	= 1 / lMaxR;
			var lBeg	: Number	= ( 2 * pRecurLvl - 1) * lDelt / 2;
			var lMid	: Number	= pRecurLvl * lDelt;
			
			if ( pExpandRate <= lBeg) return 0;
			else if ( pExpandRate <= lMid) return NEXT_BRANCH_SCALE_LIMIT * ( pExpandRate - lBeg) / ( lDelt / 2);
			else if ( pExpandRate < ( pRecurLvl + 1) * lDelt) return NEXT_BRANCH_SCALE_LIMIT + ( 1 - NEXT_BRANCH_SCALE_LIMIT) * ( pExpandRate - lMid) / lDelt;
			else return 1;
		}
		
		/**
		 * on calcule le scale de disparité à un certain indice de branche, pour un certain taux de disparité
		 * @param	pI				indice de branche [ 0 .. n-1]
		 * @param	pDisparityRate	taux de disparité [ 0 .. 1] : 0 homogène
		 * @return	scale de disparité [ DISPARITY_MIN_SCALE .. 1]
		 */
		protected function getDisparityScaleAtI( pI : int, pDisparityRate : Number) : Number {
			var lMinScale	: Number	= DISPARITY_MIN_SCALE + ( 1 - DISPARITY_MIN_SCALE) * ( 1 - pDisparityRate);
			
			return lMinScale + ( 1 - lMinScale) * ( 1 - Math.min( 1, Math.abs( _nbBranch / 2 - pI) / ( _nbBranch * MAX_A_BRANCH / 360)));
		}
		
		/**
		 * on instancie le rendu de la base
		 * @param	pRecurLvl	niveau de récursion [ 0 .. n]
		 * @return	instance sous forme d'objet graphique
		 */
		protected function instanciateBase( pRecurLvl : int) : DisplayObject {
			return AssetsMgr.getInstance().getAssetInstance( MOTIF_ASSET_RADIX + _nbBranch + ( pRecurLvl == 0 ? BASE_ASSET_SUFFIX : BRANCH_ASSET_SUFFIX));
		}
		
		/**
		 * on libère de la mémoire d'un rendu de base
		 * @param	pDisp	rendu graphique à libérer
		 */
		protected function freeBase( pDisp : DisplayObject) : void { ( pDisp as AssetInstance).free(); }
		
		/**
		 * on libère la mémoire des branches ; /!\ : récursion
		 * @param	pCont	conteneur de couple base + ses branches
		 */
		protected function freeBranch( pCont : DisplayObjectContainer) : void {
			var lCont	: DisplayObjectContainer	= getBranchCont( pCont);
			var lDisp	: DisplayObject				= getBaseCont( pCont).getChildAt( 0);
			var lChild	: DisplayObject;
			
			while ( lCont.numChildren > 0) {
				lChild = ( lCont.getChildAt( 0) as DisplayObjectContainer).getChildAt( 0);
				freeBranch( lChild as DisplayObjectContainer);
				UtilsMovieClip.clearFromParent( lChild.parent);
				UtilsMovieClip.clearFromParent( lChild);
			}
			
			freeBase( lDisp);
			UtilsMovieClip.clearFromParent( lDisp);
			
			UtilsMovieClip.clearFromParent( pCont.getChildAt( 0));
			UtilsMovieClip.clearFromParent( pCont.getChildAt( 0));
		}
		
		/**
		 * on met à jour ou si inexistante on crée la branche ; si scale trop petit, on ignore ou on vire ce qu'il y a ; /!\ : récursion
		 * @param	pExpandRate		taux d'expansion du fractal étoilé [ 0 .. 1]
		 * @param	pDisparityRate	taux de disparité suivant l'écart de l'axe principal d'une branche [ 0 .. 1] ; 0 <=> pas de disparité, croissance identique
		 * @param	pBranchCont		conteneur des prochaines branches qu'on crée
		 * @param	pCumulScale		scale cumulé depuis la racine (base0)
		 * @param	pAtRecurLvl		niveau de récursion auquel la nouvelle branche est générée
		 * @param	pIBranch		indice de branche autour du cercle trigonométrique
		 * @param	pDisparityScale	scale appliqué à la base de cette branche par disparité
		 * @param	pFromDRot		delta de début d'arc qui pousse en deg autour de l'axe d'origine sur ] -180 .. 180]
		 * @param	pToDRot			delta de fin d'arc autour de l'origine sur ] -180 .. 180]
		 */
		protected function updateBranch( pExpandRate : Number, pDisparityRate : Number, pBranchCont : DisplayObjectContainer, pCumulScale : Number, pAtRecurLvl : int, pIBranch : int, pDisparityScale : Number, pFromDRot : Number, pToDRot : Number) : void {
			var lDisp	: DisplayObject				= pBranchCont.getChildByName( "mc" + pIBranch);
			var lRate	: Number					= getBaseNScaleFromExpandRate( pAtRecurLvl, pExpandRate);
			var lRateTt	: Number					= lRate * pDisparityScale * shrinkRecur;
			var lCont	: DisplayObjectContainer;
			var lI		: int;
			var lIEnd	: int;
			var lA		: Number;
			
			if ( lRateTt * pCumulScale <= MICRO_SCALE) {
				if ( lDisp != null) {
					lCont = ( lDisp as DisplayObjectContainer).getChildAt( 0) as DisplayObjectContainer;
					freeBranch( lCont);
					UtilsMovieClip.clearFromParent( lCont);
					UtilsMovieClip.clearFromParent( lDisp);
				}
				
				return;
			}
			
			if ( lDisp == null) {
				lCont = new Sprite();
				lCont.name = "mc" + pIBranch;
				pBranchCont.addChild( lCont);
				
				lCont.rotation = 180 + pIBranch * 360 / _nbBranch;
				
				lCont = lCont.addChild( new Sprite()) as DisplayObjectContainer;
				
				lCont.addChild( new Sprite());
				lCont.addChild( new Sprite());
				
				getBaseCont( lCont).addChild( instanciateBase( pAtRecurLvl));
			}else lCont = ( lDisp as DisplayObjectContainer).getChildAt( 0) as DisplayObjectContainer;
			
			lCont.x			= -2 * _ray + _ray * ( 1 - lRateTt);//-_ray - ( _ray * lRateTt) / 2;
			lCont.scaleX	= lCont.scaleY = lRateTt;
			
			onBaseAtRate( getBaseCont( lCont), pAtRecurLvl, lRate);
			
			if ( lRate > NEXT_BRANCH_SCALE_LIMIT && RECUR_MAX > pAtRecurLvl++) {
				lCont		= getBranchCont( lCont);
				pCumulScale	*= lRateTt;
				lI			= Math.ceil( _nbBranch * ( 180 + pFromDRot) / 360);
				lIEnd		= Math.floor( _nbBranch * ( 180 + pToDRot) / 360);
				
				for ( ; lI <= lIEnd ; lI++) {
					lA	= 180 - lI * 360 / _nbBranch;
					
					updateBranch(
						pExpandRate,
						pDisparityRate,
						lCont,
						pCumulScale,
						pAtRecurLvl,
						lI,
						getDisparityScaleAtI( lI, pDisparityRate),
						Math.max( pFromDRot, pFromDRot + lA),
						Math.min( pToDRot, pToDRot + lA)
					);
				}
			}else {
				lCont = getBranchCont( lCont);
				
				while ( lCont.numChildren > 0) {
					lDisp = ( lCont.getChildAt( 0) as DisplayObjectContainer).getChildAt( 0);
					freeBranch( lDisp as DisplayObjectContainer);
					UtilsMovieClip.clearFromParent( lDisp.parent);
					UtilsMovieClip.clearFromParent( lDisp);
				}
			}
		}
		
		/**
		 * on signale l'évolution d'une base à partir de son taux de croissance
		 * @param	pBaseCont	conteneur de base
		 * @param	pRecurLvl	niveau de récursion de la base [ 0 .. n]
		 * @param	pRate		taux de croissance [ 0  .. 1]
		 */
		protected function onBaseAtRate( pBaseCont : DisplayObjectContainer, pRecurLvl : int, pRate : Number) : void {}
	}
}