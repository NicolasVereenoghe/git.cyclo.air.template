package net.cyclo.ui {
	import flash.display.DisplayObjectContainer;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import net.cyclo.shell.MySystem;
	
	/**
	 * compteur de score qui scroll ; itération contrôlée de manière externe via ::doFrame
	 * 
	 * @author nico
	 */
	public class MyCounterScore extends MyCounter {
		/** modulo de frames itérées */
		protected var SCORE_MODULO_FRAME					: int									= 2;
		/** coef d'inertie du scroll */
		protected var SCORE_INERTIA							: Number								= 1 / 4;
		/** scroll max */
		protected var SCORE_DELT_MAX						: int									= 500;
		/** scroll min */
		protected var SCORE_DELT_MIN						: int									= 5;
		/** nombre de chiffres de plus haute valeur que l'on fait scroller */
		protected var SCORE_NB_SCROLL_DIGIT					: int									= 2;
		
		/** degré de progression du bump */
		protected var BUMP_DEG								: Number								= .3;
		
		/** compteur de modulo de frames */
		protected var scoreMod								: int									= 0;
		
		/** score réel, diffère de la valeur affichée avec l'inertie */
		protected var score									: int									= -1;
		
		/** pile de valeurs décalées : { ctr: <itérations restantes avant compte:int>, val: <valeur à compter:int>} ; null si pas défini */
		protected var delayedVals							: Array									= null;
		
		/** matrice de trans originale du conteneur */
		protected var mtrx									: Matrix								= null;
		
		/** compteur d'effet bump ; à 0 le bump est fini */
		protected var bumpCtr								: int									= 0;
		/** durée totale du bump en cours en nombre d'itérations */
		protected var bumpTotal								: int									= 0;
		/** scale du bump en cours */
		protected var bumpScale								: Number								= 0;
		/** tranformation de couleur du bmp en cours */
		protected var bumpColor								: ColorTransform						= null;
		
		/**
		 * @inheritDoc
		 * 
		 * @param	pMinScroll	scroll min de valeur, laisser -1 pour valeur par défaut
		 * @param	pMod		modulo de frames itérées ; laisser -1 pour valeur par défaut
		 * @param	pInert		inertie de scroll ; laisser -1 pour valeur par défaut
		 */
		public function MyCounterScore( pContainer : DisplayObjectContainer, pValue : int = 0, pMinScroll : int = -1, pMod : int = -1, pInert : Number = -1) {
			super( pContainer, pValue);
			
			delayedVals = new Array();
			
			if ( pMinScroll >= 0) SCORE_DELT_MIN = pMinScroll;
			if ( pMod > 0) SCORE_MODULO_FRAME = pMod;
			if ( pInert > 0) SCORE_INERTIA = pInert;
			
			mtrx = pContainer.transform.matrix.clone();
		}
		
		/** @inheritDoc */
		override public function destroy() : void {
			delayedVals = null;
			
			container.transform.matrix = mtrx;
			container.transform.colorTransform = new ColorTransform();
			mtrx = null;
			bumpColor = null;
			
			super.destroy();
		}
		
		/**
		 * on demande faire une anim de bump du compteur qui sera itérée avec le ::doFrame
		 * @param	pRGB	couleur du bump
		 * @param	pScale	scale de bump
		 * @param	pDelay	nombre d'itérations du bump
		 */
		public function bump( pRGB : uint, pScale : Number, pDelay : int) : void {
			var lCol	: ColorTransform	= new ColorTransform();
			
			lCol.color	= pRGB;
			
			bumpCtr		= bumpTotal = pDelay;
			bumpScale	= pScale;
			bumpColor	= lCol;
			
			container.transform.colorTransform = lCol;
			container.scaleX = pScale * mtrx.a;
			container.scaleY = pScale * mtrx.d;
		}
		
		/**
		 * on vérifie si le compteur est en train de bumper
		 * @return	true si en train de bumper, false sinon
		 */
		public function isBumping() : Boolean { return bumpCtr > 0; }
		
		/**
		 * on effectue le framing du score scrollé
		 */
		public function doFrame() : void {
			var lDelt	: int;
			var lPow	: int;
			var lI		: int;
			var lScale	: Number;
			var lRate	: Number;
			var lInvR	: Number;
			
			if ( bumpCtr > 0) {
				if ( --bumpCtr == 0) {
					container.transform.colorTransform = new ColorTransform();
					container.transform.matrix = mtrx;
					bumpColor = null;
				}else {
					lRate	= Math.pow( bumpCtr / bumpTotal, BUMP_DEG);
					lInvR	= 1 - lRate;
					lScale	= ( 1 + ( bumpScale - 1) * lRate);
					
					container.scaleX = mtrx.a * lScale;
					container.scaleY = mtrx.d * lScale;
					
					container.transform.colorTransform = new ColorTransform(
						.5 + lInvR * .5,
						.5 + lInvR * .5,
						.5 + lInvR * .5,
						1,
						bumpColor.redOffset * lRate,
						bumpColor.greenOffset * lRate,
						bumpColor.blueOffset * lRate
					);
				}
			}
			
			for ( lI = delayedVals.length - 1 ; lI >= 0 ; lI--) {
				if ( delayedVals[ lI].ctr-- <= 0) {
					setValue( score + delayedVals[ lI].val, false);
					
					delayedVals.splice( lI, 1);
				}
			}
			
			if ( score != value) {
				if ( scoreMod-- == 0) {
					scoreMod	= SCORE_MODULO_FRAME - 1;
					lDelt		= score - value;
					
					//MySystem.traceDebug( "" + lDelt);
					
					if( lDelt > SCORE_DELT_MIN){
						lDelt	= Math.min( SCORE_DELT_MAX, Math.max( SCORE_DELT_MIN, Math.floor( lDelt * SCORE_INERTIA)));
						lPow	= Math.pow( 10, Math.max( 0, Math.floor( Math.log( lDelt) / Math.LN10) - SCORE_NB_SCROLL_DIGIT + 1));
						
						super.setValue( value + Math.floor( lDelt / lPow) * lPow);
					}else setValue( score);
				}
			}
		}
		
		/** @inheritDoc */
		override public function getRealValue() : int {
			var lTotal	: int	= score;
			var lI		: int;
			
			for ( lI = 0 ; lI < delayedVals.length ; lI++) lTotal += delayedVals[ lI].val;
			
			return lTotal;
		}
		
		/** @inheritDoc */
		override public function setValue( pVal : int, pForce : Boolean = true, pDelay : int = 0) : void {
			if( pForce || pDelay <= 0){
				if ( pForce) super.setValue( pVal, true);
				else if( pVal != score) scoreMod = 0;
				
				score = pVal;
			}else {
				if ( score != pVal) {
					delayedVals.push( {
						ctr: pDelay,
						val: pVal - getRealValue()
					});
				}
			}
		}
	}
}