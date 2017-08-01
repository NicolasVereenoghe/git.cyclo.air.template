package net.cyclo.template.game {
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import net.cyclo.template.shell.datas.SavedDatas;
	import net.cyclo.template.shell.IGameShell;
	import net.cyclo.template.shell.score.MyScore;
	
	/**
	 * interface d'un gestionnaire d'une instance de jeu
	 * @author nico
	 */
	public interface IGameMgr {
		/**
		 * méthode d'initialisation du jeu ; on répondra au shell qu'on est prêt en appelant sa callback IGameShell::onGameReady
		 * @param	pShell			le shell qui gère le jeu ; quand le jeu est prêt (peu prendre plusieurs frames à s'initialiser), appeler IGameShell::onGameReady
		 * @param	pGameContainer	conteneur où attacher les éléments de jeu
		 * @param	pSavedDatas		descripteur de données sauvegardées du jeu ; null si aucune données sauvée
		 */
		function init( pShell : IGameShell, pGameContainer : DisplayObjectContainer, pSavedDatas : SavedDatas = null) : void;
		
		/**
		 * on reset le jeu pour pouvoir y jouer à nouveau depuis le début ; à la suite du reset, le jeu est remis à l'état initial en pause et attend un ::startGame pour redémarrer
		 */
		function reset() : void;
		
		/**
		 * méthode de destruction du jeu ; on libère la mémoire occupée par le jeu et on clean l'affichage (cleaner le conteneur de jeu)
		 */
		function destroy() : void;
		
		/**
		 * on demande au jeu de passer en pause, ou d'en sortir
		 * @param	pIsPause	true pour passer en pause, false pour en sortir
		 */
		function switchPause( pIsPause : Boolean) : void;
		
		/**
		 * on signale le changement d'orientation du device
		 */
		function updateRotContent() : void;
		
		/**
		 * on récupère l'identifiant de jeu
		 * @return	identifiant de jeu
		 */
		function get gameId() : String;
		
		/**
		 * on récupère le score de jeu
		 * @return	descripteur de score du jeu, ou null si non défini
		 */
		function getScore() : MyScore;
		
		/**
		 * on récupère les données de jeu à sauver
		 * @return	données de jeu à sauver ; c'est une réf partagée, on peut écrire des données dedans ; ou null si rien à sauver (ou si on veut gérer la sauvegarde en interne)
		 */
		function getDatas() : SavedDatas;
		
		/**
		 * on demande au jeu de se lancer
		 */
		function startGame() : void;
		
		/**
		 * on récupère une réf sur le shell du jeu
		 * @return	ref sur le shell du jeu
		 */
		function getShell() : IGameShell;
		
		/**
		 * méthode générique de traitement d'évènement de jeu, classés comme feedback
		 * modèle prévu pour pour traiter de manière simple les fin d'affichage de popins de chaîne / combo (conjointement avec net.cyclo.template.game.hud.FeedbackDisplayMgr)
		 * @param	pEvtId	identifiant d'event de jeu ; prévu comme identifiant de feedback de chaîne / combo
		 * @param	pLvl	niveau d'event de jeu [ 0 .. n-1] ; prévu pour niveau de chaîne / combo
		 * @param	pVal	valeur entière associé à l'évent ; prévue pour un score
		 * @param	pWXY	coordonnées d'écran du point de fin du feedback, pour gérer un effet ; null si pas défini
		 */
		function onFeedbackEnd( pEvtId : String = null, pLvl : int = 0, pVal : int = 0, pWXY : Point = null) : void;
	}
}