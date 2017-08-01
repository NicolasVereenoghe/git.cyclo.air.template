package net.cyclo.mysprite {
	
	public class MySpLimitRight extends MySpDecor {
		override public function init( pMgr : MySpriteMgr, pDesc : MyCellDesc = null) : void {
			super.init( pMgr, pDesc);
			
			mgr.camera.setLimitRight( x);
		}
		
		override public function destroy() : void {
			mgr.camera.freeLimitRight();
			
			super.destroy();
		}
	}
}