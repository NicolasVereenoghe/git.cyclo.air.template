package net.cyclo.paddle {
	import flash.display.Stage;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	
	/// manage a paddle with several "fire mode"
	/**
	 * @author	nico
	 */
	public class MyPaddle extends EventDispatcher {
		/// down mode class
		public const MODE_DOWN			: Class		= ModeDown;
		/// up mode class
		public const MODE_UP			: Class		= ModeUp;
		/// autofire down mode class ; must specify first delay time and the delay time for the next events in ms
		public const MODE_DOWN_AUTO		: Class		= ModeDownAuto;
		/// first time down mode class
		public const MODE_DOWN_FIRST	: Class		= ModeDownFirst;
		
		/// stage where we bind listener
		private var kStage				: Stage;
		/// paddle's action ; hash tab indexed by action names ; the value of a cell is an object { k, a} with "k" its KAction, and "a" a hash tab of antagonist actions
		private var actions				: Object;
		/// list of the last active actions name
		private var _actives			: Object;
		
		/// constructor
		/**
		 * @param	pStage	stage where we bind listener to listen to keys events
		 */
		public function MyPaddle( pStage : Stage) {
			super();
			
			kStage	= pStage;
			actions	= new Object();
			
			if( kStage){
				kStage.addEventListener( KeyboardEvent.KEY_DOWN, onKeyDown);
				kStage.addEventListener( KeyboardEvent.KEY_UP, onKeyUp);
			}
		}
		
		/// desctructor
		public function destroy() : void {
			var lI	: String;
			
			if( kStage){
				kStage.removeEventListener( KeyboardEvent.KEY_DOWN, onKeyDown);
				kStage.removeEventListener( KeyboardEvent.KEY_UP, onKeyUp);
			}
			
			for( lI in actions) KAction( actions[ lI].k).destroy( this);
		}
		
		/// add an action to the paddle
		/**
		 * @param	pAction	name of the action ; unique id
		 * @param	pKeys	array of keys binded to the action
		 * @param	pMode	mode of the action
		 * @param	pAntas	array of antagonist actions
		 */
		public function addAction( pAction : String, pKeys : Array, pMode : Object, pAntas : Array = null) : void {
			actions[ pAction] = {
				k: new KAction( this, array2Hash( pKeys, {}), ModeKey( pMode)),
				a: pAntas != null ? array2Hash( pAntas, {}) : null
			};
		}
		
		/// gets a list of active actions name
		/**
		 * @return	hash tab of active actions name (marked as "true")
		 */
		public function get actives() : Object { return _actives;}
		
		/// test all actions and dispatch the result to listener call back method
		public function testActions() : void {
			var lRes	: Object = new Object();
			var lA		: String;
			var lR		: String;
			
			for( lA in actions){
				if( KAction( actions[ lA].k).isActive){
					lRes[ lA] = true;
					
					for( lR in actions[ lA].a){
						if( lRes[ lR]){
							if( KAction( actions[ lA].k).lastA >= KAction( actions[ lR].k).lastA) delete lRes[ lR];
							else delete lRes[ lA];
						}
					}
				}
			}
			
			_actives = lRes;
			
			refresh();
		}
		
		/// flush actions state
		public function flush() : void { dispatchEvent( new PaddleEvent( PaddleEvent.FLUSH)); }
		
		/// lock an action while it is being held
		/**
		 * @param	pAction	name of the action to lock ; null to lock all the actions
		 */
		public function lock( pAction : String = null) : void {
			if( pAction) KAction( actions[ pAction].k).lock();
			else dispatchEvent( new PaddleEvent( PaddleEvent.LOCK));
		}
		
		/// refresh actions state
		private function refresh() : void { dispatchEvent( new PaddleEvent( PaddleEvent.REFRESH));}
		
		/// called when a key is down
		/**
		 * @param	pEvt	keyboard event
		 */
		private function onKeyDown( pEvt : KeyboardEvent) : void { dispatchEvent( new PaddleEvent( PaddleEvent.K_DOWN, pEvt.keyCode));}
		
		/// called when a key is up
		/**
		 * @param	pEvt	keyboard event
		 */
		private function onKeyUp( pEvt : KeyboardEvent) : void { dispatchEvent( new PaddleEvent( PaddleEvent.K_UP, pEvt.keyCode));}
		
		/// convert an array of key entries into a hash tab
		/**
		 * @param	pArray	the array of key entries to convert
		 * @param	pHash	the hash tab to write to ; each key entry has a "true" value
		 * @return	hash tab
		 */
		private function array2Hash( pArray : Array, pHash : Object) : Object {
			for( var lI : int = 0 ; lI < pArray.length ; lI++) pHash[ pArray[ lI]] = true;
			
			return pHash;
		}
	}
}

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.utils.getTimer;

/// paddle event
internal class PaddleEvent extends Event {
	/// key up event
	public static const K_UP	: String	= "kUp";
	/// key down event
	public static const K_DOWN	: String	= "kDown";
	/// key refresh event
	public static const REFRESH	: String	= "refresh";
	/// key flush event
	public static const FLUSH	: String	= "flush";
	/// lock key event
	public static const LOCK	: String	= "lock";
	
	/// key code
	public var code				: int;
	
	/// constructor
	/**
	 * @param		pType	event type
	 * @param		pCode	key code
	 */
	public function PaddleEvent( pType : String, pCode : int = 0) {
		super( pType);
		
		code	= pCode;
	}
}

/// a keys action
internal class KAction {
	/// flag that tells if the action is active
	public var isActive	: Boolean;
	/// time of the last activity ; -1 if no activity
	public var lastA	: int;
	
