package net.cyclo.ui {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import net.cyclo.shell.device.MobileDeviceMgr;
	import net.cyclo.shell.MySystem;
	
	/**
	 * ascenseur de rubriques, ergo mobile
	 * contient un mcContent que l'on va déplacer en y pour faire le scroll ; y initial pris en compte
	 * le contenu est une liste de rubriques mcItem<i> (0 .. n-1)
	 * chaque mcItem<i> est formaté pour être wrappé par un MyButton
	 * l'itération est prévue à la frame mais doit être contrôlée de l'extérieur par l'appel de ::doFrame
	 * 
	 * @author nico
	 */
	public class VScroll {
		/** racine de nom de scène des éléments du scroll */
		protected var ITEM_RADIX						: String									= "mcItem";
		
		/** écart d'ordonnées à partir duquel on passe en mode scrolling */
		protected var DELT_Y_TRIGGER_SCROLL				: Number									= 5;
		/** friction du scroll lors de la finalisation */
		protected var SCROLL_FROT						: Number									= .02;
		/** friction du scroll hors limites lors de la finalisation  */
		protected var SCROLL_FROT_OUT					: Number									= .3;
		/** vitesse minimale du scroll lors de la finalisation */
		protected var SCROLL_MIN_SPEED					: Number									= 1;
		/** coef d'inertie pour rattraper les limites */
		protected var SCROLL_OUT_INERTIA				: Number									= .13;
		/** distance de rattrapage de limite à partir de laquelle on se positionne sur la limite */
		protected var SCROLL_OUT_MIN_DIST				: Number									= 2;
		
		/** conteneur du scroll */
		protected var container							: DisplayObjectContainer					= null;
		
		/** dictionnaire de boutons d'items indexés par réf d'items */
		protected var itemsButton						: Dictionary								= null;
		
		/** ordonnée maximale du contenu du scroll dans le repère du conteneur ; y initial du mcContent restituée à la destruction*/
		protected var scrollMaxY						: Number									= 0;
		/** ordonnée minimale du contenu du scroll dans le repère du conteneur */
		protected var scrollMinY						: Number									= 0;
		
		/** nombre total d'élément dans le contenu de scroll */
		protected var totalItem							: int										= 0;
		
		/** flag indiquant si le click sur rubrique est dispo (true) ou pas (false) car en train de faire du "drag / scroll" */
		protected var isItemClickFree					: Boolean									= true;
		
		/** l'indice de jeu qui a été sélectionné pour jouer par l'utilisateur : 0 .. n-1 ; -1 si aucun */
		protected var _selectedGameIndex				: int										= -1;
		
		/** mode d'itération de l'ascenseur */
		protected var doMode							: Function									= null;
		
		/** flag indiquant si on est en pause (true) ou pas (false) */
		protected var isPause							: Boolean									= false;
		
		/** ordonnée où on a détecté un premier touché d'écran avant de passer en mode scrolling */
		protected var scrollFromY						: Number									= 0;
		/** ordonnée de dernière position de touché d'écran */
		protected var scrollLastY						: Number									= 0;
		/** vitesse de scroll lors de la finalisation */
		protected var scrollSpeed						: Number									= 0;
		
		/**
		 * construction
		 */
		public function VScroll() { }
		
		/**
		 * getter sur l'index de rubrique qui a été clickée
		 * @return	index de rubrique clickée ( 0 .. n-1), -1 si rien de clické
		 */
		public function get selectedGameIndex() : int { return _selectedGameIndex; }
		
		/**
		 * initialisation
		 * @param	pScrollContainer	conteneur du scroll
		 * @param	pDScrollY			depuis l'origine du conteneur du scroll, distance scrollable en hauteur - /!\ on y enlève la hauteur initiale du contenu du scroll
		 */
		public function init( pScrollContainer : DisplayObjectContainer, pDScrollY : Number) : void {
			var lI		: int						= 0;
			var lChild	: DisplayObject;
			var lCont	: DisplayObjectContainer;
			
			container	= pScrollContainer;
			itemsButton	= new Dictionary();
			
			MySystem.stage.addEventListener( MouseEvent.MOUSE_DOWN, onScrollDown);
			MySystem.stage.addEventListener( MouseEvent.MOUSE_UP, onScrollUp);
			
			lCont		= getContent();
			scrollMaxY	= lCont.y;
			
			lChild = lCont.getChildByName( ITEM_RADIX + 0);
			while ( lChild != null) {
				totalItem++;
				
				initItem( DisplayObjectContainer( lChild), lI);
				
				lChild = lCont.getChildByName( ITEM_RADIX + ++lI);
			}
			
			updateDScrollY( pDScrollY);
			
			setModeWait();
		}
		
		/**
		 * destruction
		 */
		public function destroy() : void {
			var lItem	: Object;
			
			for ( lItem in itemsButton) clearItem( lItem as DisplayObjectContainer);
			itemsButton = null;
			
			getContent().y	= scrollMaxY;
			
			container		= null;
			
			MySystem.stage.removeEventListener( MouseEvent.MOUSE_DOWN, onScrollDown);
			MySystem.stage.removeEventListener( MouseEvent.MOUSE_UP, onScrollUp);
		}
		
		/**
		 * on pause l'ascenseur : empèche le traitement de click
		 * @param	pIsPause	true pour mettre en pause, false sinon
		 */
		public function switchPause( pIsPause : Boolean) : void {
			if ( isPause && ! pIsPause) setModeScrollToLimit();
			
			isPause = pIsPause;
		}
		
		/**
		 * on effectue une itération de l'ascenseur
		 */
		public function doFrame() : void { doMode(); }
		
		/**
		 * on met à jour la distance de scroll en hauteur depuis l'origine du conteneur du scroll
		 * @param	pDScrollY	nouvelle distance de scroll
		 */
		public function updateDScrollY( pDScrollY : Number) : void {
			var lCont	: DisplayObjectContainer	= getContent();
			
			/* 2 * scrollMaxY - pDScrollY + totalItem * ( lCont.getChildByName( ITEM_RADIX + 1).y - lCont.getChildByName( ITEM_RADIX + 0).y) */
			/* scrollMaxY - ( totalItem * ( lCont.getChildByName( ITEM_RADIX + 1).y - lCont.getChildByName( ITEM_RADIX + 0).y) - ( pDScrollY - scrollMaxY)) */
			
			if ( totalItem > 1) scrollMinY	= Math.min( scrollMaxY, scrollMaxY - ( totalItem * ( lCont.getChildByName( ITEM_RADIX + 1).y - lCont.getChildByName( ITEM_RADIX + 0).y) - ( pDScrollY - scrollMaxY)));
			else scrollMinY	= scrollMaxY;
			
			setModeScrollToLimit();
		}
		
		/**
		 * on libère la mémorie d'un élément du contenu de scroll
		 * @param	pItem	symbole d'élément de scroll posé dans le contenu
		 */
		protected function clearItem( pItem : DisplayObjectContainer) : void {
			var lBt	: MyButton = itemsButton[ pItem];
			
			lBt.removeEventListener( MouseEvent.CLICK, onItemClicked);
			lBt.destroy();
		}
		
		/**
		 * on initialise un élément du contenu de scroll
		 * @param	pItem	symbole d'élément de scroll posé dans le contenu
		 * @param	pI		index d'item (0 .. n-1)
		 */
		protected function initItem( pItem : DisplayObjectContainer, pI : int) : void {
			var lBt				: MyButton;
			
			lBt = new MyButton( pItem);
			lBt.addEventListener( MouseEvent.CLICK, onItemClicked);
			itemsButton[ pItem] = lBt;
		}
		
		/**
		 * on capture le click sur un item
		 * @param	pE	event de click sur item
		 */
		protected function onItemClicked( pE : MouseEvent) : void { if ( isItemClickFree) _selectedGameIndex = retrieveItemIndex( DisplayObject( pE.target)); }
		
		/**
		 * on capture le touché sur le scroll
		 * @param	pE	event de touché
		 */
		protected function onScrollDown( pE : MouseEvent) : void { if ( ! ( MobileDeviceMgr.getInstance().isLocked() || isPause)) setModeDetectScroll();}
		
		/**
		 * on capture le relâché du scroll
		 * @param	pE	event de relâché
		 */
		protected function onScrollUp( pE : MouseEvent) : void {
			if ( ! ( MobileDeviceMgr.getInstance().isLocked() || isPause)) {
				if ( doMode == doModeDragScroll) setModeFinalizeDragScroll();
				else if ( doMode == doModeDetectScroll) setModeWait();
			}
		}
		
		/**
		 * on récupère le contenu du scroll, l'instance qui est déaplacée
		 * @return	contenu du scroll
		 */
		protected function getContent() : DisplayObjectContainer { return container.getChildByName( "mcContent") as DisplayObjectContainer; }
		
		/**
		 * on retrouve l'index d'un item de scroll à partir d'un de ses enfants
		 * @param	pChild	enfant d'un item de scroll
		 * @return	index d'item de scroll : 0 .. n-1
		 */
		protected function retrieveItemIndex( pChild : DisplayObject) : int {
			if ( pChild.name.indexOf( ITEM_RADIX) == 0) return parseInt( pChild.name.substr( ITEM_RADIX.length));
			else return retrieveItemIndex( pChild.parent);
		}
		
		/**
		 * on effectue une itération de drag du contenu de scroll
		 */
		protected function doDragScroll() : void {
			var lCurY		: Number		= container.mouseY;
			var lDeltY		: Number		= lCurY - scrollLastY;
			var lContent	: DisplayObject	= getContent();
			
			if ( lContent.y > scrollMaxY || lContent.y < scrollMinY) lDeltY /= 2;
			
			lContent.y	+= lDeltY;
			scrollSpeed = lDeltY;
			scrollLastY	= lCurY;
		}
		
		/**
		 * on effectue une itération de la finalisation de drag de scroll avec inertie
		 */
		protected function doFinalizeDragScroll() : void {
			var lContent	: DisplayObject	= getContent();
			var lIsOut		: Boolean;
			
			lContent.y += scrollSpeed;
			
			lIsOut = ( lContent.y > scrollMaxY || lContent.y < scrollMinY);
			
			if ( lIsOut) scrollSpeed -= scrollSpeed * SCROLL_FROT_OUT;
			else scrollSpeed -= scrollSpeed * SCROLL_FROT;
			
			if ( Math.abs( scrollSpeed) < SCROLL_MIN_SPEED) {
				scrollSpeed = 0;
				
				if ( lIsOut) setModeScrollToLimit();
				else setModeWait();
			}
		}
		
		/**
		 * on effectue une itération de scroll pour se remettre en limites
		 */
		protected function doScrollToLimit() : void {
			var lContent	: DisplayObject	= getContent();
			
			if ( lContent.y > scrollMaxY) {
				lContent.y += ( scrollMaxY - lContent.y) * SCROLL_OUT_INERTIA;
				
				if ( lContent.y <= scrollMaxY + SCROLL_OUT_MIN_DIST) {
					lContent.y = scrollMaxY;
					
					setModeWait();
				}
			}else if ( lContent.y < scrollMinY) {
				lContent.y += ( scrollMinY - lContent.y) * SCROLL_OUT_INERTIA;
				
				if ( lContent.y >= scrollMinY - SCROLL_OUT_MIN_DIST) {
					lContent.y = scrollMinY;
					
					setModeWait();
				}
			}else setModeWait();
		}
		
		/**
		 * on passe en mode d'itération d'attente
		 */
		protected function setModeWait() : void { doMode = doModeWait; }
		
		/**
		 * on agit en mode d'attente
		 */
		protected function doModeWait() : void { isItemClickFree = true; }
		
		/**
		 * on passe en mode détection de drag de scroll (l'utilisateur vient de tapper l'écran)
		 */
		protected function setModeDetectScroll() : void {
			scrollFromY = scrollLastY = container.mouseY;
			
			doMode = doModeDetectScroll;
		}
		
		/**
		 * on agit en mode détection de drag de scroll
		 */
		protected function doModeDetectScroll() : void {
			if ( Math.abs( container.mouseY - scrollFromY) >= DELT_Y_TRIGGER_SCROLL) setModeDragScroll();
			else scrollLastY = container.mouseY;
		}
		
		/**
		 * on passe on mode drag du contenu de scroll
		 */
		protected function setModeDragScroll() : void {
			isItemClickFree = false;
			
			doMode = doModeDragScroll;
			
			doDragScroll();
		}
		
		/**
		 * on agit en mode drag du contenu de scroll
		 */
		protected function doModeDragScroll() : void { doDragScroll(); }
		
		/**
		 * on passe en mode finalisation du drag du scroll avec de l'inertie
		 */
		protected function setModeFinalizeDragScroll() : void {
			doMode = doModeFinalizeDragScroll;
			
			doFinalizeDragScroll();
		}
		
		/**
		 * on agit en mode finalisation du drag du scroll avec de l'inertie
		 */
		protected function doModeFinalizeDragScroll() : void { doFinalizeDragScroll(); }
		
		/**
		 * on passe en mode scroll pour replacer dans les limites
		 */
		protected function setModeScrollToLimit() : void {
			doMode = doModeScrollToLimit;
			
			doScrollToLimit();
		}
		
		/**
		 * on agit en mode scroll pour replacer dans les limites
		 */
		protected function doModeScrollToLimit() : void { doScrollToLimit(); }
	}
}