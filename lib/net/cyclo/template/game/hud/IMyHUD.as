package net.cyclo.template.game.hud {
	import net.cyclo.template.shell.IGameShell;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * interface de HUD de jeu
	 * @author nico
	 */
	public interface IMyHUD {
		/**
		 * initialisation du HUD
		 * @param	coque du jeu dont on gère le HUD
		 * @param	pContainer	le conteneur où attacher le rendu graphique du HUD
		 * @param	pType		nom identifiant d'un type de HUD
		 */
		function init( pShell : IGameShell, pContainer : DisplayObjectContainer, pType : String) : void;
		
		/**
		 * destruction de l'interface HUD
		 */
		function destroy() : void;
		
		/**
		 * on bascule la pause
		 * @param	pPause	true pour passer en pause, false pour reprendre la lecture
		 */
		function switchPause( pPause : Boolean) : void;
		
		/**
		 * on réoriente le contenu orientable de la fenêtre si le le device a été tourné
		 */
		function updateRotContent() : void;
	}
}