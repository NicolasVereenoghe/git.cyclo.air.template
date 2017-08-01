package net.cyclo.template.shell {
	import net.cyclo.loading.file.MyFile;
	import net.cyclo.template.screen.MyScreen;
	import net.cyclo.template.shell.datas.SavedDatas;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * interface de gestionnaire de coque de jeu
	 * @author nico
	 */
	public interface IShell {
		/**
		 * initilisation de la coque du jeu
		 * @param	pStage		stage de l'application
		 * @param	pLocalXML	xml de localisation (XML), ou liste de xml de localication (Array of XML), ou null si non dispo en local
		 * @param	pAssetsXML	xml de description d'assets, ou null si non dispo en local
		 * @param	pLocalFile	descripteur de fichier de localisation à charger (MyFile), ou liste de descripteurs de fichiers à charger (Array of MyFile), null si aucun
		 * @param	pAssetsFile	descripteur de fichier d'assets à charger, null si aucun
		 */
		function initShell( pContainer : DisplayObjectContainer, pLocalXML : Object = null, pAssetsXML : XML = null, pLocalFile : Object = null, pAssetsFile : MyFile = null) : void;
		
		/**
		 * on signale au shell que l'écran est en train de se fermer
		 * @param	pScreen	instance d'écran qui est en train de se fermer
		 * @param	pNext	instance d'écran à suivre ; donne un indice sur la transition à effectuer ; peut être laisser à null
		 */
		function onScreenClose( pScreen : MyScreen, pNext : MyScreen = null) : void;
		
		/**
		 * on signale au shell qu'un écran est fermé
		 * @param	pScreen	instance d'écran qui vient de fermer
		 */
		function onScreenEnd( pScreen : MyScreen) : void;
		
		/**
		 * on signale au shell qu'un écran a fini de s'initialiser ; il est prêt à être lancé
		 * @param	pScreen	instance d'écran prête à être lancée
		 */
		function onScreenReady( pScreen : MyScreen) : void;
		
		/**
		 * on récupère les données sauvées correspondant à un identifiant de données
		 * @param	pId		identifiant de données recherchées ; laisser null pour des propriétés globales
		 * @param	pForce	true pour forcer la création de données vierges si aucune données trouvées à cet identifiant ; laisser false pour retourner null si données absentes
		 * @return	données sauvées correspondant à cet identifiant, ou null si rien de trouvé
		 */
		function getSavedDatas( pId : String, pForce : Boolean = false) : SavedDatas;
		
		/**
		 * on sauvegarde un jeu de données correspondant à un identifant de données
		 * @param	pId		identifiant du jeu de données à sauver ; laisser null pour des propriétés globales
		 * @param	pDatas	jeu de données à sauver ; null pour supprimer les données à cet identifiant
		 */
		function setSavedDatas( pId : String, pDatas : SavedDatas) : void;
	}
}