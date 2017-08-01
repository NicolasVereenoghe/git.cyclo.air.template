package net.cyclo.mysprite {
	
	public class MySpLimitBot extends MySpDecor {
		override public function init( pMgr : MySpriteMgr, pDesc : MyCellDesc = null) : void {
			super.init( pMgr, pDesc);
			
			mgr.camera.setLimitBot( y);
		}
		
		override public function destroy() : void {
			mgr.camera.freeLimitBot();
			
			super.destroy();
		}
	}
}