package net.cyclo.ui.local {
	import flash.utils.Dictionary;
	
	/**
	 * gestionnaire de localisation
	 * @author	nico
	 */
	public class LocalMgr {
		/** ref sur le singleton ; null tant que pas de singleton */
		protected static var current		: LocalMgr		= null;
		
		/** liste de xml de localisation (Array of XML) */
		protected var xmls					: Array			= null;
		
		/** index de xml de localisation courrement utilisé */
		protected var curLangInd			: int			= 0;
		
		/** collection de listener de mise à jour de localisation */
		protected var listeners				: Dictionary	= null;
		
		/**
		 * constructeur : on crée et on initialise le singleton ; attention, une seule instance acceptée, sinon une erreur est levée
		 * @param	pXmls	liste de xml de localisation (Array of XML)
		 */
		public function LocalMgr( pXmls : Array) {
			if ( current != null) {
				throw new Error( "LocalMgr::LocalMgr : il y a déjà une instance de déclarée en singleton");
			}
			
			current		= this;
			xmls		= pXmls;
			listeners	= new Dictionary();
			
			LocalTextField;
		}
		
		/**
		 * on bascule la langue en cours vers une autre ; on dispatch l'event de changement à tous les listener ; rien ne se passe si l'id de langue correspond à celui en cours
		 * @param	pLangInd	indice de langue qui devient celle en cours ; 0 .. n-1, avec n le nombre de langue définies dans le gestionnaire ; l'indice correspond à l'index dans la collection du gestionnaire (::xmls)
		 * @param	pNoDispatch	mettre true pour empêcher la propagation de l'info de mise à jour de langue ; laisser false par défaut pour dispatcher
		 */
		public function swapLang( pLangInd : int, pNoDispatch : Boolean = false) : void {
			var lListener	: ILocalListener;
			
			if ( pLangInd != curLangInd) {
				curLangInd = pLangInd;
				
				if ( ! pNoDispatch) {
					for each( lListener in listeners) lListener.onLocalUpdate();
				}
			}
		}
		
		/**
		 * on récupère le nombre de langues définies
		 * @return	nombre de langues définies
		 */
		public function getNbLangs() : int { return xmls.length; }
		
		/**
		 * on récupère l'indice de langue en cours
		 * @return	indice de langue : 0 .. n-1
		 */
		public function getCurLangInd() : int { return curLangInd;}
		
		/**
		 * on ajoute un listener de mise à jour de localisation
		 * @param	pListener	écouteur de mise à jour
		 */
		public function addListener( pListener : ILocalListener) : void { listeners[ pListener] = pListener; }
		
		/**
		 * on retire un listener de mise à jour de localisation
		 * @param	pListener	écouteur de mise à jour
		 */
		public function remListener( pListener : ILocalListener) : void { delete listeners[ pListener];}
		
		/**
		 * on récupère la valeur texte correspondant à la clef d'un champ localisé
		 * @param	pId				identifiant de texte localisé
		 * @param	pForceLangInd	laisser -1 par défaut pour récupérer le texte dans la langue définie comme courrante ; préciser un indice de langue si on cherche une traduction pour une langue particulière
		 * @return	valeur de texte correspondante à l'id de localisation ; si l'identifiant ne correspond à rien, on retourne null
		 */
		public function getLocalTxt( pId : String, pForceLangInd : int = -1) : String {
			var lInd	: int		= pForceLangInd != -1 ? pForceLangInd : curLangInd;
			var lRes	: *			= ( xmls[ lInd] as XML).local.(@id == pId)[ 0];
			
			return lRes != undefined ? String( lRes) : null;
		}
		
		/**
		 * on récupère la réf sur le singleton
		 * @return	réf sur singleton, ou null si pas encore instancié
		 */
		public static function getInstance() : LocalMgr { return current; }
	}
}