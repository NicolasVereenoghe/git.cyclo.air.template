package net.cyclo.assets {
	
	/**
	 * une valeur possible d'une variable ; attention, peut être composite et présenter une liste de valeurs
	 * 
	 * @author	nico
	 */
	public class VarValue {
		/** la valeur, éventuellement composite (liste de valeurs sous la forme a..z) */
		protected var value		: String;
		
		/**
		 * constructeur
		 * @param	pVal	valeur de variable ou liste de valeurs sous la forme a..z
		 */
		public function VarValue( pVal : String) { value = pVal;}
		
		/**
		 * on retourne le nombre de valeurs élémentaires qui constituent cette valeur composite
		 * @return	nombre de valeurs élémentaires
		 */
		public function get length() : int {
			var lVals : Array = value.split( "..");
			
			if( lVals.length == 1) return 1;
			else{
				if( isNaN( lVals[ 0])) return lVals[ 1].charCodeAt() - lVals[ 0].charCodeAt() + 1;
				else return parseInt( lVals[ 1]) - parseInt( lVals[ 0]) + 1;
			}
		}
		
		/**
		 * on retourne la valeur élémentaire se trouvant à un certain index
		 * @param	pI	indice de valeur élémentaire ; si la valeur "composite" est déjà élémentaire, on ignore ce paramètre ; attention, pas de contrôle de borne
		 * @return	valeur élémentaire
		 */
		public function getVal( pI : int) : String {
			var lVals	: Array	= value.split( "..");
			var lFrom	: int;
			var lRes	: int;
			var lResTxt	: String;
			var lI		: int;
			var lLen	: int;
			
			if( lVals.length == 1) return value;
			else{
				if( isNaN( lVals[ 0])) return String.fromCharCode( lVals[ 0].charCodeAt() + pI);
				else {
					lFrom	= parseInt( lVals[ 0]);
					lRes	= lFrom + pI;
					lLen	= ( lVals[ 0] as String).length;
					
					if ( lFrom.toString().length < lLen) {
						lResTxt	= lRes.toString();
						
						for ( lI = lResTxt.length ; lI < lLen ; lI++) lResTxt = "0" + lResTxt;
						
						return lResTxt;
					}else return lRes.toString();
				}
			}
		}
	}
}