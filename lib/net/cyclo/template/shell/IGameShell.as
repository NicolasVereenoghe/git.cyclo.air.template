package net.cyclo.template.shell {
	import net.cyclo.template.game.hud.IMyHUD;
	import net.cyclo.template.game.IGameMgr;
	import net.cyclo.template.shell.datas.SavedDatas;
	import net.cyclo.template.shell.score.MyScore;
	
	/**
	 * interface de shell de jeu
	 * @author nico
	 */
	public interface IGameShell {
		/**
		 * on signale au shell que le jeu qu'on a initialisé est prêt à être lancé
		 */
		function onGameReady() : void;
		
		/**
		 * on signale la progression de chargement du jeu ; la fin de progression sera signalée par ::onGameReady
		 * @param	pRate	taux de progression [0 .. 1]
		 */
		function onGameProgress( pRate : Number) : void;
		
		/**
		 * on signale au shell que le jeu en cours est quitté ; on n'est pas arrivé à son terme, c'est un exit prématuré ; le shell va détruire le jeu (IGMgr::destroy)
		 */
		function onGameAborted() : void;
		
		/**
		 * on signale que le jeu en cours est arrivé à son terme
		 * @param	pScore		descripteur de score marqué pour ce jeu ; null si pas de score défini
		 * @param	pSavedDatas	réf sur les données à sauver du jeu ; si défini, on effectue l'écriture de données de résultat de jeu dans cette instance, et on sauvegarde ; laisser null pour ne rien gérer
		 */
		function onGameover( pScore : MyScore = null, pSavedDatas : SavedDatas = null) : void;
		
		/**
		 * on demande d'activer le HUD d'un jeu ; c'est un instanciateur de HUD
		 * @param	pType	nom identifiant d'un type de HUD ; permet d'avoir des variation de HUD si plusieurs jeux sont gérés ; null pour le type par défaut
		 * @return	le gestionnaire de HUD que l'on vient d'activer
		 */
		function enableGameHUD( pType : String) : IMyHUD;
		
		/**
		 * on récupère la référence sur le jeu en cours
		 * @return	ref sur jeu en cours ou null si aucun
		 */
		function getCurGame() : IGameMgr;
	}
}