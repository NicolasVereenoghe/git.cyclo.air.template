package net.cyclo.assets {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	import net.cyclo.ui.ExtTimelineMovieClip;
	
	import net.cyclo.loading.CycloLoader;
	import net.cyclo.loading.CycloLoaderMgr;
	import net.cyclo.loading.file.MyFile;
	import net.cyclo.shell.ApplicationDomainMgr;
	import net.cyclo.shell.MySystem;
	
	/**
	 * gestionnaire de ressources graphiques
	 * 
	 * template de xml de config des assets :
	 * @code
	 *	<xml>
	 *		[<instance>NB_INSTANCES_EN_MEMOIRE_PAR_DEFAUT_POUR_TOUS</instance>]
	 * 		[<lock_instance/>|<unlock_instance/>]
	 *		[<file>
	 *			[<path>TAG_CHEMIN_FICHIER</path>]
	 *			[<version>TAG_DE_VERSION</version>]
	 *			[<domain>APPLICATION_DOMAIN</domain>]
	 *			<name>NOM_FICHIER_AVEC_EXTENSION_EXPLICITE</name>
	 *		</file>]
	 * 		[<file_template>
	 * 			[<path>TAG_CHEMIN_FICHIER</path>]
	 *			[<version>TAG_DE_VERSION</version>]
	 *			[<domain>APPLICATION_DOMAIN</domain>]
	 *			<name>NOM_FICHIER_AVEC_EXTENSION_EXPLICITE</name>
	 * 		</file_template>]
	 * 		[<template_alpha>0..1</template_alpha>]
	 *		[<{bitmap|vecto} [snap={"never"|"auto"|"always"}] [smooth={"false"|"true"}] [stabil={"false"|"true"}] [fixedQ={"false"|"true"}] [step="PAS_EN_NOMBRE_DE_FRAMES_DU_PARSING_BITMAP"] [parse_mode={"in-depth"|"in-length"}] [ignoreParseBmp={"true"|"false"}]>
	 * 			[<transform>
	 *				[<dx>CORRECTION_DE_CALAGE_EN_X_POUR_CREER_LES_BITMAPS</dx>]
	 *				[<dy>CORRECTION_DE_CALAGE_EN_Y_POUR_CREER_LES_BITMAPS</dy>]
	 *				[<scalex>CORRECTION_DE_SCALE_X_POUR_CREER_LES_BITMAPS</scalex>]
	 *				[<scaley>CORRECTION_DE_SCALE_Y_POUR_CREER_LES_BITMAPS</scaley>]
	 *				[<rotation>CORRECTION_DE_ROTATION_EN_DEG_POUR_CREER_LES_BITMAPS</rotation>]
	 *			</transform>]
	 * 		</{bitmap|vecto}>]
	 * 		[<{internal|external}/>]
	 *		[<transform>
	 *			[<dx>CORRECTION_DE_CALAGE_PAR_DEFAUT_EN_X</dx>]
	 *			[<dy>CORRECTION_DE_CALAGE_PAR_DEFAUT_EN_Y</dy>]
	 *			[<scalex>CORRECTION_DE_SCALE_X_PAR_DEFAUT</scalex>]
	 *			[<scaley>CORRECTION_DE_SCALE_Y_PAR_DEFAUT</scaley>]
	 *			[<rotation>CORRECTION_DE_ROTATION_EN_DEG_PAR_DEFAUT</rotation>]
	 *		</transform>]
	 * 		[<datas>
	 * 			[<data>
	 *				<id>CLEF</id>
	 * 				<value>VALEUR</value> 
	 * 			</data>
	 * 			[...]]
	 * 		</datas>]
	 *		[<vars>
	 *			[<var>
	 *				<id>ID_DE_VARIABLE_RECHERCHEE_DANS_LES_NODES_D_ASSETS</id>
	 *				<value>{[A..Z]|A}[,...]</value>
	 *			</var>
	 *			[...]]
	 *		</vars>]
	 *		[<groups>
	 *			<group>
	 *				<id>ID_GROUP</id>
	 *				[<instance>NB_INSTANCES_EN_MEMOIRE_PAR_DEFAUT_DU_GROUPE</instance>]
	 * 				[<lock_instance/>|<unlock_instance/>]
	 *				[<file>DEFINITION_ACCES_FICHIER</file>]
	 * 				[<file_template>DEFINITION_ACCES_FICHIER</file_template>]
	 * 				[<template_alpha>0..1</template_alpha>]
	 *				[<{bitmap|vecto}/>]
	 * 				[<{internal|external}/>]
	 *				[<transform>DEFINITION_DE_CORRECTION_DE_CALAGE_POUR_GROUPE</transform>]
	 * 				[<datas>DEFINITION_DE_DATAS_POUR_GROUPE</datas>]
	 *				[<assets>
	 *					<asset>
	 *						<id>ID_INTERNE_AU_CODE</id>
	 *						[<export>ID_D_EXPORT_DANS_FLA</export>]
	 *						[<instance>NB_INSTANCES_EN_MEMOIRE</instance>]
	 * 						[<lock_instance/>|<unlock_instance/>]
	 *						[<file>DEFINITION_ACCES_FICHIER</file>]
	 * 						[<file_template>DEFINITION_ACCES_FICHIER</file_template>]
	 * 						[<export_template>ID_D_EXPORT_DANS_FLA</export_template>]
	 * 						[<template_alpha>0..1</template_alpha>]
	 *						[<{bitmap|vecto}/>]
	 * 						[<{internal|external}/>]
	 *						[<transform>DEFINITION_DE_CORRECTION_DE_CALAGE</transform>]
	 * 						[<datas>DEFINITION_DE_DATAS_POUR_CET_ASSET</datas>]
	 * 						[<index>ORDRE_DE_GENERATION</index>]
	 *						[<add_groups>
	 *							[<add_group>ID_GROUP_ADDITIONNEL_OU_TAG_AUTRE</add_group>
	 *							[...]]
	 *						</add_groups>]
	 *					</asset>
	 *					[...]
	 *				</assets>]
	 *				[<groups>DEFINITION_DE_GROUPS_IMBRIQUES</groups>]
	 *			</group>
	 *			[...]
	 *		</groups>]
	 *		[<assets>DEFINITION_D_ASSETS_SANS_UTILISER_D_IMBRICATION_DE_GROUPE</assets>]
	 *	</xml>
	 * @endcode
	 * 
	 * @author	nico
	 */
	public class AssetsMgr {
		/** label de l'instance vide */
		public static const VOID_ASSET			: String					= "asset_vide";
		
		/** réf sur le singleton */
		protected static var current			: AssetsMgr;
		
		/** propriétés patagées de l'ensemble des assets */
		public var sharedProperties				: AssetsSharedProperties;
		
		/** descripteur de l'asset vide (utilisé pour un semblant de services d'assets, tout en ayant un état vide) */
		protected var voidAsset					: AssetDescVoid;
		
		/** map de descripteurs d'assets (AssetDesc), indexée par id d'asset */
		protected var assets					: Object;
		/** map de descripteurs de variables d'assets (AssetVarDesc), indexée par id de variable ; uniquement utilisées lors du parsing de xml pour construire la map d'assets */
		protected var vars						: Object;
		/** map de descripteurs de groupes d'assets (AssetGroupDesc), indexée par id de groupe */
		protected var groups					: Object;
		
		/** réf sur l'instance qui reçoit les notifications de progression et de fin de traitement d'allocation mémoire */
		protected var notifyMallocAssets		: INotifyMallocAssets;
		/** une pile d'assets (AssetDesc) en cours de traitement d'allocation mémoire ; null si pas d'allocation en cours */
		protected var mallocStack				: Array;
		/** itérateur de frame de traitement d'allocation mémoire des assets ; null si pas d'allocation en cours */
		protected var mallocIterator			: Sprite;
		/** nombre total d'assets à traiter au début de l'allocation mémoire */
		protected var mallocNbAssets			: int;
		
		/** temps en ms maximum qui peut s'écouler pendant une iteration d'allocation avant d'attendre l'iteration suivante. Plus la valeur élevée, plus le loading est rapide, mais moins l'affichage devient fluide */
		protected var mallocLimitTime			: int						= 500;
		
		/** réf vers l'interface de génération d'export externe, null si pas utilisé */
		protected var externalExportGenerator	: IExternalExportGenerator	= null;
		
		/**
		 * constructeur : on ne crée pas le singleton ici, juste une nouvelle instance indépendante
		 * @param	pConfig				xml de config des assets
		 * @param	pExternalExportGen	interface de génération d'export d'assets, null si pas utilisée
		 */
		public function AssetsMgr( pConfig : XML, pExternalExportGen : IExternalExportGenerator = null) {
			groups					= new Object();
			assets					= new Object();
			voidAsset				= new AssetDescVoid( null, null, this);
			externalExportGenerator	= pExternalExportGen;
			
			parseGlobal( pConfig);
			parseGroups( pConfig);
			
			voidAsset.malloc();
			
			ExtTimelineMovieClip;
			AutoInstance;
		}
		
		/**
		 * instanciateur et getter d'instance de singleton de gestionnaire d'assets
		 * @param	pConfig				xml de config des assets, à spécifier si il n'y a pas encore d'instance, sinon ignoré
		 * @param	pExternalExportGen	interface de génération d'export d'assets, null si pas utilisée
		 * @return	le singleton si il existe, ou une nouvelle qui devient le singleton si pas encore instancié
		 */
		public static function getInstance( pConfig : XML = null, pExternalExportGen : IExternalExportGenerator = null) : AssetsMgr {
			if( ! current) current = new AssetsMgr( pConfig, pExternalExportGen);
			
			return current;
		}
		
		/**
		 * on récupère une instance allouée en mémoire d'un asset
		 * 
		 * attention, on suppose que le fichier de ressource de cet asset a été chargé (loadAssets), et que la mémoire a bien été allouée pour cet asset (mallocAssets)
		 * 
		 * @param	pId		identifiant d'asset
		 * @return	instance d'asset
		 */
		public function getAssetInstance( pId : String) : AssetInstance {
			if( pId != VOID_ASSET) return assets[ pId].getAssetInstance();
			else return voidAsset.getAssetInstance();
		}
		
		/**
		 * on récupère un descripteur de variable d'assets
		 * @param	pId		identifiant de descripteur de variable
		 * @return	le descripteur de variable avec son pool de valeurs
		 */
		public function getVar( pId : String) : AssetVarDesc { return vars[ pId];}
		
		/**
		 * on récupère un descripteur d'asset à partir de son id
		 * @param	pId	id d'asset
		 * @return	descripteur d'asset correspondant
		 */
		public function getAssetDescById( pId : String) : AssetDesc { return AssetDesc( assets[ pId]);}
		
		/**
		 * on récupère une liste de descripteur d'assets correspondant aux patterns de recherche spécifiés
		 * 
		 * attention, ce n'est pas un getter optimisé, on parse tous les assets pour trouver toutes les correspondances possibles
		 * 
		 * @param	pPatterns	liste variable de patterns (PatternAsset) pour désigner un ensemble de patterns à rechercher ; on peut aussi passer des Array de PatternAsset ; on doit au moins préciser un critère de recherche, sinon aucun résultat 
		 * @return	liste de descripteurs d'assets
		 */
		public function getAssetDescs( ... pPatterns) : Array {
			var lRes		: Array		= new Array();
			var lControl	: Object	= new Object();
			var lI			: int;
			var lJ			: int;
			var lId			: String;
			
			for( lI = 0 ; lI < pPatterns.length ; lI++){
				if( pPatterns[ lI] is Array){
					for( lJ = 0 ; lJ < pPatterns[ lI].length ; lJ++){
						for( lId in assets){
							if( ( ! lControl[ lId]) && PatternAsset( pPatterns[ lI][ lJ]).match( AssetDesc( assets[ lId]))){
								lRes.push( assets[ lId]);
								lControl[ lId] = true;
							}
						}
					}
				}else{
					for( lId in assets){
						if( ( ! lControl[ lId]) && PatternAsset( pPatterns[ lI]).match( AssetDesc( assets[ lId]))){
							lRes.push( assets[ lId]);
							lControl[ lId] = true;
						}
					}
				}
			}
			
			return lRes;
		}
		
		/**
		 * on demande le chargement de fichiers d'assets (loading)
		 * 
		 * à la suite d'une demande de chargement de fichier d'assets (une fois finie), on s'attend à avoir une demande d'allocation mémoire
		 * de ces assets, au moins pour les marquer comme étant en cours d'utilisation même si on n'utilise aucune instance préchargée
		 * (par exemple une config de nombre d'instances à 0 pour des assets)
		 * 
		 * @param	pLoader		le loader à utiliser pour effectuer les chargement (on laisse le soin d'y coller des listener à l'extérieur)
		 * @param	pPatterns	liste variable de patterns (PatternAsset) pour désigner un ensemble de patterns à rechercher ; on peut aussi passer des Array de PatternAsset ; pour désigner TOUS les assets, ne rien préciser ici
		 * @return	le loader qu'on a passé en paramètres et auquel on vient d'ajouter les fichiers à charger. Il faut encore lui demander explicitement de faire le chargement. On le retourne juste pour que ce soit pratique :)
		 */
		public function loadAssets( pLoader : CycloLoader, ... pPatterns) : CycloLoader {
			var lLoadControl	: Object	= new Object();
			var lI				: int;
			var lJ				: int;
			
			if( pPatterns.length > 0){
				for( lI = 0 ; lI < pPatterns.length ; lI++){
					if( pPatterns[ lI] is Array){
						for( lJ = 0 ; lJ < pPatterns[ lI].length ; lJ++) loadPatternAsset( pLoader, pPatterns[ lI][ lJ], lLoadControl);
					}else loadPatternAsset( pLoader, pPatterns[ lI], lLoadControl);
				}
			}else loadPatternAsset( pLoader, null, lLoadControl);
			
			return pLoader;
		}
		
		/**
		 * on décharge les fichiers d'assets et on libère leur domaine d'application ; le ApplicationDomain.currentDomain est ignoré
		 * 
		 * attention, on suppose que les assets dont on cherche à décharger les fichiers associés ont été préalablement libérés.
		 * attention, cette méthode ne libère que les fichiers dont on est sûr qu'aucun asset en cours ne dépend : si d'autres assets
		 * que ceux spécifiés en pattern de recherche sont toujours alloués en mémoire, et qu'ils partagent des fichiers de ressources,
		 * alors ces fichiers de ressources communs ne seront pas déchargés.
		 * attention, risque de foirage si il y a des ressources externes à cette instance d'AssetMgr qui dépendent de fichiers qu'on va décharger.
		 * pour résoudre ce soucis de dépendances externes, on peut spécifier des listes de LoadingFile et de domaines à ignorer.
		 * 
		 * @param	pIgnoreFile	map de LoadingFile à ignorer lors de la décharge de fichiers ; indexée par chaîne identifiante de MyFile (MyFile::id) ; null si pas de liste
		 * @param	pIgnoreDom	map d'id de domaine d'application à ignorer lors de la décharge (en plus de ceux éventuellement définis dans les LoadingFile de la map pIgnoreFile) ; indexée par id de domaine ; le ApplicationDomain.currentDomain n'a pas à y figurer (pas d'id particulier), et il est de toute façon ignoré ; null si pas de liste
		 * @param	pPatterns	liste variable de patterns (PatternAsset) pour désigner un ensemble de patterns à rechercher ; on peut aussi passer des Array de PatternAsset ; pour désigner TOUS les assets, ne rien préciser ici
		 */
		public function unloadAssets( pIgnoreFile : Object, pIgnoreDom : Object, ... pPatterns) : void {
			var lId		: String;
			var lAsset	: AssetDesc;
			var lFile	: MyFile;
			var lI		: int;
			var lJ		: int;
			
			if( ! pIgnoreDom) pIgnoreDom = new Object();
			if( ! pIgnoreFile) pIgnoreFile = new Object();
			
			for( lId in pIgnoreFile){
				lFile = pIgnoreFile[ lId];
				
				if( lFile.applicationDomainId) pIgnoreDom[ lFile.applicationDomainId] = lFile.applicationDomainId;
			}
			
			for( lId in assets){
				lAsset = assets[ lId];
				
				if ( lAsset.isMalloc()) {
					lFile = lAsset.file;
					if( lFile != null){
						pIgnoreFile[ lFile.id]	= lFile;
						
						if ( lFile.applicationDomainId) pIgnoreDom[ lFile.applicationDomainId] = lFile.applicationDomainId;
					}
				}
			}
			
			if( pPatterns.length > 0){
				for( lI = 0 ; lI < pPatterns.length ; lI++){
					if( pPatterns[ lI] is Array){
						for( lJ = 0 ; lJ < pPatterns[ lI].length ; lJ++) unloadPatternAsset( pPatterns[ lI][ lJ], pIgnoreFile, pIgnoreDom);
					}else unloadPatternAsset( pPatterns[ lI], pIgnoreFile, pIgnoreDom);
				}
			}else unloadPatternAsset( null, pIgnoreFile, pIgnoreDom);
			
			MySystem.gc();
		}
		
		/**
		 * on effectue le préchargement en mémoire des instances d'assets
		 * 
		 * attention, ne pas faire plusieurs allocations en même temps
		 * on suppose que les fichiers d'assets correspondant ont été loadés
		 * 
		 * @param	pNotifyMalloc	instance qui reçoit les notifications de progression du préchargement en mémoire des instances d'assets ; null si pas de notification => on alloue tout en une seule itération !
		 * @param	pPatterns		liste variable de patterns (PatternAsset) pour désigner un ensemble de patterns à rechercher ; on peut aussi passer des Array de PatternAsset ; pour désigner TOUS les assets, ne rien préciser ici
		 */
		public function mallocAssets( pNotifyMalloc : INotifyMallocAssets, ... pPatterns) : void {
			var lMallocControl	: Object	= new Object();
			var lI				: int;
			var lJ				: int;
			
			notifyMallocAssets	= pNotifyMalloc;
			mallocStack			= new Array();
			
			if( pPatterns.length > 0){
				for( lI = 0 ; lI < pPatterns.length ; lI++){
					if( pPatterns[ lI] is Array){
						for( lJ = 0 ; lJ < pPatterns[ lI].length ; lJ++) mallocPatternAsset( pPatterns[ lI][ lJ], lMallocControl);
					}else mallocPatternAsset( pPatterns[ lI], lMallocControl);
				}
			}else mallocPatternAsset( null, lMallocControl);
			
			mallocStack.sort( cmpAssetDescIndex);
			
			if( pNotifyMalloc){
				mallocNbAssets	= mallocStack.length;
				mallocIterator	= new Sprite();
				mallocIterator.addEventListener( Event.ENTER_FRAME, onMallocIteration);
			}else{
				while( mallocStack.length > 0){
					if( AssetDesc( mallocStack[ 0]).malloc()) mallocStack.shift();
				}
				
				mallocStack = null;
			}
		}
		
		/**
		 * on libère la mémoire occupée par les instances d'assets préchargés
		 * 
		 * attention, on suppose que les instances d'assets utilisées ont été libérées et remises en mémoire
		 * 
		 * @param	pPatterns		liste variable de patterns (PatternAsset) pour désigner un ensemble de patterns à rechercher ; on peut aussi passer des Array de PatternAsset ; pour désigner TOUS les assets, ne rien préciser ici
		 */
		public function freeAssets( ... pPatterns) : void {
			var lI		: int;
			var lJ		: int;
			
			if( pPatterns.length > 0){
				for( lI = 0 ; lI < pPatterns.length ; lI++){
					if( pPatterns[ lI] is Array){
						for( lJ = 0 ; lJ < pPatterns[ lI].length ; lJ++) freePatternAsset( pPatterns[ lI][ lJ]);
					}else freePatternAsset( pPatterns[ lI]);
				}
			}else freePatternAsset( null);
			
			MySystem.gc();
		}
		 
		/**
		 * on ajoute un groupe "muet", c'est à dire qu'il n'a comme propriété qu'un nom ; on vérifie si il n'existe pas déjà une définition pour ce groupe, dans ce cas on ne le crée pas à nouveau
		 * 
		 * méthode uniquement utilisée lors du parsing de la config
		 * 
		 * @param	pId		id de groupe
		 * @return	ref sur le groupe "muet" créé, ou sur le groupe existant qui a le même id
		 */
		public function addGroup( pId : String) : AssetGroupDesc {
			var lGroup : AssetGroupDesc;
			
			if( groups[ pId]) return groups[ pId];
			else{
				lGroup			= new AssetGroupDesc();
				lGroup.id		= pId;
				groups[ pId]	= lGroup;
				
				return lGroup;
			}
		}
		
		/**
		 * on ajoute un descripteur d'asset
		 * @param	pADesc	descripteur d'asset à ajouter
		 * @param	pGDesc	descripteur de groupe auquel l'asset appartient, ou null si non spécifié
		 */
		public function addAsset( pADesc : AssetDesc) : void { assets[ pADesc.id] = pADesc; }
		
		/**
		 * le gestionnaire d'assets fait appel à son interface externe IAssetExportGenerator pour générer un export d'asset
		 * @param	pExport		nom d'export de l'asset ; ce nom permet d'identifier l'export à générer
		 * @return	export graphique généré, ou null si rien à générer
		 */
		public function generateExternalExport( pExport : String) : DisplayObject {
			if ( externalExportGenerator != null) return externalExportGenerator.generateExport( pExport);
			else return null;
		}
		
		/**
		 * on compare l'ordre de malloc de 2 descripteurs d'asset
		 * @param	pA	descripteur A
		 * @param	pB	descripteur B
		 * @return	< 0 si A précède B, 0 si A et B même ordre, > 0 si B précède A
		 */
		protected function cmpAssetDescIndex( pA : AssetDesc, pB : AssetDesc) : int {
			if ( pA.index < pB.index) return -1;
			else if ( pA.index == pB.index) return 0;
			else return 1;
		}
		
		/**
		 * méthode d'itération de l'allocation mémoire
		 * 
		 * alloue des assets jusqu'à ce que le temps écoulé dépasse mallocLimitTime, dans ce cas on attend le prochain ENTER_FRAME pour poursuivre les allocations, pour ne pas figer le jeu.
		 * 
		 * @param	pE	évènement d'itération de frame
		 */
		protected function onMallocIteration( pE : Event) : void {
			var lNotify : INotifyMallocAssets = notifyMallocAssets;
			var lStartTime : Number = getTimer();
			
			do{
				lNotify.onMallocAssetsProgress( mallocNbAssets - mallocStack.length, mallocNbAssets);
				
				if( mallocStack.length == 0){
					mallocIterator.removeEventListener( Event.ENTER_FRAME, onMallocIteration);
					mallocIterator		= null;
					mallocStack			= null;
					notifyMallocAssets	= null;
					lNotify.onMallocAssetsEnd();
					break;
				}else{
					if ( AssetDesc( mallocStack[ 0]).malloc()) mallocStack.shift();
					else break;
				}
			}while( getTimer() - lStartTime < mallocLimitTime);
		}
		
		/**
		 * on empile les assets correspondant à un pattern de recherche dans la pile de traitement d'allocation mémoire
		 * 
		 * @param	pPattern	pattern de recherche d'assets, ou null pour tout prendre
		 * @param	pControl	map d'assets déjà empilés, indexée par id d'assets
		 */
		protected function mallocPatternAsset( pPattern : PatternAsset, pControl : Object) : void {
			var lI		: String;
			var lAsset	: AssetDesc;
			
			for( lI in assets){
				lAsset = assets[ lI];
				
				if( ( ! pControl[ lI]) && ( ( ! pPattern) || pPattern.match( lAsset))){
					pControl[ lI] = lAsset;
					mallocStack.push( lAsset);
				}
			}
		}
		
		/**
		 * on libère la mémoire occupée par les instances d'assets désignées par un pattern de recherche d'assets
		 * @param	pPattern	pattern de recherche d'assets, ou null pour tout prendre
		 */
		protected function freePatternAsset( pPattern : PatternAsset) : void {
			var lFile	: MyFile;
			var lI		: String;
			var lAsset	: AssetDesc;
			
			for( lI in assets){
				lAsset = assets[ lI];
				
				if ( ( ! pPattern) || pPattern.match( lAsset)) {
					lAsset.free();
				}
			}
		}
		
		/**
		 * on empile dans un loader les assets qui correspondent au pattern de recherche d'assets
		 * 
		 * @param	pLoader			le loader dans lequel on empile les assets trouvés
		 * @param	pPattern		pattern de recherche d'assets, ou null pour tout prendre
		 * @param	pLoadControl	map de LoadingFile (indexée par id de File - File::id) qu'on a déjà empilé
		 */
		protected function loadPatternAsset( pLoader : CycloLoader, pPattern : PatternAsset, pLoadControl : Object) : void {
			var lI		: String;
			var lAsset	: AssetDesc;
			var lFile	: MyFile;
			
			for( lI in assets){
				lAsset = assets[ lI];
				
				if( ( ! pPattern) || pPattern.match( lAsset)){
					lFile = lAsset.file;
					if( lFile && ! pLoadControl[ lFile.id]){
						pLoadControl[ lFile.id] = lFile;
						pLoader.addDisplayFile( lFile);
					}
					
					lFile = lAsset.templateFile;
					if( lFile && ! pLoadControl[ lFile.id]){
						pLoadControl[ lFile.id] = lFile;
						pLoader.addDisplayFile( lFile);
					}
				}
			}
		}
		
		/**
		 * on décharge les fichiers des assets correspondant au pattern de recherche spécifié, et on libère leur domaine
		 * 
		 * on ne va effectivement décharger que les fichiers et libérer les domaines des assets rencontrés qui ne sont plus alloués
		 * en mémoire (pas marqués comme "actifs" : voir AssetDesc::isMalloc)
		 * 
		 * @param	pPattern		pattern de recherche d'assets, ou null pour tout prendre
		 * @param	pControlFile	liste d'exclusion ou de fichier déjà traité (LoadingFile) indexée par id de MyFile (MyFile::id)
		 * @param	pControlDom		liste d'exclusion ou de domaines (id de domaines) déjà traités, indexée par id de domaine
		 */
		protected function unloadPatternAsset( pPattern : PatternAsset, pControlFile : Object, pControlDom : Object) : void {
			var lI		: String;
			var lAsset	: AssetDesc;
			var lFile	: MyFile;
			
			for( lI in assets){
				lAsset = assets[ lI];
				
				if( ( ! lAsset.isMalloc()) && ( ( ! pPattern) || pPattern.match( lAsset))){
					lFile = lAsset.file;
					
					if( lFile != null){
						if( ! pControlFile[ lFile.id]){
							pControlFile[ lFile.id] = lFile;
							
							CycloLoaderMgr.getInstance().freeLoadedFileMem( lFile);
						}
						
						if( lFile.applicationDomainId && ! pControlDom[ lFile.applicationDomainId]){
							pControlDom[ lFile.applicationDomainId] = lFile.applicationDomainId;
							
							ApplicationDomainMgr.getInstance().destroyDomain( lFile.applicationDomainId);
						}
					}
				}
			}
			
			MySystem.gc();
		}
		
		/**
		 * parsing d'un node de config à la recherche d'un node <assets> pour ajouter de nouveaux assets
		 * @param	pConfig	node de config pouvant contenir un node <assets>
		 * @param	pParent	groupe parent de ce node de config, null si à la racine
		 */
		protected function parseAssets( pConfig : XML, pParent : AssetGroupDesc = null) : void {
			var lAssets : XMLList = pConfig.assets.asset;
			var lI		: int;
			var lIPool	: int;
			var lLPool	: int;
			var lAsset	: XML;
			var lPool	: VarPool;
			var lAssetD	: AssetDesc;
			
			for( lI = 0 ; lI < lAssets.length() ; lI++){
				lAsset	= lAssets[ lI];
				lPool	= getVarPool( lAsset);
				lLPool	= lPool.length;
				
				for( lIPool = 0 ; lIPool < lLPool ; lIPool++){
					lAssetD				= new AssetDesc( lPool.substituteVars( lAsset, lIPool), pParent, this);
					assets[ lAssetD.id]	= lAssetD;
				}
			}
		}
		
		/**
		 * parsing des groupes d'assets
		 * @param	pConfig	xml de config des assets
		 * @param	pParent	groupe parent de ce groupe, null si à la racine
		 */
		protected function parseGroups( pConfig : XML, pParent : AssetGroupDesc = null) : void {
			var lGroups	: XMLList = pConfig.groups.group;
			var lGroup	: XML;
			var lAGroup	: AssetGroupDesc;
			var lI		: int;
			
			parseAssets( pConfig, pParent);
			
			for( lI = 0 ; lI < lGroups.length() ; lI++){
				lGroup				= lGroups[ lI];
				lAGroup				= new AssetGroupDesc( lGroup, pParent);
				
				if( groups[ AssetGroupDesc.getId( lGroup)]){
					lAGroup = groups[ AssetGroupDesc.getId( lGroup)];
					lAGroup.setConfig( lGroup, pParent);
				}else{
					lAGroup = new AssetGroupDesc( lGroup, pParent);
					groups[ lAGroup.id] = lAGroup;
				}
				
				parseGroups( lGroup, lAGroup);
			}
		}
		
		/**
		 * parsing des settings globales des assets, et attribution des valeurs par défaut
		 * @param	pConfig	xml de config des assets
		 */
		protected function parseGlobal( pConfig : XML) : void {
			sharedProperties = new AssetsSharedProperties( pConfig);
			
			if( ! sharedProperties.render) sharedProperties.render = new AssetRender( AssetRender.RENDER_VECTO);
			if( sharedProperties.instanceCount < 0) sharedProperties.instanceCount = 1;
			if( sharedProperties.templateAlpha < 0) sharedProperties.templateAlpha = 0;
			if ( sharedProperties.lockInstance == AssetsSharedProperties.LOCKER_UNDEFINED) sharedProperties.lockInstance = AssetsSharedProperties.LOCKER_UNLOCKED;
			if ( ! sharedProperties.generateMode) sharedProperties.generateMode = AssetsSharedProperties.GEN_INTERNAL;
			
			buildVars( pConfig);
		}
		
		/**
		 * construction de map de variables d'assets
		 * @param	pConfig	xml de config des assets
		 */
		protected function buildVars( pConfig : XML) : void {
			var lVars	: XMLList		= pConfig.vars.child( "var");
			var lVar	: AssetVarDesc;
			var lI		: int;
			
			vars = new Object();
			
			for( lI = 0 ; lI < lVars.length() ; lI++){
				lVar = new AssetVarDesc( lVars[ lI]);
				
				vars[ lVar.id] = lVar;
			}
		}
		
		/**
		 * retourne un pool de variables utilisées dans un node xml
		 * @param	pNode	node xml dans lequel on recherche un pool de variables
		 * @return	pool de valeurs des variables trouvées
		 */
		protected function getVarPool( pNode : XML) : VarPool {
			var lStr	: String	= pNode.toString();
			var lPool	: VarPool	= new VarPool();
			var lId		: String;
			
			for( lId in vars){
				if( lStr.indexOf( lId) >= 0) lPool.addVar( AssetVarDesc( vars[ lId]));
			}
			
			return lPool;
		}
	}
}