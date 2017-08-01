package net.cyclo.ui.local {
	
	/**
	 * interface d'écoute d'event de changement de localisation
	 * @author	nico
	 */
	public interface ILocalListener {
		/**
		 * on notifie le listener qu'un changement de localisation a eu lieu et qu'il doit rafraichir son contenu localisé
		 */
		function onLocalUpdate() : void;
	}
}