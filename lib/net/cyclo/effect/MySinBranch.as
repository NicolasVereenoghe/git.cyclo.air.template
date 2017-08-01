package net.cyclo.effect {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * gestionnaire de branche sinueuse
	 * le modèle est un asset avec des "mcLeaf<i>" comme conteneurs des prochains motifs de la branche
	 * un "mcLeaf<i>" contient un graphisme (même invisible pour le montage), on le suppose vide si son numChildren vaut 1
	 * on a une croissance principale forte sur un chemin sinueux en balayant les feuilles, une croissance faible sur les voix alternatives
	 * 
	 * @author nico
	 */
	public class MySinBranch extends Sprite {
		/** map de nombre de branches, indexée par nom de modèle */
		protected static var NB_BRANCH										: Object										= null;
		
		/** id d'asset par défaut */
		protected var ASSET_ID												: String										= "sinBranch_model";
		
		/** niveau max de récursion de rendu [ 0 .. n] */
		protected var RECUR_MAX												: int											= 10;
		/** scale min global de rendu ; en dessous on ignore */
		protected var SCALE_MIN												: Number										= .15;
		/** scale max du motif suivant à côté du chemin principal ; ensuite c'est une dégradation linéaire jusqu'à l'étape avant 0 */
		protected var SCALE_MAX_ALT											: Number										= .667;
		/** scale max du la suite de la branche principale */
		protected var SCALE_MAX_MAIN										: Number										= .9;
		/** scale de base de croissance d'un motif à l'étape 0 */
		protected var SCALE0												: Number										= .2;
		/** limite de scale du support à partir de laquelle, les branches poussent sur le support */
		protected var NEXT_SCALE_LIMIT										: Number										= .75;
		/** coef de dégradation supplémentaire de scale sur les branches alternatives */
		protected var ALT_SCALE_COEF										: Number										= .8;
		
		/** offset de niveau de récursion pour le calcul du cycle sinueux */
		protected var RECUR_SIN_OFFSET										: int											= -1;
		
		/** précalculé : écart de points de croissance qu'il y a entre chaque niveau de récursion ; -1 si pas défini */
		protected var DELT_RECUR_GROW										: Number										= -1;
		/** précalculé : points de scale gagnés par point de croissance global pour un motif en 1ere phase de croissance (expansion) ; -1 si pas défini */
		protected var PHASE1_SCALE_PER_GROW 								: Number										= -1;
		/** précalculé : points de scale gagnés par point de croissance global pour un motif en 2eme phase de croissance (fin d'expansion + pousse de la suite) ; -1 si pas défini */
		protected var PHASE2_SCALE_PER_GROW									: Number										= -1;
		
		/** modèle de base, null si pas encore défini */
		protected var model													: AssetInstance									= null;
		
		/** taux d'expansion global en cours de la branche sur [ 0 .. 1] */
		protected var curGrowRate											: Number										= 0;
		/** taux de disparité en cours de la branche sur [ 0 .. 1] */
		protected var curDispRate											: Number										= 0;
		
		/** précalculé : scale max de chemin alternatif */
		protected var curAltMax												: Number										= 0;
		
		/** niveau de recherche de récursion du dernier appel à appliquer une méthode aux instances (voir ::applyFuncAtR) */
		protected var applyFuncAtThisR										: int											= -1;
		
		/**
		 * construction
		 */
		public function MySinBranch() { super(); }
		
		/**
		 * initialisation, construction de la vue initiale
		 * @param	pGrowRate		taux d'expansion de la branche à l'init [ 0 .. 1]
		 * @param	pDispRate		taux de disparité à l'init [ 0<=>disparité min .. 1<=>disparité max]
		 * @param	pAssetId		id d'asset du modèle de branche ; laisser null pour valeur par défaut
		 * @param	pRecurMax		niveau de récursion max ; laisser -1 pour valeur par défaut
		 * @param	pLimScaleMin	limite de scale de rendu, en dessous on ignore ; laisser -1 pour valeur par défaut
		 * @param	pAltScaleMax	scale max des chemins alternatifs, dégressif linéaire plus on s'éloigne du principal ; laisser -1 pour valeur par défaut
		 * @param	pMainScaleMax	scale max du prochain motif du chemin principal sinueux ; laisser -1 pour valeur par défaut
		 * @param	pScale0			scale de base de croissance d'un motif à l'étape 0 ; laisser -1 pour valeur par défaut
		 * @param	pNextScaleLim	limite de scale du support à partir de laquelle, les branches poussent sur le support ; laisser -1 pour valeur par défaut
		 * @param	pAltScaleCoef	coef de dégradation de scale [ 0 .. 1] à appliquer de manière globale aux récursions de chemin alternatif ; laisser -1 pour valeur par défaut
		 */
		public function init( pGrowRate : Number = 0, pDispRate : Number = 1, pAssetId : String = null, pRecurMax : int = -1, pLimScaleMin : Number = -1, pAltScaleMax : Number = -1, pMainScaleMax : Number = -1, pScale0 : Number = -1, pNextScaleLim : Number = -1, pAltScaleCoef : Number = -1) : void {
			if ( pAssetId != null) ASSET_ID = pAssetId;
			if ( pRecurMax >= 0) RECUR_MAX = pRecurMax;
			if ( pLimScaleMin >= 0) SCALE_MIN = pLimScaleMin;
			if ( pAltScaleMax >= 0) SCALE_MAX_ALT = pAltScaleMax;
			if ( pMainScaleMax >= 0) SCALE_MAX_MAIN = pMainScaleMax;
			if ( pScale0 >= 0) SCALE0 = pScale0;
			if ( pNextScaleLim >= 0) NEXT_SCALE_LIMIT = pNextScaleLim;
			if ( pAltScaleCoef >= 0) ALT_SCALE_COEF = pAltScaleCoef;
			
			DELT_RECUR_GROW			= 1 / ( RECUR_MAX + 1);
			PHASE1_SCALE_PER_GROW	= ( NEXT_SCALE_LIMIT - SCALE0) / ( DELT_RECUR_GROW / 2);
			PHASE2_SCALE_PER_GROW	= ( 1 - NEXT_SCALE_LIMIT) / DELT_RECUR_GROW;
			
			model					= getInstance( this, 0);
			
			procCurModel( model);
			
			doRender( pGrowRate, pDispRate);
		}
		
		/**
		 * destruction
		 */
		public function destroy() : void {
			if ( model != null) {
				freeBranch( model);
				model = null;
			}
		}
		
		/**
		 * on effectue un changement de modèle de motif en cours de rendu
		 * @param	pAssetId	id d'asset du nouveau modèle à permuter
		 */
		public function switchModel( pAssetId : String) : void {
			if( pAssetId != ASSET_ID){
				freeBranch( model);
				
				model = addChild( AssetsMgr.getInstance().getAssetInstance( pAssetId)) as AssetInstance;
				
				procCurModel( model);
				
				ASSET_ID = pAssetId;
				
				doRender( curGrowRate, curDispRate);
			}
		}
		
		/**
		 * on effectue un rendu de croissance de la branche sinueuse
		 * @param	pGrowRate	taux de croissance de la branche [ 0 .. 1]
		 * @param	pDispRate	taux de disparité de la branche [ 0<=>pas de disparité .. 1<=>disparité max]
		 */
		public function doRender( pGrowRate : Number, pDispRate : Number) : void {
			var lScale	: Number;
			
			curGrowRate	= pGrowRate;
			curDispRate	= pDispRate;
			
			curAltMax		= ( 1 - curDispRate) * SCALE_MAX_ALT;
			
			lScale			= getBase0ScaleFromExpandRate();
			
			updateBranch( 0, model, lScale, lScale, 1, "");
		}
		
		/**
		 * on applique une méthode à toutes les instances trouvées à un certain niveau de récursion
		 * @param	pR		niveau de récursion [ 0 .. n]
		 * @param	pFunc	méthode à appliquer aux instances trouvées ; on lui passe en params l'instance d'AssetInstance trouvée et le niveau de récusion de recherche
		 * @param	pModel	modèle de début de recherche, laisser null
		 */
		public function applyFuncAtR( pR : int, pFunc : Function, pModel : AssetInstance = null) : void {
			var lCont		: DisplayObjectContainer;
			var lNB_BRANCH	: int;
			var lI			: int;
			
			if ( pModel == null) {
				applyFuncAtThisR = pR;
				pModel = model;
			}
			
			if ( pR == 0) pFunc( pModel, applyFuncAtThisR);
			else {
				lNB_BRANCH = NB_BRANCH[ pModel.desc.id];
				
				pR--;
				
				for ( lI = 0 ; lI < lNB_BRANCH ; lI++) {
					lCont = getChildCont( pModel, lI);
					
					if( lCont.numChildren > 1) applyFuncAtR( pR, pFunc, lCont.getChildAt( 1) as AssetInstance);
				}
			}
		}
		
		/**
		 * on calcule le scale de la base 0 en fonction du taux d'expansion
		 * @return	scale de la base [ ::SCALE0 .. 1]
		 */
		protected function getBase0ScaleFromExpandRate() : Number {
			var lMid	: Number = 1 / ( 2 * ( RECUR_MAX + 1));
			
			if ( curGrowRate < lMid) return SCALE0 + ( NEXT_SCALE_LIMIT - SCALE0) * curGrowRate / lMid;
			else if ( curGrowRate < 2 * lMid) return NEXT_SCALE_LIMIT + ( 1 - NEXT_SCALE_LIMIT) * ( curGrowRate - lMid) / lMid;
			else return 1;
		}
		
		/**
		 * on calcule le scale de la base n en fonction du taux d'expansion en cours
		 * @param	pRecurLvl	niveau de récursion [ 1 .. n] ; doit être dans le contexte de croissance, pas avant que ça pousse
		 * @return	scale de la base [ ::SCALE0 .. 1]
		 */
		protected function getBaseNScaleFromExpandRate( pRecurLvl : int) : Number {
			var lDelt	: Number	= DELT_RECUR_GROW;
			var lBeg	: Number	= ( 2 * pRecurLvl - 1) * lDelt / 2;
			var lMid	: Number	= pRecurLvl * lDelt;
			
			if ( curGrowRate <= lMid) return SCALE0 + PHASE1_SCALE_PER_GROW * ( curGrowRate - lBeg);
			else if ( curGrowRate < ( pRecurLvl + 1) * lDelt) return NEXT_SCALE_LIMIT + PHASE2_SCALE_PER_GROW * ( curGrowRate - lMid);
			else return 1;
		}
		
		/**
		 * on filtre un enfant de la récursion avant de le construire, pour savoir si on le construit où si on ignore
		 * @param	pTagPath	tag de path de récursion de l'enfant
		 * @return	true pour construire, false pour ignorer
		 */
		protected function filterTagPath( pTagPath : String) : Boolean { return true; }
		
		/**
		 * on effectue le développement récursif d'une branche
		 * @param	pRecurLvl		niveau de récursion, [ 0 .. n]
		 * @param	pBranch			asset de branche à traiter dans ce niveau de récursion
		 * @param	pGlobalScale	scale global pour arrêter la récursion
		 * @param	pGrowScale		scale de croissance pré-calculé pour cette branche
		 * @param	pScaleCoef		coef de dégradation appliqué de manière globale aux prochains [ 0<=>dégradation max .. 1<=>aucune dégradation]
		 * @param	pTagPath		tag de chemin de récusion, concaténation des id de leaf rencontrés, ajoutés depuis le début en fin de chaine, séparés par "_"
		 */
		protected function updateBranch( pRecurLvl : int, pBranch : AssetInstance, pGlobalScale : Number, pGrowScale : Number, pScaleCoef : Number, pTagPath : String) : void {
			var lNB_BRANCH			: int						= NB_BRANCH[ pBranch.desc.id];
			var lSIN_PERIOD			: int						= 2 * lNB_BRANCH;
			var lCurDeltDispRate	: Number					= curAltMax / ( lNB_BRANCH - 1);
			var lI					: int						= 0;
			var lTag				: String;
			var lGrow				: Number;
			var lCurStep			: int;
			var lGlobalS			: Number;
			var lNextScaleC			: Number;
			var lMainI				: int;
			var lCont				: DisplayObjectContainer;
			var lScale				: Number;
			
			pBranch.scaleX	= pBranch.scaleY = pGrowScale;
			
			if ( pGrowScale >= NEXT_SCALE_LIMIT && pRecurLvl < RECUR_MAX) {
				lGrow		= getBaseNScaleFromExpandRate( ++pRecurLvl);
				
				if( lGrow * pGlobalScale >= SCALE_MIN){
					lCurStep	= ( pRecurLvl + RECUR_SIN_OFFSET) % lSIN_PERIOD;
					
					if ( lCurStep < lNB_BRANCH) lMainI = lCurStep;
					else lMainI = lSIN_PERIOD - lCurStep - 1;
					
					for ( ; lI < lNB_BRANCH ; lI++) {
						lTag = pTagPath + "_" + lI;
						
						if( filterTagPath( lTag)){
							lCont = getChildCont( pBranch, lI);
							
							if ( isAllMaxAtR( pRecurLvl) || lI == lMainI) {
								lScale		= pScaleCoef * SCALE_MAX_MAIN;
								lNextScaleC	= pScaleCoef;
							}else {
								lScale		= pScaleCoef * ( curAltMax - ( Math.abs( lMainI - lI) - 1) * lCurDeltDispRate);
								lNextScaleC	= ALT_SCALE_COEF;
							}
							
							lGlobalS = pGlobalScale * lScale * lGrow;
							
							if ( lGlobalS < SCALE_MIN) {
								if ( lCont.numChildren > 1) freeBranch( lCont.getChildAt( 1) as AssetInstance);
							}else {
								lCont.scaleX = lCont.scaleY = lScale;
								
								if ( lCont.numChildren > 1) {
									updateBranch(
										pRecurLvl,
										lCont.getChildAt( 1) as AssetInstance,
										lGlobalS,
										lGrow,
										lNextScaleC,
										lTag
									);
								} else {
									updateBranch(
										pRecurLvl,
										getInstance( lCont, pRecurLvl),
										lGlobalS,
										lGrow,
										lNextScaleC,
										lTag
									);
								}
							}
						}
					}
					
					return;
				}
			}
			
			for ( ; lI < lNB_BRANCH ; lI++) {
				lCont = getChildCont( pBranch, lI);
				
				if ( lCont.numChildren > 1) freeBranch( lCont.getChildAt( 1) as AssetInstance);
			}
		}
		
		/**
		 * on récupère une instance d'asset de modèle à attacher au fractal
		 * @param	pCont	conteneur où ajouter la novelle instance
		 * @param	pAtR	niveau de récursion où sera attaché le modèle
		 * @return	instance d'asset de modèe
		 */
		protected function getInstance( pCont : DisplayObjectContainer, pAtR : int) : AssetInstance { return pCont.addChild( AssetsMgr.getInstance().getAssetInstance( ASSET_ID)) as AssetInstance; }
		
		/**
		 * permet de forcer un rendu calculé à partir de ::SCALE_MAX_MAIN pour un certain niveau de récursion
		 * @param	pR	niveau de récursion
		 * @return	true pour forcer le rendu max, false pour traitement régulier
		 */
		protected function isAllMaxAtR( pR : int) : Boolean { return false; }
		
		/**
		 * on libère récursivement une branche avec tous ses enfants
		 * @param	pBranch	asset de branche
		 */
		protected function freeBranch( pAsset : AssetInstance) : void {
			var lNB_BRANCH	: int						= NB_BRANCH[ pAsset.desc.id];
			var lI			: int						= 0;
			var lCont		: DisplayObjectContainer;
			
			while ( lI < lNB_BRANCH) {
				lCont = getChildCont( pAsset, lI++);
				
				if( lCont.numChildren > 1) freeBranch( lCont.getChildAt( 1) as AssetInstance);
			}
			
			UtilsMovieClip.clearFromParent( pAsset);
			pAsset.free();
		}
		
		/**
		 * on récupère un conteneur de branche fille dans un asset de branche
		 * @param	pBranch	asset de branche
		 * @param	indice de branche fille, [ 0 .. n-1]
		 * @return	conteneur de branche fille, null si pas défini
		 */
		protected function getChildCont( pBranch : AssetInstance, pI : int) : DisplayObjectContainer { return ( pBranch.content as DisplayObjectContainer).getChildByName( "mcLeaf" + pI) as DisplayObjectContainer; }
		
		/**
		 * on précalcules le contexte de transformation du modèle en cours
		 * @param	pModel	asset de modèle
		 */
		protected function procCurModel( pModel : AssetInstance) : void {
			var lName	: String		= pModel.desc.id;
			var lChild	: DisplayObject = getChildCont( pModel, 0);
			var lCtr	: int			= 0;
			
			if ( NB_BRANCH == null) {
				NB_BRANCH = new Object();
			}else if ( NB_BRANCH[ lName] != null) return;
			
			while ( lChild != null) lChild = getChildCont( pModel, ++lCtr);
			
			NB_BRANCH[ lName] = lCtr;
		}
	}
}