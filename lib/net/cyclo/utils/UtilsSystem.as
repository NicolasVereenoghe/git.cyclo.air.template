package net.cyclo.utils {
	import flash.system.ApplicationDomain;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	
	/**
	 * boîte à outils système
	 * 
	 * @author	nico
	 */
	public class UtilsSystem {
		/**
		 * on teste si une classe en hérite d'une autre
		 * @param	pChild	classe supposée fille
		 * @param	pMother	classe supposée mère
		 * @param	pDom	domaine d'application où chercher la relation d'héritage ; null pour le domaine d'application par défaut
		 * @return	true si pChild hérite de pMother ou si classes identiques, false sinon
		 */
		public static function doesInherit( pChild : Class, pMother : Class, pDom : ApplicationDomain = null) : Boolean {
			var lMother	: String	= getQualifiedClassName( pMother);
			var lChild	: String	= getQualifiedClassName( pChild);
			
			if ( pDom == null) pDom = ApplicationDomain.currentDomain;
			
			do {
				if ( lChild == lMother) return true;
				
				lChild	= getQualifiedSuperclassName( pChild);
				pChild	= pDom.getDefinition( lChild) as Class;
			}while ( lChild != "Object");
			
			return false;
		}
	}
}