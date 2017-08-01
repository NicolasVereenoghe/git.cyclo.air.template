package net.cyclo.assets {
	import flash.geom.Matrix;
	
	import net.cyclo.loading.file.MyFile;
	
	/**
	 * un groupe d'assets
	 * 
	 * @author	nico
	 */
	public class AssetGroupDesc {
		/** identifiant de groupe */
		public var id				: String;
		/** map de groupes enfants indexés par id de groupe */
		public var childs			: Object;
		/** ref sur le groupe parent ; null si aucun */
		public var parent			: AssetGroupDesc;
		/** map d'assets enfants (AssetDesc) de ce groupe indexée par id d'asset */
		public var assets			: Object;
		
		/** propriétés partagées de l'ensemble des assets de ce groupe */
		public var sharedProperties	: AssetsSharedProperties;
		
		/**
		 * constructeur
		 * @param	pConfig	node xml de config du groupe ; null si rien n'est spécifié
		 * @param	pParent	le groupe d'assets parent, ou null si à la racine
		 */
		public function AssetGroupDesc( pConfig : XML = null, pParent : AssetGroupDesc = null) {
			id		= pConfig ? getId( pConfig) : null;
			childs	= new Object();
			assets	= new Object();
			
			setConfig( pConfig, pParent);
		}
		
		/**
		 * on récupère un id de groupe dans une config xml de groupe
		 * @param	pConfig	node xml de config de groupe
		 * @return	id de groupe
		 */
		public static function getId( pConfig : XML) : String { return pConfig.id[ 0].toString();}
		
		/**
		 * on définie une config au groupe
		 * @param	pConfig	node xml de config du groupe
		 * @param	pParent	le groupe d'assets parent, ou null si à la racine
		 */
		public function setConfig( pConfig : XML, pParent : AssetGroupDesc) : void {
			sharedProperties	= new AssetsSharedProperties( pConfig);
			parent				= pParent;
			
			if( pParent) pParent.childs[ id] = this;
		}
		
		/**
		 * on recherche la transformation à appliquer aux assets membres de ce groupe ; si on trouve pas ici, on cherche dans le parent, et ainsi de suite
		 * @return	matrice de transformation ou null si rien de trouvé
		 */
		public function get trans() : Matrix {
			if( sharedProperties.trans) return sharedProperties.trans;
			else if( parent) return parent.trans;
			else return null;
		}
		
		/**
		 * on retourne le descripteur de fichier des assets de ce groupe ; si on ne trouve pas pour ce groupe, on cherche dans le parent, et ainsi de suite
		 * @return	descripteur de fichier, ou null si aucun de défini pour ce groupe ou ses parents
		 */
		public function get file() : MyFile {
			if( sharedProperties.file) return sharedProperties.file;
			else if( parent) return parent.file;
			else return null;
		}
		
		/**
		 * on retourne le descripteur de fichier des template d'assets de ce groupe ; si on ne trouve pas pour ce groupe, on cherche dans le parent, et ainsi de suite
		 * @return	descripteur de fichier de template, ou null si aucun de défini pour ce groupe ou ses parents
		 */
		public function get templateFile() : MyFile {
			if( sharedProperties.templateFile) return sharedProperties.templateFile;
			else if( parent) return parent.templateFile;
			else return null;
		}
		
		/**
		 * on recherche le nombre théorique d'instances à mettre en mémoire pour les membres de ce groupe ; si l'info n'est pas définie pour ce groupe, on cherche dans le groupe parent, et ainsi de suite
		 * @return	nombre théorique d'instances des assets à allouer en mémoire, ou -1 si pas défini pour ce groupe ou ses parents
		 */
		public function get instanceCount() : int {
			if( sharedProperties.instanceCount >= 0) return sharedProperties.instanceCount;
			else if( parent) return parent.instanceCount;
			else return -1;
		}
		
		/**
		 * retrouve l'état du verrou d'instance ; si pas déini dans ce groupe, on cherche dans les parents
		 * @return	nom d'état du verrou d'instance (voir constantes des AssetsSharedProperties)
		 */
		public function get lockInstance() : String {
			if( sharedProperties.lockInstance != AssetsSharedProperties.LOCKER_UNDEFINED) return sharedProperties.lockInstance;
			else if( parent) return parent.lockInstance;
			else return AssetsSharedProperties.LOCKER_UNDEFINED;
		}
		
		/**
		 * on recherche la valeur d'alpha des templates des assets de ce groupe ; si info pas définie, on cherche dans le parent, et ainsi de suite
		 * @return	valeur d'alpha (0..1) ou -1 si pas définie
		 */
		public function get templateAlpha() : Number {
			if( sharedProperties.templateAlpha >= 0) return sharedProperties.templateAlpha;
			else if( parent) return parent.templateAlpha;
			else return -1;
		}
		
		/** on récupère le tag de nom de mode de génération d'export défini dans l'imbrication de groupes
		 * @return	tag de mode de génération d'export, voir constantes AssetsSharedProperties::GEN_INTERNAL et AssetsSharedProperties::GEN_EXTERNAL null
		 */
		public function get generateMode() : String {
			if ( sharedProperties.generateMode) return sharedProperties.generateMode;
			else if ( parent) return parent.generateMode;
			else return null;
		}
		
		/**
		 * on cherche le type de rendu défini pour les membres de ce groupe
		 * @return	type de rendu de l'asset ; null si non défini
		 */
		public function get render() : AssetRender {
			if( sharedProperties.render) return sharedProperties.render;
			else if( parent) return parent.render;
			else return null;
		}
		
		/**
		 * on récupère une valeur définie en "datas" pour les membres de ce groupe et correspondant à la clef passée ; si info pas définie, on cherche dans le parent
		 * @param	pId		clef de la valeur cherchée dans les datas de cet asset
		 * @return	valeur correspondante, ou null si rien de défini
		 */
		public function getData( pId : String) : String {
			if( sharedProperties.datas[ pId]) return sharedProperties.datas[ pId];
			else if( parent) return parent.getData( pId);
			else return null;
		}
	}
}