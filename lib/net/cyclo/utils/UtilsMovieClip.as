package net.cyclo.utils {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.bitmap.BitmapMovieClip;
	import net.cyclo.bitmap.BitmapMovieClipMgr;
	import net.cyclo.ui.local.ILocalListener;
	
	/**
	 * méthode utilitaires de MovieClip
	 * @author	nico
	 */
	public class UtilsMovieClip {
		/**
		 * on vérifie si une animation est arrivée à son terme ; prise en charge d'anim instanciée de time line embeded (cache un objet Loader interne)
		 * @param	pMC		animation dont on vérifie la timeline pour savoir si elle est terminée
		 * @return	true si animation terminée, false sinon
		 */
		public static function isCurrentFrameAtTotal( pMC : MovieClip) : Boolean {
			if ( pMC.numChildren == 1 && pMC.getChildAt( 0) is Loader) {
				pMC = ( pMC.getChildAt( 0) as Loader).content as MovieClip;
				
				if ( pMC != null) return pMC.currentFrame == pMC.totalFrames;
				else return false;
			}else return pMC.currentFrame == pMC.totalFrames;
		}
		
		/**
		 * on centre le graphisme
		 * @param	pDisp	graphisme à centrer
		 */
		public static function center( pDisp : DisplayObject) : void {
			var lBmp	: BitmapMovieClip;
			var lData	: BitmapData;
			
			if( pDisp is BitmapMovieClip){
				lBmp 	= pDisp as BitmapMovieClip;
				lData	= BitmapMovieClipMgr.getBmpInfos( lBmp.bmpId).getFrameInfos( lBmp.currentFrame).bmp;
				
				pDisp.x	= -lData.width / 2;
				pDisp.y	= -lData.height / 2;
			}else if ( pDisp is AssetInstance && ( pDisp as AssetInstance).content is BitmapMovieClip) {
				lBmp	= ( pDisp as AssetInstance).content as BitmapMovieClip;
				lData	= BitmapMovieClipMgr.getBmpInfos( lBmp.bmpId).getFrameInfos( lBmp.currentFrame).bmp;
				
				pDisp.x	= -lData.width / 2;
				pDisp.y	= -lData.height / 2;
			}else{
				pDisp.x	= -pDisp.width / 2;
				pDisp.y = -pDisp.height / 2;
			}
		}
		
		/**
		 * on convertit un identifiant de classe de movie clip (id de liaison) en notation "getQualifiedClassName" : on vire le dernier "." du path pour remplacer par "::"
		 * @param	pClassId	id de liason de movie clip en notation de path pointée
		 * @return	identifiant au formalisme "getQualifiedClassName"
		 */
		public static function fromClassIdToQualifiedClassName( pClassId : String) : String {
			var lI : int	= pClassId.lastIndexOf( ".");
			
			if( lI != -1 && pClassId.indexOf( "::") == -1) return pClassId.substring( 0, lI) + "::" + pClassId.substring( lI + 1);
			else return pClassId;
		}
		
		/**
		 * remove complet d'un objet graphique
		 * @param	pDisp	objet graphique à effacer
		 */
		public static function free( pDisp : DisplayObject) : void {
			if ( pDisp is DisplayObjectContainer) recursiveGotoAndStop( DisplayObjectContainer( pDisp), 1);
			
			clearFromParent( pDisp);
		}
		
		/**
		 * vire un objet graphique de son conteneur
		 * @param	pClip	objet graphique à virer de son conteneur
		 */
		public static function clearFromParent( pClip : DisplayObject) : void {
			var lParent : DisplayObjectContainer = pClip.parent;
			
			if( lParent != null){
				lParent.removeChild( pClip);
				
				if( lParent.hasOwnProperty( pClip.name)) lParent[ pClip.name] = null;
			}
		}
		
		/**
		 * stop recursif sur un conteneur graphique
		 * @param	pClip	conteneur graphique
		 */
		public static function recursiveStop( pClip : DisplayObjectContainer) : void {
			var lChild	: DisplayObject;
			var lI		: int;
			
			if( pClip is MovieClip) MovieClip( pClip).stop();
			
			for( lI = 0 ; lI < pClip.numChildren ; lI++){
				lChild = pClip.getChildAt( lI);
				
				if( lChild is DisplayObjectContainer) recursiveStop( DisplayObjectContainer( lChild));
			}
		}
		
		/**
		 * play récursif sur un conteneur graphique
		 * @param	pClip	conteneur graphique
		 */
		public static function recursivePlay( pClip : DisplayObjectContainer) : void {
			var lChild	: DisplayObject;
			var lI		: int;
			
			if ( pClip is MovieClip) {
				MovieClip( pClip).play();
			}
			
			for( lI = 0 ; lI < pClip.numChildren ; lI++){
				lChild = pClip.getChildAt( lI);
				
				if( lChild is DisplayObjectContainer) recursivePlay( DisplayObjectContainer( lChild));
			}
		}
		
		/**
		 * on force la mise à jour de localisation de tous les enfants du conteneur précisé ; un enfant peut recevoir une mise à jour si il implémente l'interface ILocalListener
		 * @param	pContainer	conteneur
		 */
		public static function recursiveLocalUpdate( pContainer : DisplayObjectContainer) : void {
			var lChild	: DisplayObject;
			var lI		: int;
			
			for ( lI = 0 ; lI < pContainer.numChildren ; lI++) {
				lChild = pContainer.getChildAt( lI);
				
				if ( lChild is ILocalListener) ( lChild as ILocalListener).onLocalUpdate();
				
				if( lChild is DisplayObjectContainer) recursiveLocalUpdate( lChild as DisplayObjectContainer)
			}
		}
		
		/**
		 * gotoAndStop récursif sur un conteneur graphique
		 * @param	pClip	conteneur graphique
		 * @param	pFrame	frame à laquelle se rendre dans tout le contenu
		 */
		public static function recursiveGotoAndStop( pClip : DisplayObjectContainer, pFrame : Object) : void {
			var lChild	: DisplayObject;
			var lI		: int;
			
			if ( pClip is MovieClip) MovieClip( pClip).gotoAndStop( pFrame);
			
			for( lI = 0 ; lI < pClip.numChildren ; lI++){
				lChild = pClip.getChildAt( lI);
				
				if( lChild is DisplayObjectContainer) recursiveGotoAndStop( DisplayObjectContainer( lChild), pFrame);
			}
		}
		
		/**
		 * on arrondit la position de l'objet graphique en scène pour qu'il soit en coordonnées entières sur le stage
		 * @param	pDisp	objet graphique en scène (sa propriété stage est définie) ; cet objet sera repositionné (x, y)
		 */
		public static function roundCoordOnStage( pDisp : DisplayObject) : void {
			var lCoord	: Point	= pDisp.parent.localToGlobal( new Point( pDisp.x, pDisp.y));
			
			lCoord.x	= Math.round( lCoord.x);
			lCoord.y	= Math.round( lCoord.y);
			
			lCoord		= pDisp.parent.globalToLocal( lCoord);
			
			pDisp.x		= lCoord.x;
			pDisp.y		= lCoord.y;
		}
	}
}