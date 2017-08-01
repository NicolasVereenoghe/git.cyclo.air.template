package net.cyclo.assets {
	
	/**
	 * struct qui décrit un critère de recherche d'un ensemble d'assets
	 * 
	 * @author	nico
	 */
	public class PatternAsset {
		/** tag utilisé pour désigner une recherche d'identifiant par rapport aux noms de groupe */
		public static const FIND_ON_GROUP	: String	= "findOnGroup";
		/** tag utilisé pour désigner une recherche d'identifiant par rapport aux noms d'identifiant des assets */
		public static const FIND_ON_ID		: String	= "findOnId";
		/** tag utilisé pour désigner une recherche d'identifiant par rapport aux noms de domaine */
		public static const FIND_ON_DOMAIN	: String	= "findOnDomain";
		/** tag utilisé pour désigner une recherche d'identifiant par rapport aux noms de fichiers */
		public static const FIND_ON_FILE	: String	= "findOnFile";
		/** tag utilisé pour désigner une recherche d'identifiant par rapport aux noms d'export */
		public static const FIND_ON_EXPORT	: String	= "findOnExport";
		
		/** tag utilisé pour désigner une recherche sur l'ensemble du champ identifiant (le champ doit être exactement identique) */
		public static const MATCH_ALL		: String	= "matchAll";
		/** tag utilisé pour désigner une recherche sur une partie du champ identifiant (le champ doit contenir l'identifiant recherché, en préfixe / suffixe, ou substring) */
		public static const MATCH_SUBSTR	: String	= "matchSubstr";
		
		/** la chaîne identifiante de recherche */
		protected var find					: String;
		/** nature des champs sur lesquels on effectue la recherche */
		protected var typeFind				: String;
		/** type de recherche : l'ensemble du champ doit correspondre (MATCH_ALL), ou juste une partie (MATCH_SUBSTR) */
		protected var typeMatch				: String;
		
		/**
		 * constructeur d'un descripteur de recherche d'assets
		 * @param	pFind		chaîne identifiante
		 * @param	pTypeFind	nature des champs sur lesquels on effectue la recherche
		 * @param	pTypeMatch	type de recherche : l'ensemble du champ doit correspondre (MATCH_ALL), ou juste une partie (MATCH_SUBSTR)
		 */
		public function PatternAsset( pFind : String, pTypeFind : String = FIND_ON_ID, pTypeMatch : String = MATCH_SUBSTR) {
			find		= pFind;
			typeFind	= pTypeFind;
			typeMatch	= pTypeMatch;
		}
		
		/**
		 * on vérifie si un asset correspond bien au pattern de recherche
		 * @param	pAsset	descripteur d'asset auquel on confronte au pattern de recherche
		 * @return	true si le descripteur d'asset correspond, false sinon
		 */
		public function match( pAsset : AssetDesc) : Boolean {
			var lI		: String;
			
			if( typeFind == FIND_ON_GROUP){
				for( lI in pAsset.groups){
					if( matchGroup( pAsset.groups[ lI])) return true;
				}
			}else if( typeFind == FIND_ON_ID) return cmpStr( pAsset.id);
			else if( typeFind == FIND_ON_DOMAIN) return cmpStr( pAsset.file.applicationDomainId);
			else if( typeFind == FIND_ON_FILE) return cmpStr( pAsset.file.name);
			else if( typeFind == FIND_ON_EXPORT) return cmpStr( pAsset.export ? pAsset.export : pAsset.exportTemplate);
			
			return false;
		}
		
		/**
		 * on vérifie si un groupe ou ses parents correspond au pattern de recherche
		 * @param	pGroup	groupe (et ses parents) que l'on confronte au critère de recherche du pattern, ou null si plus aucun groupe
		 * @return	true si ça correspond, false sinon
		 */
		protected function matchGroup( pGroup : AssetGroupDesc) : Boolean {
			if( ! pGroup) return false;
			else if( cmpStr( pGroup.id)) return true;
			else return matchGroup( pGroup.parent);
		}
		
		/**
		 * on effectue une comparaison de chaîne en fonction de ce qui a été défini comme critère de recherche (soit tout la chaîne du champ doit correspondre, soit au moins une "substring")
		 * @param	pStr	valeur de string du champ que l'on compare
		 * @return	true si ça correspond, false sinon
		 */
		protected function cmpStr( pStr : String) : Boolean {
			if( typeMatch == MATCH_ALL) return pStr == find;
			else return pStr && pStr.indexOf( find) >= 0;
		}
	}
}