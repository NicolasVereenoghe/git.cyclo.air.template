package net.cyclo.assets {
	
	/**
	 * implémentation d'un écouter d'allocation mémoire d'assets
	 * @author 
	 */
	public class NotifyMallocAssets implements INotifyMallocAssets {
		/** ref sur callback de notification d'allocation finie, utiliser la même signature que ::onMallocAssetsEnd ; si null, pas de notification */
		protected var _onEnd				: Function		= null;
		
		/** ref sur callback de notification de progression d'allocation, utiliser la même signature que ::onMallocAssetsProgress ; si null, pas de notification */
		protected var _onProgress			: Function		= null;
		
		/**
		 * construction
		 * @param	pOnEnd		callback de notification d'allocation finie, utiliser la même signature que ::onMallocAssetsEnd ; si null, pas de notification
		 * @param	pOnProgress	callback de notification de progression d'allocation, utiliser la même signature que ::onMallocAssetsProgress ; si null, pas de notification
		 */
		public function NotifyMallocAssets( pOnEnd : Function, pOnProgress : Function = null) {
			_onEnd		= pOnEnd;
			_onProgress	= pOnProgress;
		}
		
		/** @inheritDoc */
		public function onMallocAssetsEnd() : void {
			if ( _onEnd != null) {
				_onEnd();
				
				_onEnd		= null;
				_onProgress	= null;
			}
		}
		
		/** @inheritDoc */
		public function onMallocAssetsProgress( pCurrent : int, pTotal : int) : void { if ( _onProgress != null) _onProgress( pCurrent, pTotal);}
	}

}