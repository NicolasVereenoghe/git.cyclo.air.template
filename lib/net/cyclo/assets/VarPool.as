package net.cyclo.assets {
	
	/**
	 * pool de valeurs de variables ; utilisé pour itérer dans le domaine de valeurs pour désigner un ensemble d'assets
	 * 
	 * @author	nico
	 */
	public class VarPool {
		/** table de variables du pool (AssetVarDesc) ; on est censé ne pas avoir de doublon ! */
		protected var vars		: Array;
		
		/**
		 * constructeur
		 */
		public function VarPool() { vars = new Array();}
		
		/**
		 * on ajoute une variable au pool ; attention, il ne faut pas ajouter une variable qu'on a déjà mis, sinon le calul de pool sera faux
		 * @param	pVar	variable à ajouter
		 */
		public function addVar( pVar : AssetVarDesc) : void { vars.push( pVar);}
		
		/**
		 * on calcule le cardinal de l'ensemble des combinaisons des valeurs de ce pool
		 * @return	nombre d'éléments dans le pool
		 */
		public function get length() : int {
			var lCard	: int	= 1;
			var lI		: int;
			
			for( lI = 0 ; lI < vars.length ; lI++) lCard *= vars[ lI].length;
			
			return lCard;
		}
		
		/**
		 * on substitue les variables trouvées par un set de valeurs tirées du pool de valeur possible
		 * @param	pNode	node xml d'asset dans le lequel on va opérer aux substitutions
		 * @param	pIPool	indice d'itération dans le pool
		 * @return	node xml avec ses variables substituées par des valeurs
		 */
		public function substituteVars( pNode : XML, pIPool : int) : XML {
			var lStr	: String;
			var lMap	: Object;
			var lI		: String;
			
			if( vars.length > 0){
				lStr	= pNode.toString();
				lMap	= getVarValAt( pIPool);
				
				for( lI in lMap) lStr = lStr.replace( new RegExp( lI, "g"), lMap[ lI]);
				
				return new XML( lStr);
			}else return pNode;
		}
		
		/**
		 * on construit une map de valeurs associées à leur variable respective pour un certain indice d'itération dans le pool
		 * @param	pI	indice d'itération de pool
		 * @return	map de valeurs indexées par id de variable associée
		 */
		protected function getVarValAt( pI : int) : Object {
			var lMap	: Object	= new Object();
			var lI		: int;
			
			for( lI = 0 ; lI < vars.length ; lI++) {
				lMap[ vars[ lI].id] = vars[ lI].getVal( pI % vars[ lI].length);
				
				pI = pI / vars[ lI].length;
			}
			
			return lMap;
		}
	}
}