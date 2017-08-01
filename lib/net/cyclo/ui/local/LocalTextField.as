package net.cyclo.ui.local {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	
	/**
	 * gère la localisation d'un champ texte ; lors de la construction du LocalTextField, on retrouve le champ ciblé et on l'initialise en fonction des paramètres de l'instance
	 * @author nico
	 */
	public class LocalTextField extends Sprite implements ILocalListener {
		/**
		 * nom d'instance du champ texte ciblé ; doit se trouver au même niveau d'imbrication que le composant
		 */
		[Inspectable(name="1 nom d'instance de TextField géré",type="String",defaultValue="")]
		public var targetName				: String		= "";
		
		/**
		 * nom de champ de localisation ; c'est l'identifiant qui va nous permettre de trouver la valeur de texte localisé du champ texte ciblé
		 */
		[Inspectable(name = "2 id de localisation", type = "String", defaultValue = "")]
		public var localId					: String		= "";
		
		/**
		 * flag indiquant si on a un rendu de type html (true) ou texte (false)
		 */
		[Inspectable(name = "3 html ?", type = "Boolean", defaultValue = false)]
		public var isHtml					: Boolean		= false;
		
		/**
		 * indice de langue pour forcer la traduction choisie ; laisser -1 pour prendre la langue définie par défaut par l'appli
		 */
		[Inspectable(name = "4 force lang indice", type = "Number", defaultValue = -1)]
		public var forceLangInd				: int			= -1;
		
		/**
		 * flag indiquant si on adapte la taille de la font si le texte dépasse en largeur (true) ; par défaut, pas d'adaptation (false)
		 */
		[Inspectable(name = "5 autoSize", type = "Boolean", defaultValue = false)]
		public var autoSize					: Boolean		= false;
		
		/**
		 * construction
		 */
		public function LocalTextField() {
			super();
			
			visible = false;
			
			addEventListener( Event.ADDED_TO_STAGE, onAdded, false, 0, true);
		}
		
		/**
		 * on est notifié de la lecture des propriétés de composant
		 * @param	pNoInit	true si pas encore initialisé, false une fois que les propriétés sont lues
		 */
		public function set componentInspectorSetting ( pNoInit : Boolean ) : void { if ( ! pNoInit) updateLocal();}
		
		/** @inheritDoc */
		public function onLocalUpdate() : void { updateLocal();}
		
		/**
		 * on met à jour le contenu localisé
		 */
		protected function updateLocal() : void {
			if ( isHtml) Object( parent.getChildByName( targetName)).htmlText = LocalMgr.getInstance().getLocalTxt( localId, forceLangInd);
			else Object( parent.getChildByName( targetName)).text = LocalMgr.getInstance().getLocalTxt( localId, forceLangInd);
		}
		
		/**
		 * on captude l'event d'ajout sur la scène
		 * @param	pE	event d'ajout sur scène
		 */
		protected function onAdded( pE : Event) : void {
			removeEventListener( Event.ADDED_TO_STAGE, onAdded);
			addEventListener( Event.REMOVED_FROM_STAGE, onRemove);
			LocalMgr.getInstance().addListener( this);
		}
		
		/**
		 * on capture l'event de dégagement de la scène
		 * @param	pE	event de virage de la scène
		 */
		protected function onRemove( pE : Event) : void {
			removeEventListener( Event.REMOVED_FROM_STAGE, onRemove);
			LocalMgr.getInstance().remListener( this);
		}
	}
}