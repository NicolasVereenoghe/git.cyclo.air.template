package net.cyclo.assets {
	import flash.geom.Matrix;
	
	/**
	 * struct définissant les paramètres de rendu d'un asset
	 * 
	 * @author	nico
	 */
	public class AssetRender {
		/** constante définissant le type de rendu vecto */
		public static const RENDER_VECTO		: String	= "vecto";
		/** constante définissant le type de rendu bitmap */
		public static const RENDER_BITMAP		: String	= "bitmap";
		
		/** le nom de type de parsing en profondeur : recherche récursive des bitmaps (instances de BitmapMovieClip) dans les imbrications de la première image de chaque conteneur rencontré */
		public static const PARSE_IN_DEPTH		: String	= "in-depth";
		/** le nom de type de parsing en "longueur" : recherche de bitmaps (instances de BitmapMovieClip) sur toute la time-line contenue dans l'export d'asset */
		public static const PARSE_IN_LENGTH		: String	= "in-length";
		
		/** type de rendu d'asset */
		public var render						: String;
		
		/** paramètre "snap" de rendu bitmap ; utiliser les constantes de la classe PixelSnapping */
		public var snap							: String	= "never";
		/** paramètre "smooth" de rendu bitmap */
		public var smooth						: Boolean	= false;
		/** paramètre "stabil" de rendu bitmap */
		public var stabil						: Boolean	= false;
		/** matrix de transformation du rendu bitmap (contrôle de qualité) : la rasterization se fait avec cette transformation, pour le rendu on fait une compensation inverse ; null si pas de transfo */
		public var bmpTrans						: Matrix	= null;
		/** indique si le bmp généré prend en compte le scale global appliqué sur l'appli (false), ou si on a une qualité fixe quelque soit le scale global (true) */
		public var bmpFixedQ					: Boolean	= false;
		
		/** mode de parsing des bitmaps (instances de BitmapMovieClip) dans un export de type vecto (RENDER_VECTO) ; utilser les constantes PARSE_IN_DEPTH o uPARSE_IN_LENGTH ; null si pas défini (et donc pas de parsing) */
		public var bmpParseMode					: String	= null;
		
		/** pas d'avancement du parsing bitmap */
		public var bmpStepParse					: int		= 1;
		
		/** indique si on ignore la génération des bitmap lors du parsing d'un asset composité (true), ou si on les génère à la vollée */
		public var ignoreParseBmp				: Boolean	= false;
		
		/**
		 * construction
		 * @param	pType	type de rendu (vecto ou bitmap) ; utiliser les constantes
		 * @param	pNode	node xml désignant décrivant les paramètres de rendu bitmap ; pour un rendu vecto, ces params concernent les éventuels bitmaps contenus
		 */
		public function AssetRender( pType : String, pNode : XML = null) {
			render	= pType;
			
			if( pNode != null){
				if( pNode.@snap != undefined) snap = pNode.@snap;
				if( pNode.@smooth == "true") smooth = true;
				if( pNode.@stabil == "true") stabil = true;
				if( pNode.@parse_mode != undefined) bmpParseMode = pNode.@parse_mode;
				if( pNode.@step != undefined) bmpStepParse = parseInt( pNode.@step);
				if ( pNode.@ignoreParseBmp == "true") ignoreParseBmp = true;
				if ( pNode.@fixedQ == "true") bmpFixedQ = true;
				
				bmpTrans = AssetsSharedProperties.parseTrans( pNode);
			}
		}
	}
}