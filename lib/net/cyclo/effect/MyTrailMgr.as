package net.cyclo.effect {
	import flash.geom.Point;
	
	/**
	 * gestionnaire simple et optimisé de trainnée d'une tête en mouvement
	 * 
	 * @author nico
	 */
	public class MyTrailMgr {
		/** écart min entre 2 éléments de trainée, en dessous, ça disparaît */
		protected var MIN_SPACE								: Number								= 2;
		/** écart max entre 2 éléments de trainée */
		protected var MAX_SPACE								: Number								= 3;
		/** nombre d'éléments de trainée */
		protected var NB_MAX								: int									= 30;
		/** alpha max de l'élément juste derrière la tête */
		protected var ALPHA_MAX								: Number								= .2;
		/** perte d'alpha par itération d'un élément trop court */
		protected var DRIFT_ALPHA_PER_FRAME					: Number						 		= .04;
		
		/** dernière abscisse de tête */
		protected var lastX									: Number								= 0;
		/** dernière ordonnée de tête */
		protected var lastY									: Number								= 0;
		
		/** pile d'éléments de trainée, en commençant par l'élément juste derrière la tête, vers la queue ; { x: <abscisse élément>, y: <ordonnée élément>, rot: <rotation élément en deg>, alpha: <alpha de l'élément>, tag: <tag identifiant d'état>}*/
		protected var trails								: Array									= null;
		
		/**
		 * construction
		 * @param	pMin	espace min entre 2 éléments ; laisser -1 pour valeur par défaut
		 * @param	pMax	espace max entre 2 éléments ; laisser -1 pour valeur par défaut
		 * @param	pNb		nombre d'éléments de trainée ; laisser -1 pour valeur par défaut
		 * @param	pAlphaM	alpha max ; laisser -1 pour valeur par défaut
		 */
		public function MyTrailMgr( pMin : Number = -1, pMax : Number = -1, pNb : Number = -1, pAlphaM : Number = -1) {
			if ( pMin > 0) MIN_SPACE = pMin;
			if ( pMax > MIN_SPACE) MAX_SPACE = pMax;
			if ( pNb > 0) NB_MAX = pNb;
			if ( pAlphaM > 0) ALPHA_MAX = pAlphaM;
		}
		
		/**
		 * initialisation
		 * @param	pX	abscisse initiale de la tête
		 * @param	pY	ordonnée initiale de la tête
		 */
		public function init( pX : Number, pY : Number) : void {
			lastX	= pX;
			lastY	= pY;
			trails	= new Array();
		}
		
		/**
		 * destruction
		 */
		public function destroy() : void {
			trails = null;
		}
		
		/**
		 * on ajoute un élément de trainée, juste derrière le dernier élément
		 * à appeler successivement après l'init si on veut décrire une trainée avec un état initial
		 * @param	pX		abscisse de l'élément de trainée
		 * @param	pY		ordonnée de l'élément de trainée
		 * @param	pRot	rotation de l'élément de trainée en deg
		 * @param	pAlpha	alpha de l'élément de trainée
		 * @param	pTag	tag attribué à cet trainée (libre)
		 */
		public function addItem( pX : Number, pY : Number, pRot : Number = 0, pAlpha : Number = 1, pTag : String = null) : void {
			trails.push({
				x:		pX,
				y:		pY,
				rot:	pRot,
				alpha:	pAlpha,
				tag:	pTag
			});
		}
		
		/**
		 * on effectue l'itération de trainée
		 * @param	pX			nouvelle abscisse de tête
		 * @param	pY			nouvelle ordonnée de tête
		 * @param	pOnItemFunc	méthode de call back : function( pI : <num d'item depuis la tête, 1..n:int>, pTotal : <nb d'item:int>, pX : <abscisse item:Number>, pY : <ordonnée élément:Number>, pRot : <rotation élément en deg:Number>, pAlpha : <alpha élément:Number>, pTag : <tag d'état:String>, pIsNew : <true pour new, false sinon>) : void;
		 * @param	pRot		rotation de tête
		 * @param	pTag		tag identifiant de l'état de tête (libre)
		 */
		public function doTrail( pX : Number, pY : Number, pOnItemFunc : Function, pRot : Number = 0, pTag : String = null) : void {
			var lDelt	: Point			= new Point( pX - lastX, pY - lastY);
			var lLen	: Number		= lDelt.length;
			var lDrift	: Boolean		= false;
			var lAlpha	: Number;
			var lD		: Number;
			var lDX		: Number;
			var lDY		: Number;
			var lTrail	: Object;
			var lI		: int;
			var lSpace	: Number;
			var lNb		: int;
			var lTotal	: int;
			
			if ( lLen > MIN_SPACE) {
				lDelt.normalize( 1);
				
				if ( lLen < MAX_SPACE) lSpace = lLen;
				else lSpace = MAX_SPACE;
				
				lNb 	= Math.floor( lLen / lSpace);
				lTotal	= Math.min( NB_MAX, trails.length + lNb);
				
				for ( lI = 0 ; lI < lNb ; lI++) {
					lTrail = {
						x:		pX - lDelt.x * ( lI + 1) * lSpace,
						y:		pY - lDelt.y * ( lI + 1) * lSpace,
						rot:	pRot,
						alpha:	getAlphaFromRank( lI),
						tag:	pTag
					}
					
					pOnItemFunc( lI + 1, lTotal, lTrail.x, lTrail.y, pRot, lTrail.alpha, pTag, true);
					
					trails.splice( lI, 0, lTrail);
				}
				
				lD		= lLen - lNb * lSpace;
				lDX		= lDelt.x * lD;
				lDY		= lDelt.y * lD;
			}else {
				lDX		= lDelt.x;
				lDY		= lDelt.y;
				lNb		= 0;
				lTotal	= trails.length;
				lDrift	= true;
			}
			
			lastX	= pX;
			lastY	= pY;
			
			for ( lI = lNb ; lI < lTotal ; lI++) {
				lTrail = trails[ lI];
				
				if ( lDrift) {
					if ( lTrail.alpha > DRIFT_ALPHA_PER_FRAME) {
						lTrail.alpha -= DRIFT_ALPHA_PER_FRAME;
					}else lTrail.alpha = 0;
				}else {
					lAlpha	= getAlphaFromRank( lI);
					
					if ( lTrail.alpha - DRIFT_ALPHA_PER_FRAME > lAlpha) {
						lTrail.alpha = lAlpha;
						
						if ( lAlpha == 0) lDrift = true;
					}else if ( lTrail.alpha > DRIFT_ALPHA_PER_FRAME) {
						lTrail.alpha -= DRIFT_ALPHA_PER_FRAME;
					}else {
						lDrift = true;
						lTrail.alpha = 0;
					}
				}
				
				lTrail.x += lDX;
				lTrail.y += lDY;
				
				pOnItemFunc( lI + 1, lTotal, lTrail.x, lTrail.y, lTrail.rot, lTrail.alpha, lTrail.tag, false);
			}
			
			if ( trails.length > NB_MAX) trails.splice( NB_MAX);
		}
		
		/**
		 * calcul d'alpha en fonction de l'indice d'élément dans la trainée
		 * @param	pRank	indice d'élément dans la trainée [ 0 .. n-1]
		 * @return
		 */
		protected function getAlphaFromRank( pRank : int) : Number { return ALPHA_MAX * ( 1 - pRank / NB_MAX); }
	}
}