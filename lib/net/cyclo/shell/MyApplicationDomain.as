package net.cyclo.shell {
	import flash.system.ApplicationDomain;
	
	/**
	 * association de domaine d'application à un nom de label identifiant (ApplicationDomain étant une classe finale, on fait une composition)
	 * 
	 * @author	nico
	 */
	public class MyApplicationDomain {
		/**
		 * label identifiant de l'ApplicationDomain, utilisée dans l'ApplicationDomainMgr
		 */
		public var _id		: String;
		
		/**
		 * instance de domaine d'appication associée
		 */
		public var _domain	: ApplicationDomain;
		
		/**
		 * construction d'une association nom de label / domaine d'application
		 * @param	pDomId	label identifiant
		 * @param	pAppDom	domaine d'application associé
		 */
		public function MyApplicationDomain( pDomId : String, pAppDom : ApplicationDomain) {
			_id		= pDomId;
			_domain	= pAppDom;
		}
		
		/**
		 * on récupère le label identifiant du domaine
		 * @return	label identifiant
		 */
		public function get id() : String { return _id;}
		
		/**
		 * on récupère l'instance de domaine d'application définie
		 * @return	domaine d'application
		 */
		public function get domain() : ApplicationDomain { return _domain;}
	}
}