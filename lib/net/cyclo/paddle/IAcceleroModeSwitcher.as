package net.cyclo.paddle {
	
	/**
	 * interface de notification de switch de mode de l'accéléromètre
	 * @author	nico
	 */
	public interface IAcceleroModeSwitcher {
		/**
		 * on capte la notification de changement de référentiel
		 * @param	pFrom	{ x, y, z} de l'ancien référentiel ( inclinaison des axes x, y, z sur [ -PI/2 .. PI/2]) ; null si pas d'antécédent
		 * @param	pTo		{ x, y, z} du nouveau référentiel ( inclinaison des axes x, y, z sur [ -PI/2 .. PI/2])
		 */
		function onRefChange( pFrom : Object, pTo : Object) : void;
	}
}