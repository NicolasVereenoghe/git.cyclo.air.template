package net.cyclo.loading {
	
	/**
	 * interface que doivent implémenter les objets qui veulent écouter la progression d'un chargement de fichiers assuré par un CycloLoader
	 * @author	nico
	 */
	public interface ICycloLoaderListener {
		/**
		 * on est notifié de la progression du chargement réalisé par l'instance passée en paramètres
		 * @param	pLoader le loader de fichiers qui notifie sa progression
		 */
		function onLoadProgress( pLoader : CycloLoader) : void;
		
		/**
		 * on est notifié de la fin complète du charmenent de fichiers géré par le loader passé
		 * @param	pLoader	loder qui a fini de charger tous ses fichiers
		 */
		function onLoadComplete( pLoader : CycloLoader) : void;
		
		/**
		 * on est notifié que le fichier en cours de traitement par le chargeur de fichiers a fini de charger
		 * @param	pLoader	loder qui a fini de charger le fichier en cours de traitement
		 */
		function onCurrentFileLoaded( pLoader : CycloLoader) : void;
		
		/**
		 * on est notifié de l'erreur de chargement d'un fichier
		 * @param	pLoader	loader dont le fichier en cours de chargement a échoué
		 */
		function onLoadError( pLoader : CycloLoader) : void;
	}
}