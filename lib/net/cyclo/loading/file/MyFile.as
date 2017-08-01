package net.cyclo.loading.file {
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	
	import net.cyclo.shell.ApplicationDomainMgr;
	import net.cyclo.shell.MySystem;
	
	/**
	 * descripteur de fichier
	 * 
	 * @author	nico
	 */
	public class MyFile {
		/** tag de version pour forcer la non utilisation du paramètre anti-cache */
		public static const VERSION_CACHE		: String			= "CACHE";
		/** tag de version pour forcer l'utilisation du paramètre anti-cache */
		public static const VERSION_NO_CACHE	: String			= "NO-CACHE";
		
		/** nom de fichier, ou nom de tag de nom à résoudre avec MySystem::getTagFileName */
		protected var _name						: String;
		/** chemin se terminant par "/" vers le fichier, ou nom de tag de path à résoudre avec MySystem::getTagPath ; null si pas de chemin défini */
		protected var _path						: String;
		/** tag de version à ajouter à l'url de chargement pour forcer la mise à jour du cache ; null si pas défini */
		protected var _version					: String;
		/** tag de nom de domaine d'application spécifique à ce fichier ; laisser null pour utiliser par défaut Application.currentDomain */
		protected var _domain					: String;
		
		/**
		 * construction d'un descripteur de fichier
		 * @param	pName		nom du fichier
		 * @param	pPath		url, chemin se terminant par "/" vers le fichier ; laisser null si pas de chemin
		 * @param	pVersion	numéro de version pour forcer la mise à jour du cache ; laisser null si pas défini
		 * @param	pDomain		nom de domaine d'application spécifique ; laisser null pour utiliser par défaut ApplicationDomain.currentDomain
		 */
		public function MyFile( pName : String, pPath : String = null, pVersion : String = null, pDomain : String = null) {
			_name		= pName;
			_path		= pPath;
			_version	= pVersion;
			_domain		= pDomain;
		}
		
		/**
		 * on récupère le nom du fichier
		 * @return	nom de fichier ou tag de nom de fichier
		 */
		public function get name() : String { return _name;}
		
		/**
		 * on récupère le "vrai" nom de fichier, en vérifiant si il y a un tag de nom défini coorespondant à la propriété ::_name
		 * @return	"vrai" nom de fichier
		 */
		public function get realName() : String { return MySystem.getTagFileName( _name) != null ? MySystem.getTagFileName( _name) : _name; }
		
		/**
		 * on récupère l'url/chemin du fichier
		 * @return	chemin du fichier se terminant par "/" ou tag de chemin de fichier, ou null si aucun de défini
		 */
		public function get path() : String { return _path;}
		
		/**
		 * on récupère la version du fichier à charger pour forcer le cache à se mettre à jour
		 * @return	version ou null si pas défini
		 */
		public function get version() : String { return _version;}
		
		/**
		 * on récupère le tag identifiant du domaine d'application défini pour ce fichier
		 * @return	trag identifiant de domaine, ou null si rien de spécifique et on utilise par défaut ApplicationDomain.currentDomain
		 */
		public function get applicationDomainId() : String { return _domain;}
		
		/**
		 * on récupère le domaine d'application déduit de ce qui est défini dans cette instance ;
		 * si le domaine n'est pas défini (null), on retourne le ApplicationDomain.currentDomain ;
		 * si le domaine n'a pas encore été créé, on le crée 
		 * @return	ApplicationDomain correspondant à l'id de domaine défini pour ce descripteur de fichier swf
		 */
		public function get applicationDomain() : ApplicationDomain {
			if( _domain != null) return ApplicationDomainMgr.getInstance().createDomain( _domain);
			else return ApplicationDomain.currentDomain;
		}
		
		/**
		 * donne l'identifiant de fichier ; on se base uniquement sur le nom et son chemin
		 * @return	identifiant de fichier
		 */
		public function get id() : String { return ( _path != null ? _path + ":" : "") + _name;}
		
		/**
		 * chaine de trace du descripteur de fichier
		 * @return	chaîne de trace de descripteur de fichier
		 */
		public function toString() : String { return _name + ":" + _path + ":" + _version + ":" + _domain; }
		
		/**
		 * on vérifie si le fichier désigné est un fichier d'image en se basant sur son extension
		 * @return	true si fichier d'image (PNG/JPG/GIF), false sinon
		 */
		public function isIMG() : Boolean {
			var lExt	: String	= String( String( realName.split( "?")[ 0]).split( ".").pop()).toLowerCase();
			
			switch( lExt) {
				case "png":
				case "jpg":
				case "jpeg":
				case "gif":
					return true;
			}
			
			return false;
		}
	}
}