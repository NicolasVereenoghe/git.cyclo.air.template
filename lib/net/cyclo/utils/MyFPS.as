package net.cyclo.utils {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	/**
	 * une petite console de compteurs FPS et d'affichage de mémoire
	 * @author	nico
	 */
	public class MyFPS extends Sprite {
		/** période d'échantillonage ; on ne fait les calculs que toutes les n frames (optim d'affichage) */
		public static const PERIODE	: int				= 5;
		
		/** pile de compteur FPS (instances de MyCounter) */
		protected var counters		: Array;
		
		/** contenu de rendu du FPS */
		protected var content		: Sprite;
		
		/** zone intercative */
		protected var zone			: Sprite;
		
		/** champ texte d'affichage de mémoire */
		protected var txtMem		: TextField;
		
		/** champ texte d'affichage de mémoire critique */
		protected var txtCritMem	: TextField;
		
		/** temporisation de la dernière valeur critique de mémoire en Mo ; -1 si pas encore temporisé */
		protected var critMem		: Number;
		
		/** flag indiquant si on affiche / masque le fps sur rool over (true), ou si on ignore le roll over (false) */
		protected var rollEnabled	: Boolean;
		
		/** compteur d'itérations (pour étaloner la période) */
		protected var ctr			: int;
		
		/**
		 * construction
		 * @param	pRollEnabled	laisser true pour afficher / masquer le fps sur roll over de souris ; false pour ignorer le roll over
		 */
		public function MyFPS( pRollEnabled : Boolean = true) {
			var lMem	: Sprite;
			
			super();
			
			rollEnabled = pRollEnabled;
			
			critMem = -1;
			ctr = 0;
			
			content = new Sprite();
			addChild( content);
			
			content.graphics.beginFill( 0x0000FF, .35);
			content.graphics.drawRect( 0, 0, 220, 28);
			content.graphics.endFill();
			
			content.mouseChildren	= false;
			content.mouseEnabled	= false;
			
			zone = new Sprite();
			addChild( zone);
			
			zone.graphics.beginFill( 0, 0);
			zone.graphics.drawRect( 0, 0, 220, 28);
			zone.graphics.endFill();
			
			counters = new Array();
			
			addCounter( 10, 0);
			addCounter( 30, 60);
			addCounter( 150, 125);
			
			lMem	= new Sprite();
			lMem.x	= 190;
			content.addChild( lMem);
			
			txtMem	= new TextField();
			txtMem.defaultTextFormat =  new TextFormat( null, 12, 0xFFFFFF);
			txtMem.multiline = false;
			txtMem.autoSize = TextFieldAutoSize.LEFT;
			txtMem.selectable = false;
			txtMem.mouseEnabled = false;
			txtMem.text = "000.0";
			lMem.addChild( txtMem);
			
			txtCritMem	= new TextField();
			txtCritMem.defaultTextFormat = new TextFormat( null, 10, 0xFF0000);
			txtCritMem.multiline = false;
			txtCritMem.autoSize = TextFieldAutoSize.LEFT;
			txtCritMem.selectable = false;
			txtCritMem.mouseEnabled = false;
			txtCritMem.y = 15;
			txtCritMem.text = "000.0";
			lMem.addChild( txtCritMem);
			
			lMem.mouseEnabled	= false;
			lMem.mouseChildren	= false;
			
			addEventListener( Event.ENTER_FRAME, doFrame);
			
			if( rollEnabled) zone.addEventListener( MouseEvent.ROLL_OUT, onRoll);
			zone.addEventListener( MouseEvent.CLICK, onReset);
		}
		
		/**
		 * destructeur
		 */
		public function destroy() : void {
			removeEventListener( Event.ENTER_FRAME, doFrame);
			
			if( rollEnabled) zone.removeEventListener( MouseEvent.ROLL_OUT, onRoll);
			zone.removeEventListener( MouseEvent.CLICK, onReset);
			
			counters	= null;
		}
		
		/**
		 * on rend le contenu visible / invisible
		 * @param	pIsVisible	true pour rendre visible, false pour invisible
		 */
		public function switchVisible( pIsVisible : Boolean) : void {
			if ( ! pIsVisible) onReset( null);
			
			content.visible = pIsVisible;
		}
		
		/**
		 * on ajoute un compteur de FPS
		 * @param	pCycle	nombre de cycle à effectuer pour une moyenne de FPS
		 * @param	pX		position en x du compteur
		 */
		protected function addCounter( pCycle : int, pX : Number) : void {
			var lCtr	: MyCounter	= new MyCounter( pCycle, this);
			
			lCtr.x	= pX;
			content.addChild( lCtr);
			counters.push( lCtr);
		}
		
		/**
		 * on capture le click de souris pour faire un reset
		 * @param	pE	event de click
		 */
		protected function onReset( pE : MouseEvent) : void {
			var lI	: int;
			
			for( lI = 0 ; lI < counters.length ; lI++) MyCounter( counters[ lI]).reset();
			
			txtMem.text = "000.0";
			txtCritMem.text = "000.0";
			critMem = -1;
		}
		
		/**
		 * on capture le roll out sur le FPS pour passer visible / invisible
		 * @param	pE	event de roll out
		 */
		protected function onRoll( pE : MouseEvent) : void { switchVisible( ! content.visible);}
		
		/**
		 * méthode d'itération par frame
		 * @param	pE	event d'itératino de frame
		 */
		protected function doFrame( pE : Event) : void { if ( content.visible) doFrameFPS();}
		
		/**
		 * itération de frame avec mise à jour de fps
		 */
		protected function doFrameFPS() : void {
			var lI		: int;
			var lMem	: Number;
			
			if( ++ctr % PERIODE == 0){
				for( lI = 0 ; lI < counters.length ; lI++){
					if( ! MyCounter( counters[ lI]).doAction()) return;
				}
				
				lMem = Math.round( 10 * System.privateMemory / Math.pow( 2, 20)) / 10;
				
				txtMem.text = String( lMem);
				
				if( critMem < lMem){
					critMem = lMem;
					txtCritMem.text = String( lMem);
				}
			}
		}
	}
}

