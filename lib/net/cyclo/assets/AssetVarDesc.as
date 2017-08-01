package net.cyclo.assets {
	
	/**
	 * descripteur d'une variable d'asset
	 * 
	 * @author	nico
	 */
	public class AssetVarDesc {
		/** id de variable */
		public var id			: String;
		
		/** table de valeurs possibles (VarValue) ; attention, les valeurs peuvent être composites et elles-même présenter une liste de valeurs */
		protected var values	: Array;
		
		/**
		 * constructeur
		 * @param	pVar	xml de description de la variable
		 */
		public function AssetVarDesc( pVar : XML) {
			var lVals	: Array	= pVar.value[ 0].toString().split( ",");
			var lI		: int;
			
			id		= pVar.id[ 0].toString();
			values	= new Array();
			
			for( lI = 0 ; lI < lVals.length ; lI++){
				values.push( new VarValue( String( lVals[ lI])));
			}
		}
		
		/**
		 * nombre de valeurs que peut prendre la variable
		 * @return	vcardinal du domaine de valeurs
		 */
		public function get length() : int {
			var lLen	: int	= 0;
			var lI		: int;
			
			for( lI = 0 ; lI < values.length ; lI++) lLen += values[ lI].length;
			
			return lLen;
		}
		
		/**
		 * on retourne la valeur élémentaire se trouvant à un certain index
		 * @param	pI	indice de valeur élémentaire ; attention, pas de contrôle de borne
		 * @return	valeur élémentaire
		 */
		public function getVal( pI : int) : String {
			var lI : int;
			
			for( lI = 0 ; lI < values.length ; lI++){
				if( pI >= values[ lI].length) pI -= values[ lI].length;
				else break;
			}
			
			return values[ lI].getVal( pI);
		}
	}
}