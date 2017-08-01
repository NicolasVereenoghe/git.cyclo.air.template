package net.cyclo.sound {
	import net.cyclo.loading.file.MyFile;
	
	/**
	 * descripteur de son
	 * @author	nico
	 */
	public class SndDesc {
		/** identifiant de son */
		protected var _id								: String							= null;
		/** taux du volume de base du son (0..1) */
		protected var _vol								: Number							= -1;
		/** nombre de répétinios de ce son à jouer quand on le lit */
		protected var _loops							: int								= -1;
		/** descripteur de fichier du son si celui-ci est externe */
		protected var _file								: MyFile							= null;
		/** mode de lecture par défaut utilisé par ce son */
		protected var _defaultPlayMode					: SndPlayMode						= null;
		
		/**
		 * construction de descripteur de son
		 * @param	pId					identifiant de son
		 * @param	pVol				taux du volume (0..1)
		 * @param	pLoops				nombre de répétition à jouer quand on lance une lecture de ce son
		 * @param	pFile				descripteur de fichier, ou null si aucun à fournir
		 * @param	pDefaultPlayMode	descripteur de mode de lecture par défaut du son ; laisser null pour une lecture simple
		 */
		public function SndDesc( pId : String, pVol : Number = 1, pLoops : int = 0, pFile : MyFile = null, pDefaultPlayMode : SndPlayMode = null) {
			_id					= pId;
			_vol				= pVol;
			_loops				= pLoops;
			_file				= pFile;
			_defaultPlayMode	= ( pDefaultPlayMode != null ? pDefaultPlayMode : new SndPlayMode());
			
			_defaultPlayMode.wrapDesc( this);
		}
		
		/**
		 * récupère l'id de son
		 * @return	id de son
		 */
		public function get id() : String { return _id; }
		
		/**
		 * on récupère un descripteur de fichier pour le son ; si aucun n'est défini, on en génère un par défaut en utilisant l'identifant comme url de son
		 * @return	descripteur de fichier du son
		 */
		public function get file() : MyFile {
			if ( _file != null) return _file;
			else return new MyFile( _id);
		}
		
		/**
		 * taux de volume par défaut de ce son
		 * @return	taux de volume (0..1)
		 */
		public function get vol() : Number { return _vol; }
		
		/**
		 * nombre de répétions par défaut de ce son quand on le lit
		 * @return	répétitions de son en lecture
		 */
		public function get loops() : Number { return _loops; }
		
		/**
		 * on récupère le mode de lecture par défaut de ce son
		 * @return	descripteur de mode de lecture du son
		 */
		public function get defaultPlayMode() : SndPlayMode { return _defaultPlayMode; }
	}
}