package net.cyclo.effect.grove {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.system.ApplicationDomain;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.effect.MyFractal2Mgr;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * on wrappe des fractales en spirales dans un fractal étoilé : un bosquet de fleurs
	 * 
	 * @author nico
	 */
	public class MyGroveMgr extends MyFractal2Mgr {
		/**
		 * construction
		 * @param	pFlowerId		identifiant d'asset de fleur
		 * @param	pStarMaxA		demi angle max autour de l'axe directeur de génération du fractal étoilé, en deg ; -1 pour valeur par défaut
		 */
		public function MyGroveMgr( pStarMaxA : Number = -1) {
			super();
			
			if( pStarMaxA >= 0) MAX_A_BRANCH = pStarMaxA;
		}
		
		/** @inheritDoc */
		override protected function instanciateBase( pRecurLvl : int) : DisplayObject {
			var lAsset	: AssetInstance	= AssetsMgr.getInstance().getAssetInstance( MOTIF_ASSET_RADIX);
			
			( lAsset.content as MovieClip).stop();
			
			return lAsset;
		}
		
		/** @inheritDoc */
		override protected function onBaseAtRate( pBaseCont : DisplayObjectContainer, pRecurLvl : int, pRate : Number) : void {
			var lFlower	: MovieClip	= ( pBaseCont.getChildAt( 0) as AssetInstance).content as MovieClip;
			var lRate	: Number;
			
			if ( pRecurLvl == 0) lRate = ( pRate >= NEXT_BRANCH_SCALE_LIMIT ? 1 : ( pRate - BASE0_SCALE_MIN) / ( NEXT_BRANCH_SCALE_LIMIT - BASE0_SCALE_MIN));
			else lRate = ( pRate <= NEXT_BRANCH_SCALE_LIMIT ? 0 : ( pRate - NEXT_BRANCH_SCALE_LIMIT) / ( 1 - NEXT_BRANCH_SCALE_LIMIT));
			
			lFlower.gotoAndStop( Math.round( ( lFlower.totalFrames - 1)  * lRate) + 1);
		}
	}
}