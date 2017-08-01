package net.cyclo.mysprite {
	
	public class MySpLimitLeft extends MySpDecor {
		override public function init( pMgr : MySpriteMgr, pDesc : MyCellDesc = null) : void {
			super.init( pMgr, pDesc);
			
			mgr.camera.setLimitLeft( x);
		}
		
		override public function destroy() : void {
			mgr.camera.freeLimitLeft();
			
			super.destroy();
		}
	}
}