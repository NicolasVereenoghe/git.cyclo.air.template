package net.cyclo.assets {
	import flash.geom.Matrix;
	
	import net.cyclo.loading.file.MyFile;
	
	/**
	 * propriétés partagées d'assets (fichier source, type de rendu, tranfsormation, nombre d'instances)
	 * 
	 * @author	nico
	 */
	public class AssetsSharedProperties {
		/** constante définissant l'état déverrouillé du verrou d'instances supplémentaires */
		public static const LOCKER_UNLOCKED		: String		= "unlock_instance";
		/** constante définissant l'état verrouillé du verrou d'instances supplémentaires */
		public static const LOCKER_LOCKED		: String		= "lock_instance";
		/** constante définissant l'état non défini du verrou d'instances supplémentaires */
		public static const LOCKER_UNDEFINED	: String		= "lock_undefined";
		
		/** tag de type de génération d'export "interne", c'est à dire construit depuis le descripteur d'asset */
		public static const GEN_INTERNAL		: String		= "internal";
		/** tag de type de génération d'export "externe", c'est à dire qu'on fait appel à une méthode d'interface IAssetExportGenerator pour créer une instance d'export */
		public static const GEN_EXTERNAL		: String		= "external";
		
		/** transformation à appliquer, ou null si aucune */
		public var trans						: Matrix;
		/** fichier d'assets, ou null si aucun */
		public var file							: MyFile;
		/** fichier de template, ou null si aucun */
		public var templateFile					: MyFile;
		/** struct définissant le type de rendu, ou null si non défini */
		public var render						: AssetRender;
		/** nombre d'instances d'assets à mettre en mémoire, -1 si pas défini */
		public var instanceCount				: int;
		/** état du verrou d'instance : est-ce qu'on empile en mémoire les instances supplémentaires ou pas : soit déverrouillé (on continue d'empiler), soit verrouillé, soit pas défini ; voir les constantes de définition */
		public var lockInstance					: String;
		/** valeur de l'alpha des templates quand un asset possède déjà un export ; si aucun export défini, le template est pleinement visible ; 0 .. 1 ; si pas défini, -1 */
		public var templateAlpha				: Number;
		/** map de clefs auxquelles correspondent des valeurs ; instance de map vide si aucune clef-valeur */
		public var datas						: Object;
		/** tag de nom de mode de génération d'export ; voir constantes ::GEN_INTERNAL et ::GEN_EXTERNAL null si non défini */
		public var generateMode					: String;
		
		/**
		 * constructeur : on parse le xml de config contenant (ou pas) des propriétés paratagée
		 * @param	pConfig	node xml de config de propriétés partagée, ou null si aucune propriété définie
		 */
		public function AssetsSharedProperties( pConfig : XML) {
			trans			= pConfig ? parseTrans( pConfig) : null;
			file			= pConfig ? parseFile( pConfig) : null;
			templateFile	= pConfig ? parseFile( pConfig, "file_template") : null;
			render			= pConfig ? parseRender( pConfig) : null;
			instanceCount	= pConfig ? parseInstanceCount( pConfig) : -1;
			templateAlpha	= pConfig ? parseTemplateAlpha( pConfig) : -1;
			lockInstance	= pConfig ? parseLockInstance( pConfig) : LOCKER_UNDEFINED;
			datas			= pConfig ? parseDatas( pConfig) : new Object();
			generateMode	= pConfig ? parseGenMode( pConfig) : null;
			
			/*if ( file != null && file.isIMG() && render == null) {
				render = new AssetRender( AssetRender.RENDER_BITMAP);
			}*/
		}
		
		/**
		 * construction d'une matrice de transformation à partir d'un node xml qui contient évetuellement un node <transform>
		 * @param	pNode	node xml contenant éventuellement un node <transform>
		 * @return	matrice de transformation construite à partir de l'éventuel node <transform> trouvé, sinon on retourne null
		 */
		public static function parseTrans( pNode : XML) : Matrix {
			var lTrans	: XML		= pNode.transform[ 0];
			var lMtrx	: Matrix;
			
			if( lTrans && lTrans.children().length()){
				lMtrx = new Matrix();
				
				lMtrx.createBox(
					lTrans.scalex[ 0] ? parseFloat( lTrans.scalex[ 0]) : 1,
					lTrans.scaley[ 0] ? parseFloat( lTrans.scaley[ 0]) : 1,
					lTrans.rotation[ 0] ? parseFloat( lTrans.rotation[ 0]) * Math.PI / 180 : 0,
					lTrans.dx[ 0] ? parseFloat( lTrans.dx[ 0]) : 0,
					lTrans.dy[ 0] ? parseFloat( lTrans.dy[ 0]) : 0
				);
				
				return lMtrx;
			}else return null;
		}
		
		/**
		 * retrouve le tag de mode de géréation d'asset dans le xml de config d'asset
		 * @param	pNode	node xml contenant éventuellement les tags <internal/> ou <external/>
		 * @return	tag de mode génération, ou null si rien de défini
		 */
		protected function parseGenMode( pNode : XML) : String {
			if ( pNode.child( "internal")[ 0]) return GEN_INTERNAL;
			else if ( pNode.external[ 0]) return GEN_EXTERNAL;
			else return null;
		}
		
		/**
		 * construction d'un descripteur de fichier d'assets à charger à partir d'un node xml qui contient éventuellement un node <file>
		 * @param	pNode	node xml contenant éventuellement un node <file>
		 * @param	pName	nom de node <file> alternatif ; par défaut le nom est "file"
		 * @return	descripteur de fichier d'assets à charger, ou null si pas de node <file> trouvé
		 */
		protected function parseFile( pNode : XML, pName : String = "file") : MyFile {
			var lFile	: XML	= pNode.child( pName)[ 0];
			
			if( lFile && lFile.children().length()){
				return new MyFile(
					lFile.name[ 0],
					lFile.path[ 0] ? lFile.path[ 0] : null,
					lFile.version[ 0] ? lFile.version[ 0] : null,
					lFile.domain[ 0] ? lFile.domain[ 0] : null
				);
			}else return null;
		}
		
		/**
		 * détermine si le rendu doit être fait en bitmap pour les assets désignés par un node xml de config
		 * @param	pNode	node xml désignant un ensemble d'assets et contenant éventuellement une info de rendu
		 * @return	struct de définition de rendu, ou null si pas défini
		 */
		protected function parseRender( pNode : XML) : AssetRender {
			if( pNode.bitmap[ 0]) return new AssetRender( AssetRender.RENDER_BITMAP, pNode.bitmap[ 0]);
			else if( pNode.vecto[ 0]) return new AssetRender( AssetRender.RENDER_VECTO, pNode.vecto[ 0]);
			else return null;
		}
		
		/**
		 * détermine le nombre d'instances qui doivent être mises en mémoire pour les assets désignés par un node xml de config
		 * @param	pNode	node xml désignant un ensemble d'assets et contenant éventuellement une info sur le nombre d'instances
		 * @return	nombre d'instances à mettre en mémoire, ou -1 si pas d'info définies
		 */
		protected function parseInstanceCount( pNode : XML) : int {
			if( pNode.instance[ 0]) return parseInt( pNode.instance[ 0]);
			else return -1;
		}
		
		/**
		 * retrouve le valeur de l'alpha du template d'un asset dans le xml de config
		 * @param	pNode	node xml désignant un ensemble d'assets et contenant éventuellement une info sur l'alpha des templates
		 * @return	valeur de l'alpha (0..1), ou -1 si non défini
		 */
		protected function parseTemplateAlpha( pNode : XML) : Number {
			if( pNode.template_alpha[ 0]) return parseFloat( pNode.template_alpha[ 0]);
			else return -1;
		}
		
		/**
		 * retrouve la valeur de verrou d'instance dans le xml de config
		 * @param	pNode	node xml désignant un ensemble d'assets et contenant éventuellement une info sur le verrou d'instance
		 * @return	nom d'état du verrou d'instance, ou LOCKER_UNDEFINED si non défini
		 */
		protected function parseLockInstance( pNode : XML) : String {
			if( pNode.lock_instance[ 0]) return LOCKER_LOCKED;
			else if( pNode.unlock_instance[ 0]) return LOCKER_UNLOCKED;
			else return LOCKER_UNDEFINED;
		}
		
		/**
		 * construit une map de clef-valeur à partir de la config xml
		 * @param	node xml de config contenant éventuellement un node <datas> de liste de clef-valeur
		 * @return	map de clef-valeur
		 */
		protected function parseDatas( pNode : XML) : Object {
			var lDatas	: XMLList	= pNode.datas.data;
			var lRes 	: Object	= new Object();
			var lI		: int;
			
			for( lI = 0 ; lI < lDatas.length() ; lI++){
				lRes[ lDatas[ lI].id[ 0].toString()] = lDatas[ lI].value[ 0].toString();
			}
			
			return lRes;
		}
	}
}