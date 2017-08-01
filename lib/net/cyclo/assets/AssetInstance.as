package net.cyclo.assets {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * une instance d'asset
	 * conteneur de la ressource graphique d'asset et du template associé (si définis)
	 * permet de faire l'abstraction de ce qui est défini ou pas
	 * 
	 * si on a besoin de spécialiser cette classe, on propose de passer par le pattern du wrapper
	 * (comme pour par exemple définir une procédure de réinitialisation ;))
	 * 
	 * @author	nico
	 */
	public class AssetInstance extends Sprite {
		/** réf sur l'export de l'asset, ou null si aucun ; plutôt utiliser le getter "content" qui fait l'abstraction de ce qui est défini ou pas entre l'export et le template */
		public var export			: DisplayObject;
		/** réf sur le template de l'asset, ou null si aucun ; plutôt utiliser le getter "content" qui fait l'abstraction de ce qui est défini ou pas entre l'export et le template */
		public var template			: DisplayObject;
		
		/** réf sur le descripteur d'asset associé */
		protected var _desc			: AssetDesc;
		
		/**
		 * construction
		 * @param	pDesc		réf sur le descripteur associé
		 * @param	pExport		movie clip du rendu exporté, ou null si aucun de défini
		 * @param	pTemplpate	movie clip du template exporté, ou null si aucun de défini
		 * @param	pAlpha		alpha du template de cet asset (uniquement utilisé si un export est aussi défini, pour debug) : 0..1
		 */
		public function AssetInstance( pDesc : AssetDesc, pExport : DisplayObject, pTemplate : DisplayObject, pAlpha : Number) {
			_desc = pDesc;
			
			if( pExport) export = addChild( pExport);
			
			if( pTemplate){
				template = addChild( pTemplate);
				
				if( pAlpha == 0) template.visible = false;
				else template.alpha = pAlpha;
			}
			
			UtilsMovieClip.recursiveStop( this);
		}
		
		/**
		 * on récupère le contenu de l'asset
		 * @return	réf sur le movie clip contenu de l'asset ; si export d'asset défini, on retourne cet export ; si pas d'export, on prendra le template (temporaire en attendant qu'il soit inétgré) ; sinon on retourne null, mais ça peut poser soucis !! faut que ce soit défini !
		 */
		public function get content() : DisplayObject {
			if( export) return export;
			else if( template) return template;
			else return null;
		}
		
		/**
		 * getter sur le descripteur d'asset de l'instance
		 * @return	descripteur d'asset
		 */
		public function get desc() : AssetDesc { return _desc;}
		
		/**
		 * on libère l'asset ; on suppose qu'il va être retiré de la scène et que toute référence à cet asset sera éliminée ; cette tâche reste à la charge de l'appelant
		 * 
		 * attention, il appartient à l'appelant de dégager son instance de la scène, et de la réinitialiser ("comme on fait son lit on se couche" ;))
		 * pour qu'à sa prochaine utilisation elle soit dans un état exploitable ; pas de dépendance ici avec la structure interne des assets,
		 * c'est à la charge de l'utilisateur (pour l'export et le tempate) !
		 */
		public function free() : void { _desc.freeAssetInstance( this);}
	}
}