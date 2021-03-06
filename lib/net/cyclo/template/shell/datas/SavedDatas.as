package net.cyclo.template.shell.datas {
	
	/**
	 * descripteur de données sauvegardées
	 * @author	nico
	 */
	public class SavedDatas {
		/** séparateur de champ des couples clef/valeur sauvés */
		protected var SEP					: String				= "#";
		/** séparateur de clef et valeur */
		protected var STO					: String				= "=";
		
		/** map de clefs / valeurs indexée par clef */
		protected var datas					: Object;
		
		/**
		 * on construit un descripteur de données à sauver
		 * @param	pDatas	données sous forme de string ; laisser null pour créer un descripteur vide
		 * @param	pSep	séparateur de blocs de données ; laisser null pour le séparateur par défaut
		 * @param	pSto	séparateur entre clefs et valeurs ; laisser null pour le séparateur par défaut
		 */
		public function SavedDatas( pDatas : String = null, pSep : String = null, pSto : String = null) {
			if ( pSep != null) SEP = pSep;
			if ( pSto != null) STO = pSto;
			
			if ( pDatas != null) setDatas( pDatas);
			else datas = new Object();
		}
		
		/**
		 * on définit une valeur pour la clef désignée
		 * @param	pKey	clef identifiante
		 * @param	pVal	valeur de la clef spécifiée ; on utilise une string pour la serialization
		 */
		public function setKeyValue( pKey : String, pVal : String) : void { datas[ pKey] = pVal;}
		
		/**
		 * on récupère la valeur associée à une clef
		 * @param	pKey	clef identifiante
		 * @return	valeur correspondant à la clef spécifiée, ou null si rien de défini
		 */
		public function getKeyValue( pKey : String) : String {
			if ( datas[ pKey] != undefined) return datas[ pKey];
			else return null;
		}
		
		/**
		 * on récupère l'ensemble des données serialisées
		 * @return	représentation sous forme de string des données à sauver
		 */
		public function getDatas() : String {
			var lSerial	: String	= "";
			var lKey	: String;
			
			for ( lKey in datas) {
				if ( lSerial != "") lSerial += SEP;
				
				lSerial += lKey + STO + datas[ lKey];
			}
			
			return lSerial;
		}
		
		/**
		 * on défini les données à partir d'une chaine de serialisation
		 * @param	pDatas	données sous forme de string
		 */
		public function setDatas( pDatas : String) : void {
			var lDatas	: Array	= pDatas.split( SEP);
			var lKeyVal	: Array;
			var lI		: int;
			
			datas = new Object();
			
			for ( lI = 0 ; lI < lDatas.length ; lI++) {
				lKeyVal	= lDatas[ lI].split( STO);
				
				datas[ lKeyVal[ 0]] = lKeyVal[ 1];
			}
		}
	}
}