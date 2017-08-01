package net.cyclo.mysprite {
	
	public class MySpLimitTop extends MySpDecor {
		override public function init( pMgr : MySpriteMgr, pDesc : MyCellDesc = null) : void {
			super.init( pMgr, pDesc);
			
			mgr.camera.setLimitTop( y);
		}
		
		override public function destroy() : void {
			mgr.camera.freeLimitTop();
			
			super.destroy();
		}
	}
}