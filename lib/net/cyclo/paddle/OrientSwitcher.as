package net.cyclo.paddle {
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * capture la notification de changement de référentiel du composant de gestion d'accéléromètre (AcceleroMultiMode)
	 * spécialisé dans le changement d'orientations uniquement, util pour une interface
	 * 
	 * @author nico
	 */
	public class OrientSwitcher extends AcceleroModeSwitcher {
		/** @inheritDoc */
		public function OrientSwitcher( pFXContainer : Sprite, pContent : DisplayObject, pContentBGColor : uint, pSwitchBGColor : uint, pSwitchListener : ISwitchModeListener = null) {
			super( pFXContainer, pContent, pContentBGColor, pSwitchBGColor, pSwitchListener);
		}
		
		/** @inheritDoc */
		override public function onRefChange( pFrom : Object, pTo : Object) : void {
			if( pFrom != null && AcceleroModeSwitcher.getPopRot( pFrom) != AcceleroModeSwitcher.getPopRot( pTo)) super.onRefChange( pFrom, pTo);
			else switchListener.onRefChange( pFrom, pTo);
		}
		
		/** @inheritDoc */
		override protected function initEffect( pFrom : Object, pTo : Object) : void {
			var lDif	: Number	= AcceleroModeSwitcher.getPopRot( pTo) - AcceleroModeSwitcher.getPopRot( pFrom);
			
			if ( lDif > 180) lDif -= 360;
			else if ( lDif < -180) lDif += 360;
			
			if( ! isFraming()){
				fxContainer.addEventListener( Event.ENTER_FRAME, doFrame);
				
				fxContainer.visible	= true;
			}
			
			ctrAnim			= 0;
			fxBg.visible	= true;
			content.visible	= false;
			
			fxBmpContainer.rotationZ	= lDif < 0 ? ANIM_Z_ROT_MAX : -ANIM_Z_ROT_MAX;
			animFromXYZ					= { x: 0, y: 0, z: fxBmpContainer.rotationZ };
		}
	}
}