	/// hash tab of keys binded to the action
	private var keys	: Object;
	/// mode of the action
	private var mode	: ModeKey;
	/// tells if we already received a key down event
	private var wasKD	: Boolean;
	/// tells if there is a lock on the current held action
	private var isLock	: Boolean;
	
	/// constructor
	/**
	 * @param	pPad	paddle
	 * @param	pKeys	hash tab of keys binded to the action
	 * @param	pMode	mode of the action
	 */
	public function KAction( pPad : EventDispatcher, pKeys : Object, pMode : ModeKey) {
		keys		= pKeys;
		mode		= pMode;
		isActive	= false;
		lastA		= -1;
		wasKD		= false;
		isLock		= false;
		
		pPad.addEventListener( PaddleEvent.K_DOWN, onKDown);
		pPad.addEventListener( PaddleEvent.K_UP, onKUp);
		pPad.addEventListener( PaddleEvent.REFRESH, refresh);
		pPad.addEventListener( PaddleEvent.FLUSH, flush);
		pPad.addEventListener( PaddleEvent.LOCK, lock);
	}
	
	/// destructor
	/**
	 * @param	pPad	paddle managing this keys action
	 */
	public function destroy( pPad : EventDispatcher) : void {
		pPad.removeEventListener( PaddleEvent.K_DOWN, onKDown);
		pPad.removeEventListener( PaddleEvent.K_UP, onKUp);
		pPad.removeEventListener( PaddleEvent.REFRESH, refresh);
		pPad.removeEventListener( PaddleEvent.FLUSH, flush);
		pPad.removeEventListener( PaddleEvent.LOCK, lock);
	}
	
	/// notify a lock key event
	/**
	 * @param	pEvt	paddle event
	 */
	public function lock( pEvt : PaddleEvent = null) : void {
		if( isActive){
			isLock		= true;
			isActive	= false;
			lastA		= -1;
		}
	}
	
	/// tries to set the activity
	/**
	 * @param	pIsActive	true to activate, else false
	 */
	private function setActivity( pIsActive : Boolean) : void {
		if( isLock){
			if( ! pIsActive) isLock = false;
		}else if( pIsActive != isActive){
			isActive = pIsActive;
			
			if( pIsActive){
				lastA		= getTimer();
				isActive	= true;
			}else{
				lastA		= -1;
				isActive	= false;
			}
		}
	}
	
	/// notify a key down
	/**
	 * @param	pEvt	paddle event
	 */
	private function onKDown( pEvt : PaddleEvent) : void {
		if( keys[ pEvt.code] && ! wasKD){
			setActivity( mode.testDown());
			
			wasKD = true;
		}
	}
	
	/// notify a key up
	/**
	 * @param	pEvt	paddle event
	 */
	private function onKUp( pEvt : PaddleEvent) : void {
		if( keys[ pEvt.code]){
			setActivity( mode.testUp());
			wasKD		= false;
		}
	}
	
	/// refresh action state
	/**
	 * @param	pEvt	paddle event
	 */
	private function refresh( pEvt : PaddleEvent) : void { setActivity( mode.testVoid());}
	
	/// flush action state
	/**
	 * @param	pEvt	paddle event
	 */
	private function flush( pEvt : PaddleEvent) : void {
		mode.flush();
		isActive	= false;
		lastA		= -1;
		wasKD		= false;
		isLock		= false;
	}
}

/// abstract class for keys modes
internal class ModeKey {
	/// test the activity on down event
	/**
	 * @return	true if ative, else false
	 */
	public function testDown() : Boolean { return false;}
	
	/// test the activity on up event
	/**
	 * @return	true if ative, else false
	 */
	public function testUp() : Boolean { return false;}
	
	/// test the activity on void event
	/**
	 * @return	true if ative, else false
	 */
	public function testVoid() : Boolean { return false; }
	
	/// flush mode
	public function flush() : void {}
}

/// mode action while key is down
internal class ModeDown extends ModeKey {
	/// flag for the down state
	private var isDown		: Boolean	= false;
	
	public override function testDown() : Boolean {
		isDown = true;
		return true;
	}
	
	public override function testUp() : Boolean {
		isDown = false;
		return false;
	}
	
	public override function testVoid() : Boolean { return isDown; }
	
	public override function flush() : void { isDown = false;}
}

/// mode action on key up
internal class ModeUp extends ModeKey {
	public override function testUp() : Boolean { return true;}
}

/// mode action triggered at regular interval while key is down
internal class ModeDownAuto extends ModeKey {
	/// first delay in ms
	private var dFirst		: int;
	/// next delay in ms
	private var dNext		: int;
	
	/// flag for the down state
	private var isDown		: Boolean	= false;
	/// flag for the first step
	private var isFirst		: Boolean;
	/// timer from the last step
	private var last		: int;
	
	/// constructor
	/**
	 * @param	pDFirst	first delay in ms to trigger the action
	 * @param	pDNext	next delay in ms to trigger all the other actions
	 */
	public function ModeDownAuto( pDFirst : int, pDNext : int) {
		dFirst	= pDFirst;
		dNext	= pDNext;
	}
	
	public override function testDown() : Boolean {
		isDown	= true;
		isFirst	= true;
		last	= getTimer();
		
		return true;
	}
	
	public override function testUp() : Boolean {
		isDown = false;
		
		return false;
	}
	
	public override function testVoid() : Boolean {
		if( isDown){
			if( isFirst){
				if( getTimer() - last >= dFirst){
					isFirst = false;
					last	= getTimer();
					
					return true;
				}
			}else{
				if( getTimer() - last >= dNext){
					last	= getTimer();
					
					return true;
				}
			}
		}
		
		return false;
	}
	
	public override function flush() : void {
		isDown = false;
	}
}

/// mode action triggered once when key is down
internal class ModeDownFirst extends ModeKey {
	public override function testDown() : Boolean { return true;}
}