import flash.display.Sprite;
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.getTimer;

import net.cyclo.utils.MyFPS;

/**
 * un compteur FPS
 * author	nico
 */
internal class MyCounter extends Sprite {
	/** champ texte de compteur */
	protected var txtCtr		: TextField;
	
	/** champ texte pour afficher les FPS critiques */
	protected var txtCrit		: TextField;
	
	/** dernier FPS critique temporisé ; -1 si rien*/
	protected var crit			: Number;
	
	/** valeur de temporisation de frame pour effectuer la moyenne */
	protected var total			: int;
	
	/** pile de temporisation de temps moyens */
	protected var stack			: Array;
	
	/** dernier horloge prise depuis la dernière itération ; -1 <=> pas encore de mesure*/
	protected var lastT			: Number;
	
	/** somme des moyennes de FPS prises à chaque itération */
	protected var sum			: Number;
	
	/** composant MyFPS responsable de ce compteur */
	protected var myFPS			: MyFPS;
	
	/**
	 * construction
	 * @param	pTotal	nombre d'itérations tempérées pour effectuer une moyenne de FPS
	 * @param	pFPS	composant MyFPS responsable de ce compteur
	 */
	public function MyCounter( pTotal : int, pFPS : MyFPS) {
		var lTxt	: TextField;
		
		super();
		
		myFPS	= pFPS;
		total	= pTotal / MyFPS.PERIODE;
		stack	= new Array();
		sum		= 0;
		lastT	= -1;
		crit	= -1;
		
		txtCtr = new TextField();
		txtCtr.defaultTextFormat = new TextFormat( null, 12, 0xFFFFFF);
		txtCtr.multiline = false;
		txtCtr.autoSize = TextFieldAutoSize.LEFT;
		txtCtr.selectable = false;
		txtCtr.mouseEnabled = false;
		txtCtr.text = "00.0";
		addChild( txtCtr);
		
		txtCrit = new TextField();
		txtCrit.defaultTextFormat = new TextFormat( null, 10, 0xFF0000);
		txtCrit.multiline = false;
		txtCrit.autoSize = TextFieldAutoSize.LEFT;
		txtCrit.selectable = false;
		txtCrit.mouseEnabled = false;
		txtCrit.x = 25;
		txtCrit.text = "00.0";
		addChild( txtCrit);
		
		lTxt	= new TextField();
		lTxt.y	= 15;
		lTxt.defaultTextFormat = new TextFormat( null, 8, 0x000000);
		lTxt.multiline = false;
		lTxt.autoSize = TextFieldAutoSize.LEFT;
		lTxt.selectable = false;
		lTxt.mouseEnabled = false;
		lTxt.text = String( total * MyFPS.PERIODE);
		addChild( lTxt);
		
		mouseEnabled	= false;
		mouseChildren	= false;
	}
	
	/**
	 * on reset le calcul de FPS
	 */
	public function reset() : void {
		txtCtr.text		= "00.0";
		txtCrit.text	= "00.0";
		sum				= 0;
		lastT			= -1;
		crit			= -1;
		stack			= new Array();
	}
	
	/**
	 * itération de compteur FPS
	 * @return	true pour signaler un process normal, false pour interrompre car détection d'abscence de stage
	 */
	public function doAction() : Boolean {
		var lCurT	: Number	= getTimer();
		var lDt		: Number;
		
		if( ! stage){
			trace( "WARNING : MyFPS$MyCounter::doAction : stage null, destroy ...");
			
			myFPS.destroy();
			
			return false;
		}else{
			if( lastT > 0){
				lDt	= ( lCurT - lastT) / ( total * MyFPS.PERIODE);
				sum	+= lDt;
				
				if( stack.length == total){
					sum -= Number( stack.shift());
					
					txtCtr.text = String( Math.round( 10 / ( sum / 1000)) / 10);
					
					if( crit < sum){
						crit = sum;
						txtCrit.text = String( Math.round( 10 / ( crit / 1000)) / 10);
					}
				}
				
				stack.push( lDt);
			}
			
			lastT = lCurT;
			
			return true;
		}
	}
}