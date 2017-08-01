package net.cyclo.effect {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import net.cyclo.utils.UtilsMaths;
	
	/**
	 * déformation d'un clip avec effet de cisaillement : 3d homothétique
	 * on joue sur le skew et le scale du contenu passé au manager (matrice de transformation, propriétés a et b)
	 * 
	 * @author nico
	 */
	public class MySkewMgr {
		/** défomation en scale dite extrême ; on utilise le contenu en-dessous de ça, sinon on masque */
		protected var SCALE_LIMIT							: Number									= .15;
		
		/** cos d'orientation du motif */
		protected var motifCos								: Number									= 0;
		/** sin d'orientation du motif */
		protected var motifSin								: Number									= 0;
		/** orientation du motif en rad */
		protected var motifA								: Number									= 0;
		/** distance du point de fuite */
		protected var motifFuiteX							: Number									= 0;
		/** distance de point de fuite du motif 2 ; -1 si non définie */
		protected var motifFuiteX2							: Number									= -1;
		/** matrice de transformation initiale du contenu restituée en destruction de composant ; pas besoin pour l'éventuel contenu 2 car ne sert pas à calculer l'init en cas de réut (push d'instances) */
		protected var initMtrx								: Matrix									= null;
		
		/** contenu à déformer ; contient un mcFuite dont le x marque la position du point de fuite au repos ; le rotation du contenu donne l'orientation du motif */
		protected var content								: DisplayObjectContainer					= null;
		
		/** contenu alternatif à utiliser quand la déformation est trop forte, sinon null pour rien afficher dans un cas extrême */
		protected var content2								: DisplayObjectContainer					= null;
		
		/**
		 * initialisation
		 * @param	pContent	contenu à déformer ; contient un mcFuite dont l'origine marque la position du point de fuite au repos
		 * @param	pContent2	contenu alternatif à utiliser quand la déformation est trop forte, sinon null pour rien afficher dans un cas extrême
		 */
		public function init( pContent : DisplayObjectContainer, pContent2 : DisplayObjectContainer = null) : void {
			content		= pContent;
			motifFuiteX	= getSkewFuite().x;
			motifA		= pContent.rotation * UtilsMaths.COEF_DEG_2_RAD;
			motifCos	= Math.cos( motifA);
			motifSin	= Math.sin( motifA);
			initMtrx	= pContent.transform.matrix;
			
			if ( pContent2 != null) {
				content2		= pContent2;
				motifFuiteX2	= getSkewFuite2().x;
			}
		}
		
		/**
		 * destruction
		 */
		public function destroy() : void {
			content.transform.matrix = initMtrx;
			content = null;
			initMtrx = null;
			content2 = null;
		}
		
		/**
		 * forcer l'état invisible
		 */
		public function hide() : void {
			content.visible = false;
			
			if ( motifFuiteX2 > 0) content2.visible = false;
		}
		
		/**
		 * on effectue le cisaillement
		 * @param	pToCenter	coordonnées du nouveau point de fuite dans le 
		 */
		public function doSkew( pToCenter : Point) : void {
			var lScalarX	: Number		= motifCos * pToCenter.x + motifSin * pToCenter.y;
			var lScalarY	: Number		= motifCos * pToCenter.y - motifSin * pToCenter.x;
			var lMtrx		: Matrix;
			
			if ( Math.abs( lScalarX / motifFuiteX) >= SCALE_LIMIT) {
				lMtrx		= new Matrix( lScalarX / motifFuiteX, lScalarY / motifFuiteX);
				
				lMtrx.rotate( motifA);
				content.transform.matrix = lMtrx;
				
				content.visible = true;
				
				if ( motifFuiteX2 > 0) content2.visible = false;
			}else {
				content.visible = false;
				
				if ( motifFuiteX2 > 0) {
					if ( Math.abs( lScalarX / motifFuiteX2) >= SCALE_LIMIT) {
						lMtrx		= new Matrix( lScalarX / motifFuiteX2, lScalarY / motifFuiteX2);
						
						lMtrx.rotate( motifA);
						content2.transform.matrix = lMtrx;
						
						content2.visible = true;
					}else content2.visible = false;
				}
			}
		}
		
		/**
		 * récupère ref sur point de fuite du contenu
		 * @return	mc point de fuite dont x donne distance de celui-ci
		 */
		protected function getSkewFuite() : DisplayObject { return content.getChildByName( "mcFuite"); }
		
		/**
		 * récupère ref sur point de fuite du contenu 2
		 * @return	mc point de fuite dont x donne distance de celui-ci
		 */
		protected function getSkewFuite2() : DisplayObject { return content2.getChildByName( "mcFuite"); }
	}
}