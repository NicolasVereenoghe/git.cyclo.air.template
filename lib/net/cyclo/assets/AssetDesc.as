package net.cyclo.assets {
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	import net.cyclo.shell.MySystem;
	
	import net.cyclo.bitmap.BitmapMovieClip;
	import net.cyclo.bitmap.BitmapMovieClipMgr;
	import net.cyclo.bitmap.INotifyBitmapGenerate;
	import net.cyclo.loading.CycloLoaderMgr;
	import net.cyclo.loading.file.MyFile;
	
	/**
	 * descripteur d'un asset
	 * 
	 * @author	nico
	 */
	public class AssetDesc implements INotifyBitmapGenerate {
		/** nom d'export réservé aux assets dont la ressource graphique se trouve driect la time line de son fichier swf */
		public static const EXPORT_TIMELINE	: String					= "TIMELINE";
		
		/** identifiant d'asset */
		public var id						: String;
		/** identifiant d'export de la ressource graphique associée ; null si non défini */
		public var export					: String;
		/** identifiant d'export du template de la ressource graphique, ou null si pas de template */
		public var exportTemplate			: String;
		/** note d'ordre de génération, 0 si non défini */
		public var index					: int;
		
		/** propriétés partagées de cet asset */
		public var sharedProperties			: AssetsSharedProperties;
		
		/** map de groupes (AssetGroupDesc) indexée par id de groupe, auxquels cet asset est enregistré */
		public var groups					: Object;
		
		/** map de comptes d'utilisation de bitmaps dans tous les assets ; chaque compte est identifié par son id de bitmap */
		protected static var bmpCount		: Object;
		/** map de bitmaps utilisées dans l'asset décrit par cette instance de descripteur ; à chaque id de bitmap, on y fait correspondre true pour marquer l'utilisation (sinon le champ est viré/non défini) ; on ne compte pas le nombre ici, juste l'utilisation */
		protected var usedBmp				: Object;
		
		/** compteur d'instances actives */
		protected var _activeCtr			: int;
		
		/** gestionnaire d'assets associé à cet asset */
		protected var mgr					: AssetsMgr;
		
		/** pile d'instances d'assets disponibles */
		protected var freeInstances			: Array;
		/** liste d'instances d'assets utilisés et qui seront restituées en mémoire après utilisation (demande de restitution à la charge de l'utilisateur) ; si le verrou d'instance est défini pour cet asset, on ne garde pas dans cette liste les instances supplémentaires */
		protected var usedInstances			: Dictionary;
		
		/** pile d'instances de BitmapMovieClip en cours de traitement de génération bitmap asynchrome */
		protected var asyncGenBmps			: Array;
		
		/** loader de duplication d'asset de time line ; null si aucune duplication en cours */
		protected var timelineLoader		: Loader					= null;
		/** pile de loaders de duplication de timeline ; temporisés en vue de libérer la mémoire ; null si pas utilisé */
		protected var timelineLoaders		: Array						= null;
		
		
		/**
		 * constructeur
		 * @param	pConf	node xml de config de l'asset ; si null, le descripteur n'est pas initialisé !
		 * @param	pParent	le groupe parent de cet asset, ou null si pas de parent
		 * @param	pMgr	ref sur gestionnaire d'assets
		 */
		public function AssetDesc( pConf : XML, pParent : AssetGroupDesc, pMgr : AssetsMgr) {
			var lGroups	: XMLList;
			var lGroup	: AssetGroupDesc;
			var lI		: int;
			
			asyncGenBmps	= new Array();
			mgr				= pMgr;
			_activeCtr		= 0;
			
			if( pConf){
				lGroups				= pConf.add_groups.add_group;
				id					= pConf.id[ 0].toString();
				export				= pConf.export[ 0] ? pConf.export[ 0].toString() : null;
				exportTemplate		= pConf.export_template[ 0] ? pConf.export_template[ 0].toString() : null;
				index				= pConf.index[ 0] ? parseInt( pConf.index[ 0]) : 0;
				sharedProperties	= new AssetsSharedProperties( pConf);
				groups				= new Object();
				
				if( pParent){
					pParent.assets[ id] = this;
					groups[ pParent.id] = pParent;
				}
				
				for( lI = 0 ; lI < lGroups.length() ; lI++){
					lGroup = pMgr.addGroup( lGroups[ lI].toString());
					lGroup.assets[ id] = this;
					groups[ lGroup.id] = lGroup;
				}
			}
		}
		
		/**
		 * on récupère une instance parmi celles disponibles et on la marque comme utilisée ; si plus d'instance disponible, on en crée une nouvelle (pas optimisé)
		 * @return	instance d'asset à utiliser
		 */
		public function getAssetInstance() : AssetInstance {
			var lAssetI : AssetInstance;
			
			_activeCtr++;
			
			if( freeInstances.length > 0){
				lAssetI 				= freeInstances.pop();
				usedInstances[ lAssetI]	= lAssetI;
				
				return lAssetI;
			}else{
				lAssetI = generateInstance();
				
				if( lockInstance != AssetsSharedProperties.LOCKER_LOCKED){
					usedInstances[ lAssetI] = lAssetI;
					
					//trace( "WARNING : AssetDesc::getAssetInstance : création d'une instance supplémentaire de " + id + ", ce qui porte le compte à " + instanceEffectiveCount);
				}
				
				return lAssetI;
			}
		}
		
		/**
		 * on libère une asset d'instance utilisée ; elle devient à nouveau disponible et utilisable ; on la garde en mémoire
		 * 
		 * attention, il appartient à l'appelant de dégager son instance de la scène, et de la réinitialiser ("comme on fait son lit on se couche" ;))
		 * pour qu'à sa prochaine utilisation elle soit dans un état exploitable ; pas de dépendance ici avec la structure interne des assets,
		 * c'est à la charge de l'utilisateur !
		 * 
		 * @param	pAssetI	instance d'asset à remettre en mémoire
		 */
		public function freeAssetInstance( pAssetI : AssetInstance) : void {
			_activeCtr--;
			
			if ( usedInstances[ pAssetI]) {
				usedInstances[ pAssetI] = null;
				delete usedInstances[ pAssetI];
				
				freeInstances.push( pAssetI);
			}
		}
		
		/**
		 * on retourne la transformation à appliquer à cet asset, en cherchant dans sa config, puis dans celle des groupes et enfin en global si on ne trouve pas
		 * @return	matrice de transformation à appliquer à l'asset, ou null si aucune transformation
		 */
		public function get trans() : Matrix {
			var lI		: String;
			var lTrans	: Matrix;
			
			if( sharedProperties.trans) return sharedProperties.trans;
			else{
				for( lI in groups){
					lTrans = groups[ lI].trans;
					
					if( lTrans) return lTrans;
				}
			}
			
			return mgr.sharedProperties.trans;
		}
		
		/**
		 * on retourne le descripteur de fichier associé à cet asset ; on commence par rechercher dans la config de l'asset, puis dans ses groupes, et enfin si toujours rien de trouvé, on prend la config globale
		 * @return	descripteur de fichier ; normalement, on doit forcément trouver une référence !
		 */
		public function get file() : MyFile {
			var lI		: String;
			var lFile	: MyFile;
			
			if( sharedProperties.file) return sharedProperties.file;
			else{
				for( lI in groups){
					lFile = groups[ lI].file;
					
					if( lFile) return lFile;
				}
			}
			
			return mgr.sharedProperties.file;
		}
		
		/**
		 * on retourne le descripteur de fichier associé au template de cet asset ; recherche d'abords dans config d'asset, puis dans groupes, et enfin dans config globale si rien trouvé
		 * @return	descripteur de fichier de template ; on doit forcément trouver une référence si un id d'export de template a été défini
		 */
		public function get templateFile() : MyFile {
			var lI		: String;
			var lFile	: MyFile;
			
			if( sharedProperties.templateFile) return sharedProperties.templateFile;
			else{
				for( lI in groups){
					lFile = groups[ lI].templateFile;
					
					if( lFile) return lFile;
				}
			}
			
			return mgr.sharedProperties.templateFile;
		}
		
		/**
		 * le nombre d'instances actives
		 * @return	nombre d'instances actives
		 */
		public function get activeCtr() : int { return _activeCtr; }
		
		/**
		 * on retrouve le nombre théorique d'instances définies pour cet asset en fonction de la config initiale ; si rien de défini dans l'assets, on regarde dans ses groupes, et enfin dans la config globale si on n'a toujours rien trouvé
		 * 
		 * attention, il s'agit d'un nombre théorique, ce n'est pas forcément effectif
		 * (si pendant le jeu on a eu besoin de plus d'instances, alors ce nombre "théorique" diffère du "effectif")
		 * 
		 * @return	nombre théorique d'instance à allouer ; c'est ce compte d'instances qui sera alloué initialement lors de l'allocation
		 */
		public function get instanceCount() : int {
			var lI		: String;
			var lCount	: int;
			
			if( sharedProperties.instanceCount >= 0) return sharedProperties.instanceCount;
			else{
				for( lI in groups){
					lCount = groups[ lI].instanceCount;
					
					if( lCount >= 0) return lCount;
				}
			}
			
			return mgr.sharedProperties.instanceCount;
		}
		
		/**
		 * on retourne le nombre effectif d'instances utilisées en mémoire
		 * 
		 * attention, cette méthode n'a de raison d'être appelée que si on a alloué de la mémoire pour les instances de cet asset, sinon la méthode va échouer
		 * 
		 * @return	nombre d'instances comptées en mémoire
		 */
		public function get instanceEffectiveCount() : int {
			var lCount	: int			= freeInstances.length;
			var lAssetI	: AssetInstance;
			
			for each( lAssetI in usedInstances) lCount++;
			
			return lCount;
		}
		
		/**
		 * retrouve l'état du verrou d'instance ; on cherche dans config de l'asset, puis dans ses groupes et enfin dans la config globale si on trouve rien
		 * @return	nom d'état du verrou d'instance (voir constantes des AssetsSharedProperties) ; est forcément défini
		 */
		public function get lockInstance() : String {
			var lI		: String;
			var lLock	: String;
			
			if( sharedProperties.lockInstance != AssetsSharedProperties.LOCKER_UNDEFINED) return sharedProperties.lockInstance;
			else{
				for( lI in groups){
					lLock = groups[ lI].lockInstance;
					
					if( lLock != AssetsSharedProperties.LOCKER_UNDEFINED) return lLock;
				}
			}
			
			return mgr.sharedProperties.lockInstance;
		}
		
		/**
		 * valeur d'alpha du template de cet asset ; si rien de défini pour l'asset, on cherche dans ses groupes, et sinon on prend la config globale
		 * @return	valeur d'alpha (0..1) du template de cet asset
		 */
		public function get templateAlpha() : Number {
			var lI		: String;
			var lAlpha	: Number;
			
			if( sharedProperties.templateAlpha >= 0) return sharedProperties.templateAlpha;
			else{
				for( lI in groups){
					lAlpha = groups[ lI].templateAlpha;
					
					if( lAlpha >= 0) return lAlpha;
				}
			}
			
			return mgr.sharedProperties.templateAlpha;
		}
		
		/**
		 * on retourne de rendu à effectuer pour cet asset
		 * @return	type de rendu de l'asset
		 */
		public function get render() : AssetRender {
			var lI		: String;
			var lRender	: AssetRender;
			
			if( sharedProperties.render) return sharedProperties.render;
			else{
				for( lI in groups){
					lRender = groups[ lI].render;
					
					if( lRender) return lRender;
				}
			}
			
			return mgr.sharedProperties.render;
		}
		
		/**
		 * donne le type de génération d'export de cet asset
		 * @return	tag de type de génération d'export, voir AssetsSharedProperties::GEN_INTERNAL ou AssetsSharedProperties::GEN_EXTERNAL
		 */
		public function get generateMode() : String {
			var lI		: String;
			var lVal	: String;
			
			if ( sharedProperties.generateMode) return sharedProperties.generateMode;
			else {
				for ( lI in groups) {
					lVal = groups[ lI].generateMode;
					
					if ( lVal) return lVal;
				}
			}
			
			if ( mgr.sharedProperties.generateMode) return mgr.sharedProperties.generateMode;
			else return null;
		}
		
		/**
		 * on récupère une valeur définie en "datas" pour l'asset et correspondant à la clef passée
		 * @param	pId		clef de la valeur cherchée dans les datas de cet asset
		 * @return	valeur correspondante, ou null si rien de défini
		 */
		public function getData( pId : String) : String {
			var lI		: String;
			var lVal	: String;
			
			if( sharedProperties.datas[ pId])
				return sharedProperties.datas[ pId];
			else{
				for( lI in groups){
					lVal = groups[ lI].getData( pId);
					
					if( lVal) return lVal;
				}
			}
			
			if( mgr.sharedProperties.datas[ pId]) return mgr.sharedProperties.datas[ pId];
			else return null;
		}
		
		/**
		 * on effectue l'allocation mémoire des instances de cet asset ; plusieurs appels peuvent être nécessaire, tant que la méthode ne retourne pas true
		 * @return	true si l'allocation est finie ; false si on a juste progressé d'une itération -> on devra rappeler la méthode encore pour terminer le job
		 */
		public function malloc() : Boolean {
			if ( isAsyncGenTimeline()) return doAsyncGenTimeline();
			else if( isAsyncGenBmp()) return false;
			else{
				if( isMalloc()){
					mallocInstance();
					
					return true;
				}else {
					freeInstances	= new Array();
					usedInstances	= new Dictionary();
					
					if( mallocGenBmp()){
						mallocInstance();
						
						return true;
					}else return false;
				}
			}
		}
		
		/**
		 * on lance les générations bitmap
		 * @return	true si la génération bitmap est effectuée, false si elle est rendue asynchrone pour éviter le freeze
		 */
		protected function mallocGenBmp() : Boolean {
			var lRender	: AssetRender		= render;
			var lFile	: MyFile			= file;
			var lIsIMG	: Boolean			= ( lFile != null && lFile.isIMG());
			var lI		: int;
			var lBmp	: BitmapMovieClip;
			
			//MySystem.traceDebug( "AssetDesc::mallocGenBmp " + id);
			
			if( export || lIsIMG){
				try{
					if ( lRender.render == AssetRender.RENDER_BITMAP) {
						if ( lIsIMG) {
							lBmp = BitmapMovieClip.generateFromBitmap(
								Bitmap( CycloLoaderMgr.getInstance().getLoadingFile( lFile.id).getLoadedContent()),
								id,
								lRender.snap,
								lRender.smooth,
								lRender.stabil,
								this
							);
						}else {
							lBmp = BitmapMovieClip.generateFromMovieClip(
								MovieClip( generateExport( export, lFile)),
								id,
								lRender.snap,
								lRender.smooth,
								lRender.stabil,
								lRender.bmpTrans,
								this,
								lRender.bmpStepParse,
								generateMode == AssetsSharedProperties.GEN_EXTERNAL,
								lRender.bmpFixedQ
							);
						}
						
						markBitmap( lBmp);
						
						return ! lBmp.isAsyncGen();
					}else{
						if( lRender.bmpParseMode == AssetRender.PARSE_IN_DEPTH) return parseInDepth( generateExport( export, lFile), lRender);
						else if( lRender.bmpParseMode == AssetRender.PARSE_IN_LENGTH) return parseInLength( MovieClip( generateExport( export, lFile)), lRender);
					}
				}catch( pE : ReferenceError){
					trace( pE.toString());
					export = null;
				}
			}
			
			return true;
		}
		
		/**
		 * on effectue l'allocation mémorie des instances disponibles
		 */
		protected function mallocInstance() : void {
			var lCount	: int	= instanceCount;
			var lI		: int;
			
			//MySystem.traceDebug( "AssetDesc::mallocInstance " + id);
			
			for( lI = 0 ; lI < lCount ; lI++){
				try{
					freeInstances.push( generateInstance());
				}catch( pE : ReferenceError){
					if( export){
						try{
							getDomain( file).getDefinition( export);
						}catch( pE2 : ReferenceError){
							trace( pE2.toString());
							export = null;
							lI--;
							continue;
						}
					}
					
					if ( exportTemplate) {
						try {
							getDomain( file).getDefinition( exportTemplate);
						}catch ( pE3 : ReferenceError) {
							trace( pE3.toString());
							exportTemplate = null;
							lI--;
							continue;
						}
					}
					
					throw( pE);
				}
			}
		}
		
		/**
		 * on libère les instances allouées en mémoire ; attention, on suppose que toutes les instances utilisées ont été libérées
		 */
		public function free() : void {
			var lRender	: AssetRender	= render;
			var lId		: String;
			var lI		: int;
			
			if ( _activeCtr > 0) MySystem.traceDebug( "ERROR : AssetDesc::free : " + id + " active ctr=" + _activeCtr);
			
			for( lId in usedBmp){
				bmpCount[ lId]--;
				
				if( bmpCount[ lId] == 0){
					delete bmpCount[ lId];
					
					BitmapMovieClipMgr.flushByIndex( lId);
				}
			}
			
			if ( timelineLoaders != null) {
				for ( lI = 0 ; lI < timelineLoaders.length ; lI++) ( timelineLoaders[ lI] as Loader).unloadAndStop();
				
				timelineLoaders = null;
			}
			
			freeInstances	= null;
			usedInstances	= null;
			usedBmp			= null;
			_activeCtr		= 0;
		}
		
		/**
		 * on vérifie si ce descripteur d'asset est "actif", c'est à dire si on a prévu de la mémoire d'allocation pour des instances d'assets
		 * 
		 * même si aucune instance n'a été préchargée en mémoire (config d'instance à 0), le descripteur est dit actif à partir du moment
		 * où on a demandé de préparer une allocation
		 * 
		 * @return	true si le descripteur est actif, false sinon (pas de mémoire allouée pour d'éventuelles instances)
		 */
		public function isMalloc() : Boolean { return Boolean( freeInstances);}
		
		/**
		 * on vérifie si le descripteur possède un nom d'export de défini pour ses instances d'assets
		 * @return	true si au moins un nom d'export est défini, false sinon
		 */
		public function hasExport() : Boolean { return export || exportTemplate;}
		
		/** @inheritDoc */
		public function onBitmapGenerateComplete( pBmpId : String) : void {
			var lI	: int;
			
			for( lI = 0 ; lI < asyncGenBmps.length ; lI++){
				if( BitmapMovieClip( asyncGenBmps[ lI]).bmpId == pBmpId){
					asyncGenBmps.splice( lI, 1);
					
					break;
				}
			}
		}
		
		/**
		 * on lance une duplication de timeline
		 */
		protected function doGenTimeline() : void {
			var lContext	: LoaderContext;
			var lInfos		: LoaderInfo;
			
			timelineLoader				= new Loader();
			timelineLoader.contentLoaderInfo.addEventListener( Event.COMPLETE, onTimelineDuplicate);
			
			lInfos						= CycloLoaderMgr.getInstance().getLoadingFile( file.id).getLoaderDispatcher() as LoaderInfo;
			lContext					= new LoaderContext( false, lInfos.applicationDomain);
			lContext.allowCodeImport	= true;
			
			timelineLoaders.push( timelineLoader);
			
			timelineLoader.loadBytes( lInfos.bytes, lContext);
		}
		
		/**
		 * on avance l'allocation mémoire d'un asset de type timelie
		 * @return	true si allocation finie, false sinon
		 */
		protected function doAsyncGenTimeline() : Boolean {
			if( freeInstances == null){
				freeInstances	= new Array();
				usedInstances	= new Dictionary();
				timelineLoaders	= new Array();
				
				doGenTimeline();
				
				return false;
			}else return timelineLoader == null;
		}
		
		/**
		 * appelé pour signaler la fin d'une duplication de timeline ; on lance la prochaine duplication si nécessaire
		 * @param	pE	event de fin de duplication
		 */
		protected function onTimelineDuplicate( pE : Event) : void {
			var lInfos		: LoaderInfo	= pE.target as LoaderInfo;
			var lTemplate	: DisplayObject	= null;
			
			lInfos.removeEventListener( Event.COMPLETE, onTimelineDuplicate);
			
			if( exportTemplate) lTemplate = generateExport( exportTemplate, templateFile, trans);
			freeInstances.push( new AssetInstance( this, lInfos.content, lTemplate, templateAlpha));
			
			if ( freeInstances.length < instanceCount) doGenTimeline();
			else timelineLoader = null;
		}
		
		/**
		 * on vérifie si on a un asset de type timelie qui nécessite une génération asynchrone
		 * @return	true si asset de type time line avec génération asynchrone d'instances, false sinon
		 */
		protected function isAsyncGenTimeline() : Boolean { return export == EXPORT_TIMELINE && instanceCount > 0 && render.render != AssetRender.RENDER_BITMAP && ! CycloLoaderMgr.getInstance().getLoadingFile( file.id).isEmbed(); }
		
		/**
		 * on vérifie si il y a une génération bitmap asynchrone en cours
		 * @return	true si en cours de génération bitmap asynchrone, sinon false
		 */
		protected function isAsyncGenBmp() : Boolean { return asyncGenBmps.length > 0;}
		
		/**
		 * on marque un bitmap comme étant utilisé par les assets décrits par ce descripteur
		 * @param	pBmp	instance de bitmap utilisée pour identifier le marquage
		 */
		protected function markBitmap( pBmp : BitmapMovieClip) : void {
			var lId	: String	= pBmp.bmpId;
			
			if( pBmp.isAsyncGen()) asyncGenBmps.push( pBmp);
			
			if( ! usedBmp) usedBmp = new Object();
			if( ! bmpCount) bmpCount = new Object();
			
			if( ! usedBmp[ lId]){
				usedBmp[ lId] = true;
				
				if( ! bmpCount[ lId]) bmpCount[ lId] = 1;
				else bmpCount[ lId]++;
			}
		}
		
		/**
		 * parcours en profondeur à la recherche d'instances de BitmapMovieClip pour les pré-générer
		 * @param	pContent		objet graphique à parser
		 * @param	pRender			paramètres de rendu à utiliser pour générer le bitmap
		 * @param	pIsGenComplete	lors de la récursion de la méthode, ce paramètre indique si les précédentes instances de bitmap dont on a lancé la génération sont toutes arrivées au terme de leur génération (true) ou pas (false)
		 * @return	true si la génération bitmap est effectuée, false si elle est rendue asynchrone pour éviter le freeze
		 */
		protected function parseInDepth( pContent : DisplayObject, pRender : AssetRender, pIsGenComplete : Boolean = true) : Boolean {
			var lBmp		: BitmapMovieClip	= null;
			var lIsComplete	: Boolean;
			var lI 			: int;
			
			if( pContent is BitmapMovieClip){
				if( ( ! BitmapMovieClipMgr.isBmpInfos( BitmapMovieClip( pContent).bmpId)) && ! pRender.ignoreParseBmp){
					lBmp = BitmapMovieClip.generateFromMovieClip(
						MovieClip( pContent),
						BitmapMovieClip( pContent).bmpId,
						pRender.snap,
						pRender.smooth,
						pRender.stabil,
						pRender.bmpTrans,
						this
					);
					
					markBitmap( lBmp);
				}else markBitmap( BitmapMovieClip( pContent));
				
				return ( lBmp == null || ( ! lBmp.isAsyncGen())) && pIsGenComplete;
			}else if( pContent is DisplayObjectContainer){
				lIsComplete = pIsGenComplete;
				
				for( lI = 0 ; lI < DisplayObjectContainer( pContent).numChildren ; lI++){
					lIsComplete &&= parseInDepth( DisplayObjectContainer( pContent).getChildAt( lI), pRender);
				}
				
				return lIsComplete;
			}
			
			return pIsGenComplete;
		}
		
		/**
		 * parcours en "longueur" à la recherche d'instances de BitmapMovieClip pour les pré-générer
		 * @param	pContent	objet graphique à parser ; il s'agit d'un movie clip, ce parsing n'a de sens que sur un objet graphique avec une time line !
		 * @param	pRender		paramètres de rendu à utiliser pour générer le bitmap
		 * @return	true si la génération bitmap est effectuée, false si elle est rendue asynchrone pour éviter le freeze
		 */
		protected function parseInLength( pContent : MovieClip, pRender : AssetRender) : Boolean {
			var lIsComplete	: Boolean			= true;
			var lBmp		: BitmapMovieClip;
			var lI			: int;
			var lChild		: DisplayObject;
			
			do{
				for( lI = 0 ; lI < pContent.numChildren ; lI++){
					lChild = pContent.getChildAt( lI);
					
					if( lChild is BitmapMovieClip){
						if( ( ! BitmapMovieClipMgr.isBmpInfos( BitmapMovieClip( lChild).bmpId)) && ! pRender.ignoreParseBmp){
							lBmp = BitmapMovieClip.generateFromMovieClip(
								MovieClip( lChild),
								BitmapMovieClip( lChild).bmpId,
								pRender.snap,
								pRender.smooth,
								pRender.stabil,
								pRender.bmpTrans,
								this
							);
							
							markBitmap( lBmp);
							
							lIsComplete	&&= ! lBmp.isAsyncGen();
						}else markBitmap( BitmapMovieClip( lChild));
					}
				}
				
				if( pContent.currentFrame == pContent.totalFrames) break;
				else pContent.nextFrame();
			}while( true);
			
			return lIsComplete;
		}
		
		/**
		 * on génère une instance d'asset
		 * 
		 * attention, en cas de rendu bitmap, on suppose que le rendu a déjà été pré-généré
		 * 
		 * @return	instance d'asset
		 */
		protected function generateInstance() : AssetInstance {
			var lRender		: AssetRender		= render;
			var lExport 	: DisplayObject		= null;
			var lTemplate	: DisplayObject		= null;
			var lFile		: MyFile			= file;
			var lIsIMG		: Boolean			= ( lFile != null && lFile.isIMG());
			var lTrans		: Matrix;
			
			if( export || lIsIMG){
				if( lRender.render == AssetRender.RENDER_BITMAP){
					lExport = new BitmapMovieClip( id, lRender.snap, lRender.smooth, lRender.stabil);
					
					if( trans){
						lTrans = lExport.transform.matrix;
						lTrans.concat( trans);
						lExport.transform.matrix = lTrans;
					}
				}else lExport = generateExport( export, lFile, trans);
			}
			
			if( exportTemplate) lTemplate	= generateExport( exportTemplate, templateFile, trans);
			
			return new AssetInstance( this, lExport, lTemplate, templateAlpha);
		}
		
		/**
		 * on récupère le domaine d'application utilisé par cet asset ; donne une valeur par défaut si pas défini
		 * @param	pFile	descripteur de fichier de l'asset (::file ou ::templateFile) ; peut ne pas être défini (null)
		 * @return	domaine d'application de l'asset ; si rien de défini pour cet asset, on retourne le domaine d'application par défaut de l'appli
		 */
		protected static function getDomain( pFile : MyFile) : ApplicationDomain {
			if ( pFile == null) return ApplicationDomain.currentDomain;
			else return pFile.applicationDomain;
		}
		
		/**
		 * on génère un rendu vecto de l'export de l'asset
		 * @param	pExport	nom d'export du rendu vecto à générer
		 * @param	pFile	fichier source du rendu vecto ; permet de définir son domaine d'application
		 * @param	pTrans	transformation à appliquer au rendu, ou null si aucune transfo définie
		 * @return	rendu vecto de l'export
		 */
		protected function generateExport( pExport : String, pFile : MyFile, pTrans : Matrix = null) : DisplayObject {
			var lMC		: DisplayObject		= null;
			
			if ( generateMode == AssetsSharedProperties.GEN_EXTERNAL) lMC = mgr.generateExternalExport( pExport);
			
			if( lMC == null){
				if ( pExport != EXPORT_TIMELINE) lMC = new ( Class( getDomain( pFile).getDefinition( pExport)))();
				else lMC = CycloLoaderMgr.getInstance().getLoadingFile( pFile.id).getLoadedContent();
			}
			
			if( pTrans) lMC.transform.matrix = pTrans.clone();
			
			return lMC;
		}
	}
}