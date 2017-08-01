package net.cyclo.template.game.hud {
	import flash.geom.Point;
	import net.cyclo.assets.AssetInstance;
	import net.cyclo.assets.AssetsMgr;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * feedback spécialisé évènement de type push
	 * pas d'interférence avec les feedback originaux
	 * ces feedback sont mis en tempon si déjà un exclusif en cours (traitement dans le FeedbackDisplayMgr)
	 * 
	 * @author nico
	 */
	public class FeedbackPush extends Feedback {
		/** amplitude du bump d'ouverture */
		protected var BUMP_DIST													: Number												= 90;
		/** vecteur directeur du bump */
		protected var BUMP_DIR													: Point													= new Point( 0, 1);
		
		/** alpha min du bump */
		protected var BUMP_MIN_ALPHA											: Number												= .2;
		/** degré de progression de l'alpha lors du bump */
		protected var BUMP_ALPHA_DEG											: Number												= .2;
		
		/** délai de l'effet élastique en nombre de frame, joué en fin d'ouverture, et en début de fermeture */
		protected var ELASTIC_DELAY												: int													= 6;
		/** amplitude max de l'effet élastique */
		protected var ELASTIC_DIST												: Number												= 4;
		/** nombre de périodes de l'effets élastique */
		protected var ELASTIC_PERIOD											: Number												= 1.5;
		/** degré de dprogression de l'oscillation élastique */
		protected var ELASTIC_DEG												: Number												= 1.7;
		
		/**
		 * construction
		 */
		public function FeedbackPush() {
			super();
			
			WAIT_DELAY = 90;
		}
		
		/** @inheritDoc */
		override public function destroy() : void {
			UtilsMovieClip.clearFromParent( asset);
			asset.free();
			asset = null;
			
			mgr = null;
		}
		
		/** @inheritDoc */
		override public function doFrame() : Boolean {
			var lRate	: Number;
			
			if ( ctr < OPEN_ANIM_DELAY - ELASTIC_DELAY) {
				lRate = ctr / ( OPEN_ANIM_DELAY - ELASTIC_DELAY);
				
				asset.x		= lRate * BUMP_DIR.x * BUMP_DIST;
				asset.y		= lRate * BUMP_DIR.y * BUMP_DIST;
				asset.alpha	= BUMP_MIN_ALPHA + Math.pow( lRate, BUMP_ALPHA_DEG) * ( 1 - BUMP_MIN_ALPHA);
			}else if ( ctr < OPEN_ANIM_DELAY) {
				lRate = Math.sin( 2 * Math.PI * Math.pow( ( ctr - OPEN_ANIM_DELAY + ELASTIC_DELAY) / ELASTIC_DELAY, ELASTIC_DEG) * ELASTIC_PERIOD);
				
				asset.x		= BUMP_DIR.x * ( lRate * ELASTIC_DIST + BUMP_DIST);
				asset.y		= BUMP_DIR.y * ( lRate * ELASTIC_DIST + BUMP_DIST);
				asset.alpha	= 1;
			}else if ( ctr < OPEN_ANIM_DELAY + WAIT_DELAY) {
				asset.x	= BUMP_DIR.x * BUMP_DIST;
				asset.y	= BUMP_DIR.y * BUMP_DIST;
			}else if ( ctr < OPEN_ANIM_DELAY + WAIT_DELAY + ELASTIC_DELAY) {
				lRate = Math.sin( 2 * Math.PI * Math.pow( 1 - ( ctr - OPEN_ANIM_DELAY - WAIT_DELAY) / ELASTIC_DELAY, ELASTIC_DEG) * ELASTIC_PERIOD);
				
				asset.x	= BUMP_DIR.x * ( lRate * ELASTIC_DIST + BUMP_DIST);
				asset.y	= BUMP_DIR.y * ( lRate * ELASTIC_DIST + BUMP_DIST);
			}else if ( ctr < 2 * OPEN_ANIM_DELAY + WAIT_DELAY) {
				lRate = ( 2 * OPEN_ANIM_DELAY + WAIT_DELAY - ctr) / ( OPEN_ANIM_DELAY - ELASTIC_DELAY);
				
				asset.x		= lRate * BUMP_DIR.x * BUMP_DIST;
				asset.y		= lRate * BUMP_DIR.y * BUMP_DIST;
				asset.alpha	= BUMP_MIN_ALPHA + Math.pow( lRate, BUMP_ALPHA_DEG) * ( 1 - BUMP_MIN_ALPHA);
			}else return false;
			
			ctr++;
			
			return true;
		}
		
		/** @inheritDoc */
		override protected function buildContent() : void { asset = addChild( AssetsMgr.getInstance().getAssetInstance( _id)) as AssetInstance; }
	}
}