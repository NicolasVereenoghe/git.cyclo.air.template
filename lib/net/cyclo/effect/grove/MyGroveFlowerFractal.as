package net.cyclo.effect.grove {
	import net.cyclo.effect.MyFractalMgr;
	import net.cyclo.effect.MyFractalRing;
	
	/**
	 * un fractal en spiral spécialisé en rendu de fleur de bosquet
	 * 
	 * @author nico
	 */
	public class MyGroveFlowerFractal extends MyFractalMgr {
		/**
		 * construction
		 */
		public function MyGroveFlowerFractal() { super(); }
		
		/** @inheritDoc */
		override protected function instanciateRingAt( pIndex : int = -1) : MyFractalRing {
			if ( pIndex > -1) return addChild( new MyGroveFlowerFractalRing()) as MyFractalRing;
			else return addChildAt( new MyGroveFlowerFractalRing(), 0) as MyFractalRing;
		}
	}
}