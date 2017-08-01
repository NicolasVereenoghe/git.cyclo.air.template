package net.cyclo.mysprite {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.text.TextField;
	
	/**
	 * dictionnaire de descripteurs de levels
	 * 
	 * @author	nico
	 */
	public class LvlMgr {
		/** clef de valeur d'abscisse initiale de l'écran dans un lvl */
		public static const DATA_INIT_X				: String							= "INIT_X";
		/** clef de valeur d'ordonnée initiale de l'écran dans un lvl */
		public static const DATA_INIT_Y				: String							= "INIT_Y";
		
		/** clef de valeur d'abscisse initiale du joueur dans un lvl */
		public static const DATA_PLAYER_X			: String							= "PLAYER_X";
		/** clef de valeur d'ordonnée initiale du joueur dans un lvl */
		public static const DATA_PLAYER_Y			: String							= "PLAYER_Y";
		/** clef de valeur d'orientation initiale du joueur en deg dans un lvl */
		public static const DATA_PLAYER_ORIENT		: String							= "PLAYER_ORIENT";
		
		/** réf sur le singleton */
		protected static var current				: LvlMgr							= null;
		
		/** nom de scène du clip servant de marque de position initiale de l'écran */
		protected var SCREEN_MC						: String							= "mcScreen";
		/** nom de scène du clip servant de marque de position initiale du joueur */
		protected var PLAYER_MC						: String							= "mcPlayer";
		
		/** identifiuant de level par défaut */
		protected var LVL_DEFAULT_ID				: String							= "default";
		
		/** map de données de levels indexés par id de level ; { map: <map de LvlGroundMgr indexés par id de ground>, sorted: <liste de grounds listés par ordre croissant de profondeur>, datas: <liste de clefs / valeurs associées à ce level>} */
		protected var lvls							: Object							= null;
		
		/**
		 * accesseur au singleton ; si le singleton n'existe pas, on le crée
		 * @return	singleton
		 */
		public static function getInstance() : LvlMgr {
			if ( current == null) new LvlMgr();
			
			return current;
		}
		
		/**
		 * construction, set du singleton
		 */
		public function LvlMgr() {
			current	= this;
			lvls	= new Object();
		}
		
		/**
		 * on parse un clip descripteur de level
		 * @param	pTmp	clip template descripteur de niveaux
		 * @param	pLvlId	identifiant de niveau parsé, laisser null pour id par défaut et a priori n'avoir qu'un seul niveau
		 */
		public function parseLvlTemplate( pTmp : DisplayObjectContainer, pLvlId : String = null) : void {
			var lLvlData	: Object		= { map: { }, sorted: [], datas: { } };
			var lI			: int;
			var lContent	: DisplayObject;
			var lLvl		: LvlGroundMgr;
			
			lvls[ pLvlId == null ? LVL_DEFAULT_ID : pLvlId] = lLvlData;
			
			for ( lI = 0 ; lI < pTmp.numChildren ; lI++) {
				lContent	= pTmp.getChildAt( lI);
				
				if ( lContent.name == SCREEN_MC) {
					lLvlData.datas[ DATA_INIT_X] = lContent.x.toString();
					lLvlData.datas[ DATA_INIT_Y] = lContent.y.toString();
				}else if ( lContent.name == PLAYER_MC) {
					lLvlData.datas[ DATA_PLAYER_X] = lContent.x.toString();
					lLvlData.datas[ DATA_PLAYER_Y] = lContent.y.toString();
					lLvlData.datas[ DATA_PLAYER_ORIENT] = lContent.rotation.toString();
				}else if ( lContent is TextField) {
					lLvlData.datas[ lContent.name] = ( lContent as TextField).text;
				}else if ( lContent is DisplayObjectContainer) {
					if ( ! lLvlData.map[ lContent.name]) {
						lLvl = getLvlGroundMgrInstance( lContent as DisplayObjectContainer, pLvlId);
						
						lLvlData.map[ lLvl.id] = lLvl;
						lLvlData.sorted.push( lLvl);
					}
				}
			}
		}
		
		/**
		 * on récupère une donnée de niveau
		 * @param	pKey	clef de valeur
		 * @param	pId		identifiant de niveau ou laisser null pour lvl par défaut
		 * @return	donnée ou null si pas trouvée
		 */
		public function getLvlData( pKey : String, pId : String = null) : String {
			if ( pId == null) pId = LVL_DEFAULT_ID;
			
			return lvls[ pId].datas[ pKey];
		}
		
		/**
		 * on récupère un ground en fonction de son identifiant
		 * @param	pId		identifiant du ground recherché
		 * @param	pLvlId	identifiant de level auquel appartient ce ground (doit exister si spécifié), ou laisser null pour rechercher dans le seul level défini
		 * @return	ground ou null si pas trouvé
		 */
		public function getLvlGroundMgrById( pId : String, pLvlId : String = null) : LvlGroundMgr {
			if ( pLvlId == null) pLvlId = LVL_DEFAULT_ID;
			
			return lvls[ pLvlId].map[ pId];
		}
		
		/**
		 * on récupère un ground en fonction de son indice de profondeur
		 * @param	pI		indice de profondeur (0 .. n-1)
		 * @param	pLvlId	identifiant de level auquel appartient ce ground (doit exister si spécifié), ou laisser null pour rechercher dans le seul level défini
		 * @return	ground, ou null si indice hors limite
		 */
		public function getLvlGroundMgr( pI : int, pLvlId : String = null) : LvlGroundMgr {
			if ( pLvlId == null) pLvlId = LVL_DEFAULT_ID;
			
			if ( pI < lvls[ pLvlId].sorted.length) return lvls[ pLvlId].sorted[ pI];
			else return null;
		}
		
		/**
		 * hook : on capte une cellule après son enregistrement lors du parsing du level
		 * @param	pCell	cellule enregistrée
		 * @return	cette même cellule
		 */
		public function onCellParsed( pCell : MyCellDesc) : MyCellDesc { return pCell; }
		
		/**
		 * on crée un descripteur de plan de sprites
		 * @param	pCont	le conteneur de sprites à parser par le descripteur
		 * @param	pLvlId	identifiant de level auquel appartient ce ground
		 * @return	descripteur de plan initialisé (map de sprite remplie)
		 */
		protected function getLvlGroundMgrInstance( pCont : DisplayObjectContainer, pLvlId : String = null) : LvlGroundMgr { return new LvlGroundMgr( pCont.name, pLvlId == null ? LVL_DEFAULT_ID : pLvlId, pCont); }
	}
}