package net.cyclo.ui {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.utils.getQualifiedClassName;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * gestion d'un compteur avec chaque chiffre qui est un movieclip (suite de représentations de 0 .. 9, puis "chiffre vide" à la 11ème frame)
	 * @author	nico
	 */
	public class MyCounter {
		/** racine des nom des modèles d"assets de chiffre du conteneur */
		protected var DIGIT_RADIX				: String					= "mc";
		
		/** liste de timelines de chiffre générés à partir des modèles parsés ; indexés par degré croissant (0 <=> unités, 1 <=> dixaines, 2 <=> centaines, ...) */
		protected var digits					: Array;
		
		/** valeur du compteur */
		protected var value						: int						= -1;
		
		/** conteneur des chiffres du compteur */
		protected var container					: DisplayObjectContainer	= null;
		
		/**
		 * construction du compteur : on parse les profondeurs du conteneur pour trouver des assets de chiffres
		 * @param	pContainer	conteneur des assets du compteur utilisé pour afficher le rendu du compteur
		 * @param	pValue		valeur initiale du compteur
		 */
		public function MyCounter( pContainer : DisplayObjectContainer, pValue : int = 0) {
			var lChild	: DisplayObject;
			var lCtr	: int;
			
			digits		= new Array();
			container	= pContainer;
			
			for ( lCtr = 0 ; lCtr < pContainer.numChildren ; lCtr++) {
				lChild	= pContainer.getChildByName( DIGIT_RADIX + lCtr);
				
				if ( lChild != null) initDigit( DisplayObjectContainer( lChild));
				else break;
			}
			
			setValue( pValue);
		}
		
		/**
		 * on set la valeur du compteur
		 * @param	pVal	valeur du compteur
		 * @param	pForce	true pour forcer la valeur, false pour laisser un éventuel comportement régler la valeur affichée ; util si on redéfinit avec un comportement d'inertie
		 * @param	pDelay	délai d'application de la valeur en frames, 0 immédiat ; util si on définit ce comportement, ici c'est de base
		 */
		public function setValue( pVal : int, pForce : Boolean = true, pDelay : int = 0) : void {
			var lVal	: String;
			var lI		: int;
			
			if ( pVal != value) {
				lVal	= pVal.toString();
				
				for ( lI = 0 ; lI < digits.length ; lI++) {
					if ( lVal.length > lI) {
						UtilsMovieClip.recursiveGotoAndStop( DisplayObjectContainer( digits[ lI]), 1 + parseInt( lVal.charAt( lVal.length - 1 - lI)))
					}else {
						UtilsMovieClip.recursiveGotoAndStop( DisplayObjectContainer( digits[ lI]), 11);
					}
				}
				
				value	= pVal;
			}
		}
		
		/**
		 * on récupère l'objet graphique représentant un chiffre
		 * @param	pI	indice de chiffre dans le compteur ; 0 <=> unités, 1 <=> dizaines, ...
		 * @return	objet graphique du chiffre, null si inexistant
		 */
		public function getDigitDisp( pI : int) : DisplayObject { return digits[ pI]; }
		
		/**
		 * on récupère la valeur du compteur
		 * @return	valeur numérique du compteur
		 */
		public function getValue() : int { return value; }
		
		/**
		 * on récupère la valeur réelle, nuance avec valeur affichée ; a du sens si redéfini pour un compteur avec inertie
		 * @return	valeur réelle
		 */
		public function getRealValue() : int { return value; }
		
		/**
		 * destruction
		 */
		public function destroy() : void {
			var lDigit	: DisplayObjectContainer;
			
			while ( digits.length > 0) {
				lDigit = DisplayObjectContainer( digits.pop());
				
				if ( lDigit is AssetInstance) {
					lDigit.parent.getChildByName( DIGIT_RADIX + digits.length).visible = true;
					
					AssetInstance( lDigit).free();
					UtilsMovieClip.free( lDigit);
				}else UtilsMovieClip.recursiveGotoAndStop( lDigit, 1);
			}
			
			digits = null;
			container = null;
		}
		
		/**
		 * initialise un modèle de chiffre pour en faire un asset de chiffre exploitable par le composant de compteur
		 * @param	pModel	modèle de chiffre
		 */
		protected function initDigit( pModel : DisplayObjectContainer) : void {
			var lId			: String		= getQualifiedClassName( pModel);
			var lAsset		: AssetInstance;
			
			UtilsMovieClip.recursiveGotoAndStop( pModel, 1);
			
			if ( ( ! ( pModel is AssetInstance)) && AssetsMgr.getInstance().getAssetDescById( lId)) {
				lAsset			= AssetsMgr.getInstance().getAssetInstance( lId);
				
				pModel.parent.addChild( lAsset);
				
				pModel.visible	= false;
				lAsset.x		= pModel.x;
				lAsset.y		= pModel.y;
				
				digits.push( lAsset);
			}else digits.push( pModel);
		}
	}
}