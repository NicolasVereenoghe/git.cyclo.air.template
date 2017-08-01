package net.cyclo.paddle {
	
	/**
	 * un écouteur de changement de mode d'un switcher graphique : on écoute les changements de points de référence, le début d'une animation de switch et sa fin
	 * @author nico
	 */
	public interface ISwitchModeListener {
		/**
		 * on capte la notification de changement de référentiel
		 * @param	pFrom	{ x, y, z} de l'ancien référentiel ( inclinaison des axes x, y, z sur [ -PI/2 .. PI/2]) ; null si pas d'antécédent
		 * @param	pTo		{ x, y, z} du nouveau référentiel ( inclinaison des axes x, y, z sur [ -PI/2 .. PI/2])
		 */
		function onRefChange( pFrom : Object, pTo : Object) : void;
		
		/**
		 * on capte le début / fin d'une anim de switch de mode
		 * @param	pIsBegin	true pour le début, false pour la fin
		 */
		function onSwitchModeAnim( pIsBegin : Boolean) : void;
	}
}