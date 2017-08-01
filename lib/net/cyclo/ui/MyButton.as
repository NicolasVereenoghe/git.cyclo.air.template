package net.cyclo.ui 
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.utils.getQualifiedClassName;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * gère un bouton d'interface avec les états "up", "over", "down", "select", "selectOver", "selectDown" et sa zone de hit
	 * on vérifie si les id de linkage des états trouvés dans le conteneur correspondent à des id d'assets, et si c'est le cas on les remplace par les assets correspondants
	 * pour la zone de hit, on ne ne recherche pas d'asset correspondant
	 * 
	 * @author	nico
	 */
	public class MyButton {
		/** nom du symbole d'état "up" dans le conteneur */
		public static const NAME_UP				: String					= "mcUp";
		/** nom de symbole d'état "over" dans le conteneur */
		public static const NAME_OVER			: String					= "mcOver";
		/** nom de symbole d'état "down" dans le coneneur */
		public static const NAME_DOWN			: String					= "mcDown";
		/** nom de symbole d'état "select" dans le conteneur */
		public static const NAME_SELECT			: String					= "mcSelect";
		/** nom de symbole d'état "selectDown" dans le conteneur */
		public static const NAME_SELECT_DOWN	: String					= "mcSelectDown";
		/** nom de symbole d'état "selectOver" dans le conteneur */
		public static const NAME_SELECT_OVER	: String					= "mcSelectOver";
		/** nom de symbole de zone de hit dans le conteneur */
		public static const NAME_HIT			: String					= "mcHit";
		
		/** conteneur du rendu du bouton */
		protected var container					: DisplayObjectContainer;
		
		/** instance de l'état "up" ; c'est l'état par défaut ; /!\ si non défini, risque de foirer lors des transitions d'état */
		protected var stateUp					: DisplayObject				= null;
		/** instance de l'état "over" ; null si pas d'état "over", on utilise le rendu "up" */
		protected var stateOver					: DisplayObject				= null;
		/** instance de l'état "down" ; null si pas d'état "down", on utilise le rendu "up" */
		protected var stateDown					: DisplayObject				= null;
		/** instance de l'état "select" ; null si pas d'état "select", comportement désactivé ; état par défaut du mode "select" */
		protected var stateSelect				: DisplayObject				= null;
		/** instance de l'état "selectDown" ; null si pas d'état "selectDown", comportement désactivé */
		protected var stateSelectDown			: DisplayObject				= null;
		/** instance de l'état "selectOver" ; null si pas d'état "selectOver", comportement désactivé */
		protected var stateSelectOver			: DisplayObject				= null;
		
		/** zone de hit du bouton ; si pas de symbole de défini, on utilise tout le conteneur du bouton */
		protected var hitZone					: DisplayObject				= null;
		
		/** réf sur l'instance d'état en cours ; null si pas d'état en cours (seulement pendant la construction)*/
		protected var curState					: DisplayObject				= null;
		/** réf sur l'instance d'état précédemment utilisée avant le dernier changement d'état ; null si aucun état précédent */
		protected var prevState					: DisplayObject				= null;
		
		/** flag indiquant si un état de bouton est un conteneur, on lance la lecture récursive de son contenu (true) ; false pour ne pas lire dans tous les cas */
		protected var autoPlay					: Boolean					= true;
		
		/**
		 * construction : on parse les profondeurs du conteneur pour savoir quels états sont définis
		 * @param	pContainer	conteneur à utiliser pour gérer l'affichage du bouton
		 * @param	pAutoPlay	si un état de bouton est un conteneur, on lance la lecture récursive de son contenu (true) ; si on ne veut pas de ce comportement par défaut, mettre false
		 */
		public function MyButton( pContainer : DisplayObjectContainer, pAutoPlay : Boolean = true) {
			var lChild	: DisplayObject;
			
			container		= pContainer;
			autoPlay		= pAutoPlay;
			
			lChild	= container.getChildByName( NAME_HIT);
			if ( lChild != null) {
				//container.swapChildrenAt( container.getChildIndex( lChild), container.numChildren - 1);
				
				//lChild.alpha	= 0;
				hitZone			= lChild;
				
				container.mouseEnabled = false;
			}else hitZone = container;
			
			hitZone.addEventListener( MouseEvent.MOUSE_OVER, onOver);
			hitZone.addEventListener( MouseEvent.MOUSE_DOWN, onDown);
			hitZone.addEventListener( MouseEvent.MOUSE_UP, onUp);
			hitZone.addEventListener( MouseEvent.CLICK, onClicked);
			hitZone.addEventListener( MouseEvent.MOUSE_OUT, onOut);
			
			stateUp			= initSymbolState( NAME_UP);
			stateOver		= initSymbolState( NAME_OVER);
			stateDown		= initSymbolState( NAME_DOWN);
			stateSelect		= initSymbolState( NAME_SELECT);
			stateSelectDown	= initSymbolState( NAME_SELECT_DOWN);
			stateSelectOver	= initSymbolState( NAME_SELECT_OVER);
			
			if ( stateOver != null && MobileDeviceMgr.getInstance().isMobile()) stateOver.visible = false;
			if ( stateSelectOver != null && MobileDeviceMgr.getInstance().isMobile()) stateSelectOver.visible = false;
			
			if( stateSelect != null) MySystem.stage.addEventListener( MouseEvent.MOUSE_UP, onStageUnselect);
			
			if ( hitZone is Sprite) Sprite( hitZone).buttonMode = true;
			
			if ( stateUp != null) enableState( stateUp);
			
			switchEnable( true);
		}
		
		/**
		 * on active / désactive le bouton
		 * @param	pIsEnable	true pour activer, false pour désactiver
		 */
		public function switchEnable( pIsEnable : Boolean) : void {
			if ( hitZone is Sprite) ( hitZone as Sprite).mouseEnabled = pIsEnable;
			else MySystem.traceDebug( "WARNING : MyButton::switchEnable : zone de hit non réactive à la souris");
		}
		
		/**
		 * on vérifie si le bouton est actif ou pas
		 * @return	true si bouton actif, false sinon
		 */
		public function isEnable() : Boolean {
			if ( hitZone is Sprite) return ( hitZone as Sprite).mouseEnabled;
			else return false;
		}
		
		/**
		 * on récupère l'objet graphique de l'état en cours
		 * @return	graphisme de l'état en cours
		 */
		public function getCurState() : DisplayObject { return curState; }
		
		/**
		 * on accède au contenu du conteneur de bouton
		 * @param	pName	nom d'état de contenu à récupérer
		 */
		public function getChildByName( pName : String) : DisplayObject { return container.getChildByName( pName); }
		
		/**
		 * on vérifie si le bouton est à l'état "select" depuis le précédent état (permet d'être sûr que si on demande depuis un event de souris, pour éviter de détecter l'état "select" alors qu'on est juste en transition)
		 * @return	true si "select" depuis le dernier état
		 */
		public function isSelectState() : Boolean { return isSelect() && prevState != null && ( prevState == stateSelect || prevState == stateSelectDown || prevState == stateSelectOver);}
		
		/**
		 * on déselectionne le bouton en le refaisant passer au state "up" par défaut
		 */
		public function unselect() : void { if ( stateUp != null) enableState( stateUp); }
		
		/**
		 * on force la sélection du bouton, on suppose que le bouton possède l'état "select"
		 */
		public function select() : void { if ( stateSelect != null) enableState( stateSelect); }
		
		/**
		 * on récupère le clip utilisé pour la zone de hit du bouton
		 * @return	clip de zone de hit de bouton
		 */
		public function getHitZone() : DisplayObject { return hitZone;}
		
		/**
		 * wrapping de EventDispatcher::addEventListener ; on forward l'appel à l'EventDispatcher de ce bouton
		 * @see	EventDispatcher::addEventListener
		 */
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void { hitZone.addEventListener(type, listener, useCapture, priority, useWeakReference);}
		
		/**
		 * wrapping de EventDispatcher::removeEventListener ; on forward l'appel à l'EventDispatcher de ce bouton
		 * @see	EventDispatcher::removeEventListener
		 */
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void { hitZone.removeEventListener(type, listener, useCapture);}
		
		/**
		 * destruction : on rétablit le conteneur comme à l'origine, et on libère la mémoire
		 */
		public function destroy() : void {
			var lChild	: DisplayObject;
			
			restaureSymbolInitialState( NAME_UP);
			restaureSymbolInitialState( NAME_OVER);
			restaureSymbolInitialState( NAME_DOWN);
			restaureSymbolInitialState( NAME_SELECT);
			restaureSymbolInitialState( NAME_SELECT_DOWN);
			restaureSymbolInitialState( NAME_SELECT_OVER);
			
			freeAsset( stateUp);
			freeAsset( stateOver);
			freeAsset( stateDown);
			freeAsset( stateSelect);
			freeAsset( stateSelectDown);
			freeAsset( stateSelectOver);
			
			//if ( hitZone != container) hitZone.alpha = 1;
			
			hitZone.removeEventListener( MouseEvent.MOUSE_OVER, onOver);
			hitZone.removeEventListener( MouseEvent.MOUSE_DOWN, onDown);
			hitZone.removeEventListener( MouseEvent.MOUSE_UP, onUp);
			hitZone.removeEventListener( MouseEvent.CLICK, onClicked);
			hitZone.removeEventListener( MouseEvent.MOUSE_OUT, onOut);
			
			if( stateSelect != null) MySystem.stage.removeEventListener( MouseEvent.CLICK, onStageUnselect);
			
			if ( hitZone is Sprite) Sprite( hitZone).buttonMode = false;
			
			switchEnable( true);
			
			container.mouseEnabled = true;
			
			stateUp			= null;
			stateOver		= null;
			stateDown		= null;
			stateSelect		= null;
			stateSelectDown	= null;
			stateSelectOver	= null;
			hitZone			= null;
			
			curState		= null;
			prevState		= null;
			
			container		= null;
		}
		
		/**
		 * on initialise un état de bouton
		 * @param	pName	nom de symbole d'état dans le conteneur de bouton
		 * @return	réf sur l'objet graphique d'état de bouton, ou null si aucun trouvé
		 */
		protected function initSymbolState( pName : String) : DisplayObject {
			var lIsLocalHit		: Boolean			= ( hitZone != container);
			var lChild			: DisplayObject;
			var lAsset			: DisplayObject;
			var lClassName		: String;
			
			lChild	= container.getChildByName( pName);
			
			if( lChild != null){
				lChild.visible	= false;
				lClassName		= getQualifiedClassName( lChild);
				
				if ( autoPlay && lChild is MovieClip) UtilsMovieClip.recursiveGotoAndStop( MovieClip( lChild), 1);
				
				if ( AssetsMgr.getInstance().getAssetDescById( lClassName) != null) {
					lAsset			= container.addChildAt( AssetsMgr.getInstance().getAssetInstance( lClassName), lChild.parent.getChildIndex( lChild));
					lAsset.visible	= false;
					lAsset.x		= lChild.x;
					lAsset.y		= lChild.y;
					
					if ( lIsLocalHit) {
						Sprite( lAsset).mouseChildren = false;
						Sprite( lAsset).mouseEnabled = false;
					}
					
					return lAsset;
				}else {
					if ( lIsLocalHit && ( lChild is Sprite)) {
						Sprite( lChild).mouseChildren = false;
						Sprite( lChild).mouseEnabled = false;
					}
					
					return lChild;
				}
			}else return null;
		}
		
		/**
		 * on restaure l'état initial des symboles d'états du conteneur de bouton
		 * @param	pName	nom de symbole d'état à restituer comme à l'initial
		 */
		protected function restaureSymbolInitialState( pName : String) : void {
			var lChild	: DisplayObject;
			
			lChild	= container.getChildByName( pName);
			if ( lChild != null) {
				lChild.visible	= true;
				
				if ( autoPlay && lChild is MovieClip) UtilsMovieClip.recursiveGotoAndStop( MovieClip( lChild), 1);
			}
		}
		
		/**
		 * on libère la mémoire d'un asset d'état
		 * @param	pState	réf sur l'asset d'état posé dans le conteneur, null si aucun
		 */
		protected function freeAsset( pState : DisplayObject) : void {
			if ( pState != null) {
				if ( pState is Sprite) {
					Sprite( pState).mouseChildren = true;
					Sprite( pState).mouseEnabled = true;
				}
				
				if( pState is AssetInstance) {
					UtilsMovieClip.free( pState);
					pState.visible = true;
					AssetInstance( pState).free();
				}
			}
		}
		
		/**
		 * on active un état
		 * @param	instance graphique de l'état à prendre ; doit être défini
		 */
		protected function enableState( pState : DisplayObject) : void {
			prevState = curState;
			
			if( pState != curState){
				if ( curState != null && pState != curState) {
					curState.visible	= false;
					
					if ( autoPlay && curState is DisplayObjectContainer) UtilsMovieClip.recursiveGotoAndStop( DisplayObjectContainer( curState), 1);
				}
				
				curState			= pState;
				curState.visible	= true;
				
				if ( autoPlay && curState is DisplayObjectContainer) UtilsMovieClip.recursivePlay( DisplayObjectContainer( curState));
			}
		}
		
		/**
		 * on vérifie si on est à l'état "select" ou l'un de ses sous-états ("selectOver" ou "selectDown") ; ne teste que le en cours ponctuel
		 * @return	true si à l'état "select", false sinon
		 */
		protected function isSelect() : Boolean { return curState != null && ( curState == stateSelect || curState == stateSelectDown || curState == stateSelectOver);}
		
		/**
		 * on capture l'event de click sur stage
		 * @param	pE	event de souris sur stage
		 */
		protected function onStageUnselect( pE : MouseEvent) : void {
			if ( isSelectState() && ( ! hitZone.hitTestPoint( MySystem.stage.mouseX, MySystem.stage.mouseY, true)) && isEnable()) unselect();
		}
		
		/**
		 * on capture l'event "over" de la zone de hit
		 * @param	pE	event de souris
		 */
		protected function onOver( pE : MouseEvent) : void {
			if ( isSelect()) {
				if ( stateSelectOver != null && ! MobileDeviceMgr.getInstance().isMobile()) enableState( stateSelectOver);
				else enableState( stateSelect);
			}else{
				if ( stateOver != null && ! MobileDeviceMgr.getInstance().isMobile()) enableState( stateOver);
				else if( stateUp != null) enableState( stateUp);
			}
		}
		
		/**
		 * on capture l'event de "click" de la zone de hit
		 * @param	pE	event de souris
		 */
		protected function onClicked( pE : MouseEvent) : void {
			if ( ! isSelect() && stateSelect != null) enableState( stateSelect);
		}
		
		/**
		 * on capture l'event "up" de la zone de hit
		 * @param	pE	event de souris
		 */
		protected function onUp( pE : MouseEvent) : void {
			if ( isSelect()) {
				if ( stateSelectOver != null && ! MobileDeviceMgr.getInstance().isMobile()) enableState( stateSelectOver);
				else enableState( stateSelect);
			}else {
				if ( stateSelectOver != null && ! MobileDeviceMgr.getInstance().isMobile()) enableState( stateSelectOver);
				else if ( stateSelect != null) return;// enableState( stateSelect);
				else if ( stateOver != null && ! MobileDeviceMgr.getInstance().isMobile()) enableState( stateOver);
				else if( stateUp != null) enableState( stateUp);
			}
		}
		
		/**
		 * on capture l'event "down" de la zone de hit
		 * @param	pE	event de souris
		 */
		protected function onDown( pE : MouseEvent) : void {
			if ( isSelect()) {
				if ( stateSelectDown) enableState( stateSelectDown);
				else enableState( stateSelect);
			}else{
				if ( stateDown != null) enableState( stateDown);
				else if( stateUp != null) enableState( stateUp);
			}
		}
		
		/**
		 * on capture l'event "out" de la zone de hit
		 * @param	pE	event de souris
		 */
		protected function onOut( pE : MouseEvent) : void {
			if ( isSelect()) enableState( stateSelect);
			else if( stateUp != null) enableState( stateUp);
		}
	}
}