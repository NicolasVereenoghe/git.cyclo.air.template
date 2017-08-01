package net.cyclo.shell.device {
	import flash.events.KeyboardEvent;
	
	/**
	 * interface de gestionnaire de fonctionnalités de device mobile (ex.: mise en pause, rotation écran) du rendu en cours
	 * @author nico
	 */
	public interface IDeviceCurRenderMgr {
		/**
		 * on est notifié de la désactivation de l'appli
		 */
		function onBrowseDeactivate() : void;
		
		/**
		 * on est notifié de la réactivation de l'appli
		 */
		function onBrowseReactivate() : void;
		
		/**
		 * on est notifié d'une navigation arrière (ex.: bouton back sous android)
		 * @param	pE	event de navigation arrière
		 */
		function onBrowseBack( pE : KeyboardEvent) : void;
	}
}