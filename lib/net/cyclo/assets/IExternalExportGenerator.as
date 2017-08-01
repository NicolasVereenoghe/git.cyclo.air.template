package net.cyclo.assets {
	import flash.display.DisplayObject;
	
	/**
	 * interface de génération d'export d'assets
	 * 
	 * @author	nico
	 */
	public interface IExternalExportGenerator {
		/**
		 * on génère un rendu vecto de l'export de l'asset
		 * @param	pExport	nom d'export du rendu vecto à générer
		 * @return	rendu vecto de l'export
		 */
		function generateExport( pExport : String) : DisplayObject;
	}
}