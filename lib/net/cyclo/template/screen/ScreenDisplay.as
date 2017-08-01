package net.cyclo.template.screen {
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	import net.cyclo.shell.device.MobileDeviceMgr;
	
	/**
	 * descripteur de positionnement automatique à l'écran
	 * 
	 * @author nico
	 */
	public class ScreenDisplay {
		/** tag de position gauche */
		public static const POS_LEFT							: String									= "left";
		/** tag de position droite */
		public static const POS_RIGHT							: String									= "right";
		/** tag de position haute */
		public static const POS_TOP								: String									= "top";
		/** tag de position basse */
		public static const POS_BOT								: String									= "bot";
		/** tag de position milieu */
		public static const POS_MID								: String									= "mid";
		
		/** tag de position courrente horizontale */
		protected var posH										: String									= null;
		/** tag de position courrente verticale */
		protected var posV										: String									= null;
		
		/** delta en x par rapport à la position d'écran horizontale */
		protected var dx										: Number									= 0;
		/** delta en y par rapport à la position d'écran verticale */
		protected var dy										: Number									= 0;
		
		/**
		 * construction : on défini le positionnement d'un élément d'écran orientable
		 * @param	pHPos	tag de position horizontale ; si null, on prend ::POS_MID
		 * @param	pVTos	tag de position verticale ; si null, on prend ::POS_MID
		 * @param	pDX		delta en x par rapport à la position d'écran horizontale
		 * @param	pDY		delta en y par rapport à la position d'écran verticale
		 */
		public function ScreenDisplay( pHPos : String = null, pVPos : String = null, pDX : Number = 0, pDY : Number = 0) {
			posH	= pHPos == null ? POS_MID : pHPos;
			posV	= pVPos == null ? POS_MID : pVPos;
			dx		= pDX;
			dy		= pDY;
		}
		
		/**
		 * on effectue l'ajustement de position adaptée à l'orientation du device, dans un conteneur qui n'est pas tourné automatiquement
		 * @param	pDisp	l'élément graphique à ajuster
		 * @param	pConf	descripteur de positionnement associé, si null on prend une config par défaut (voir constructeur)
		 */
		public static function doPos( pDisp : DisplayObject, pConf : ScreenDisplay) : void {
			var lRect	: Rectangle	= MobileDeviceMgr.getInstance().mobileFullscreenRect;
			var lRot	: int		= MobileDeviceMgr.getInstance().rotContent;
			
			if ( pConf == null) pConf = new ScreenDisplay();
			
			if ( lRot == -90) {
				if ( pConf.posH == POS_LEFT) pDisp.y = lRect.bottom;
				else if ( pConf.posH == POS_RIGHT) pDisp.y = lRect.top;
				else pDisp.y = ( lRect.top + lRect.bottom) / 2;
				
				pDisp.y -= pConf.dx;
				
				if ( pConf.posV == POS_TOP) pDisp.x = lRect.left;
				else if ( pConf.posV == POS_BOT) pDisp.x = lRect.right;
				else pDisp.x = ( lRect.left + lRect.right) / 2;
				
				pDisp.x += pConf.dy;
			}else if ( lRot == 0) {
				if ( pConf.posH == POS_LEFT) pDisp.x = lRect.left;
				else if ( pConf.posH == POS_RIGHT) pDisp.x = lRect.right;
				else pDisp.x = ( lRect.left + lRect.right) / 2;
				
				pDisp.x += pConf.dx;
				
				if ( pConf.posV == POS_TOP) pDisp.y = lRect.top;
				else if ( pConf.posV == POS_BOT) pDisp.y = lRect.bottom;
				else pDisp.y = ( lRect.top + lRect.bottom) / 2;
				
				pDisp.y += pConf.dy;
			}else if ( lRot == 90) {
				if ( pConf.posH == POS_LEFT) pDisp.y = lRect.top;
				else if ( pConf.posH == POS_RIGHT) pDisp.y = lRect.bottom;
				else pDisp.y = ( lRect.top + lRect.bottom) / 2;
				
				pDisp.y += pConf.dx;
				
				if ( pConf.posV == POS_TOP) pDisp.x = lRect.right;
				else if ( pConf.posV == POS_BOT) pDisp.x = lRect.left;
				else pDisp.x = ( lRect.left + lRect.right) / 2;
				
				pDisp.x -= pConf.dy;
			}else {
				if ( pConf.posH == POS_LEFT) pDisp.x = lRect.right;
				else if ( pConf.posH == POS_RIGHT) pDisp.x = lRect.left;
				else pDisp.x = ( lRect.left + lRect.right) / 2;
				
				pDisp.x -= pConf.dx;
				
				if ( pConf.posV == POS_TOP) pDisp.y = lRect.bottom;
				else if ( pConf.posV == POS_BOT) pDisp.y = lRect.top;
				else pDisp.y = ( lRect.top + lRect.bottom) / 2;
				
				pDisp.y -= pConf.dy;
			}
			
			pDisp.rotation = lRot;
		}
	}
}