package net.cyclo.display {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * manage depths of a DisplayObjectContainer content ; enables on the fly relative depth assigning (as2 way)
	 * @author	nico
	 */
	public class DepthMgr {
		/** zone where to manage depths */
		private var zone		: DisplayObjectContainer;
		/** table of displayed items sorted by depth ; at each cell, we have a struct { mc: <ref on the displayed object>, depth: <hint depth value : Number>} */
		private var items		: Array;
		
		/**
		 * constructor
		 * @param	pZone	zone where to manage depths
		 */
		public function DepthMgr( pZone : DisplayObjectContainer) {
			zone		= pZone;
			items		= new Array();
		}
		
		/**
		 * set a relative depth for an item
		 * @param	pItem	an item of the managed zone to set at a relative depth (is already added to the zone)
		 * @param	pDepth	depth hint comparative value
		 */
		public function setDepth( pItem : DisplayObject, pDepth : Number) : void {
			var lBeg	: int	= 0;
			var lEnd	: int	= items.length;
			var lMid	: int	= Math.floor( ( lBeg + lEnd) / 2);
			
			while( lBeg < lEnd){
				if( pDepth > items[ lMid].depth){
					lBeg = lMid + 1;
				}else if( pDepth < items[ lMid].depth){
					lEnd = lMid;
				}else break;
				
				lMid = Math.floor( ( lBeg + lEnd) / 2);
			}
			
			items.splice( lMid, 0, { mc: pItem, depth: pDepth});
			
			if( items.length == lMid + 1) zone.setChildIndex( pItem, zone.numChildren - 1);
			else zone.setChildIndex( pItem, zone.getChildIndex( items[ lMid + 1].mc));
		}
		
		/**
		 * update the depth of an already registered item
		 * @param	pItem	the displayed item which depth should be updated
		 * @param	pDeth	its new depth hint comparative value
		 */
		public function updateDepth( pItem : DisplayObject, pDepth : Number) : void {
			freeDepth( pItem);
			zone.setChildIndex( pItem, zone.numChildren - 1);
			setDepth( pItem, pDepth);
		}
		
		/**
		 * free depth of the specified item managed in the zone
		 * @param	pItem	item which registered depth is to be freed ; after being freed, we should remove that item ; you should use "updateDepth" to just update its depth or it will crash the depth engine !
		 */
		public function freeDepth( pItem : DisplayObject) : void {
			var lBeg	: int	= 0;
			var lEnd	: int	= items.length;
			var lMid	: int	= Math.floor( ( lBeg + lEnd) / 2);
			var lDepth	: int	= zone.getChildIndex( pItem);
			
			while( lBeg < lEnd){
				if( lDepth > zone.getChildIndex( items[ lMid].mc)){
					lBeg = lMid + 1;
				}else if( lDepth < zone.getChildIndex( items[ lMid].mc)){
					lEnd = lMid;
				}else break;
				
				lMid = Math.floor( ( lBeg + lEnd) / 2);
			}
			
			items.splice( lMid, 1);
		}
		
		/**
		 * string representation of the content managed by this depth manager ; debug purpose
		 * @return	string representation for debug purpose
		 */
		public function toString() : String {
			var lRes	: String = "DepthMgr::toString\n";
			var lI		: int;
			
			lRes += "items:" + items.length + "\n";
			for( lI = 0 ; lI < items.length ; lI++){
				lRes += lI + ":hint=" + items[ lI].depth + ":depth=" + zone.getChildIndex( items[ lI].mc) + ":mc=" + items[ lI].mc.name + "\n";
			}
			lRes += "end items\n";
			
			lRes += "zone:" + zone.numChildren + ":" + zone + "\n";
			for( lI = 0 ; lI < zone.numChildren ; lI++){
				lRes += lI + ":" + ":mc=" + zone.getChildAt( lI).name + "\n";
			}
			lRes += "end zone";
			
			return lRes;
		}
	}
}