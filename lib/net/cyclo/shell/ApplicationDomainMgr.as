package net.cyclo.shell {
	import flash.system.ApplicationDomain;

	/**
	 * gestionnaire de dommaines d'application en les collectionant par nom
	 * 
	 * @author nico
	 */
	public class ApplicationDomainMgr {
		/**
		 * singleton
		 */
		protected static var instance				: ApplicationDomainMgr			= null;
		
		/**
		 * map de MyApplicationDomain indexées par nom label du domaine d'application
		 */
		protected var domains						: Object;
		
		public function ApplicationDomainMgr() { domains = new Object();}
		
		/**
		 * donne le singleton, le crée si pas encore instancié
		 * @return	réf sur le singleton
		 */
		public static function getInstance() : ApplicationDomainMgr {
			if( ! instance) instance = new ApplicationDomainMgr();
			
			return instance;
		}
		
		/**
		 * renvoie un ApplicationDomain créé précédemment (pendant un loading de fichier normalement)
		 * @param pDomId	label identifiant de domaine d'application
		 * @return ApplicationDomain demandé, null si il n'a pas été créé et n'est pas référencé
		 */
		public function getDomain( pDomId : String) : ApplicationDomain { return MyApplicationDomain( domains[ pDomId]).domain;}
		
		/**
		 * donne le domaine d'application correspondant au nom de label spécifié ; si le domaine n'existe pas, on le crée
		 * @param	pDomId	label identifiant du domaine recherché ou à créer ; si on passe "" ou null, le domaine est non défini
		 * @return	domaine d'application correspondant ou crée pour ce label, ou null si domaine non défini
		 */
		public function createDomain( pDomId : String) : ApplicationDomain {
			if( ! pDomId) return null;
			
			if( ! domains[ pDomId]) domains[ pDomId] = new MyApplicationDomain( pDomId, new ApplicationDomain( ApplicationDomain.currentDomain));
			
			return MyApplicationDomain( domains[ pDomId]).domain;
		}
		
		/**
		 * libère de la collection un domaine référencé par le manager
		 * @param pDomId	label identifiant du domaine recherché ou à créer ; si on passe "" ou null, le domaine est non défini
		 */
		public function destroyDomain( pDomId : String) : void { if( domains[ pDomId] != null) delete domains[ pDomId];}
	}
}