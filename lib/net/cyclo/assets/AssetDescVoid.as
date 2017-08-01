package net.cyclo.assets {
	import flash.geom.Matrix;
	
	/**
	 * descripteur d'asset vide
	 * 
	 * @author	nico
	 */
	public class AssetDescVoid extends AssetDesc {
		public function AssetDescVoid( pConf : XML, pParent : AssetGroupDesc, pMgr : AssetsMgr) {
			super( null, null, pMgr);
			
			id					= AssetsMgr.VOID_ASSET;
			export				= "flash.display.MovieClip";
			exportTemplate		= null;
			sharedProperties	= new AssetsSharedProperties( null);
			groups				= new Object();
			
			sharedProperties.instanceCount	= 0;
			sharedProperties.lockInstance	= AssetsSharedProperties.LOCKER_LOCKED;
			sharedProperties.render			= new AssetRender( AssetRender.RENDER_VECTO);
		}
		
		public override function get trans() : Matrix { return null;}
	}
}