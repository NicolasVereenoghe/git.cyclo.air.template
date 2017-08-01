package net.cyclo.shell {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.net.LocalConnection;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;

	/**
	 * outils de controle du sytème
	 * 
	 * @author	nico
	 */
	public class MySystem extends Sprite {
		/** taille de font de debug en pixels */
		protected static var DEBUG_TXT_SIZE		: int						= 20;
		
		/** réf sur le stage de l'appli ; doit être défini à l'initialisation de l'appli !! */
		protected static var _stage				: Stage						= null;
		
		/** frame rate original de l'appli ; -1 si pas encore défini */
		protected static var _FPS				: Number					= -1;
		/** frame rate conjoncturel de l'appli */
		protected static var tmpFPS				: Number					= -1;
		/** qualité de rendu de l'appli */
		protected static var _initialQuality	: String					= null;
		/** flag indiquant si le fps contextuel est forcé (true) ou pas (false) ; si fps contextuel forcé, on ne l'utilise plus tant qu'on n'invoque pas sa restauration (voir ::restaureFPS) */
		protected static var isFPSForced		: Boolean					= false;
		
		/** chemin de chargement qui préfixe les chemins relatifs des fichiers à charger ; si défini, doit se terminer par "/" ; "" si aucun de défini */
		protected static var _mainPath			: String					= "";
		
		/** chemins de chargement prédéfinis en fonction d'un nom d'extension ; map de path indexée par extension en minuscule */
		protected static var _extPath			: Object					= null;
		/** chemins de chargement prédéfinis en fonction d'un tag ; map de path indexée par tag */
		protected static var _tagPath			: Object					= null;
		/** collection de noms de fichiers indexés par noms de tags */
		protected static var _tagFileName		: Object					= null;
		
		/** flag indiquant si la souris est down sur le stage (true) ou pas (false) */
		protected static var _isMouseDown		: Boolean					= false;
		
		/** nom de scène du conteneur de trace debug sur le stage */
		protected static var TRACE_CONT_NAME	: String					= "mcTraceDebug";
		
		/** dernière ordonnée de trace de debug */
		//protected static var lastDebugY			: Number					= 0;
		/** conteneur de trace de debug ; null si pas encore instancié */
		//protected static var traceContainer		: DisplayObjectContainer	= null;
		
		/**
		 * on ajoute un champ de debug sur le stage de l'appli
		 * @param	pTxtDebug	texte à afficher dans le cham pde debug
		 */
		public static function traceDebug( pTxtDebug : String) : void {
			trace( pTxtDebug);
			
			CONFIG::debug {
				var lTxt		: TextField					= new TextField();
				var lContainer	: DisplayObjectContainer;
				var lListener	: Sprite;
				
				if ( _stage == null) {
					trace( "ERROR : MySystem::traceDebug : stage non défini, impossible de tracer");
					return;
				}else {
					lContainer = _stage.getChildByName( TRACE_CONT_NAME) as DisplayObjectContainer;
					
					if ( lContainer == null) {
						lContainer				= _stage.addChild( new Sprite()) as DisplayObjectContainer;
						lContainer.name			= TRACE_CONT_NAME;
						lContainer.mouseEnabled	= false;
						
						lListener = _stage.addChild( new Sprite()) as Sprite;
						lListener.graphics.beginFill( 0, 0);
						lListener.graphics.drawRect( 0, 0, 3, 3);
						lListener.graphics.endFill();
						
						lListener.addEventListener( MouseEvent.CLICK, onTraceDebugClicked);
					}
					
					lTxt.defaultTextFormat = new TextFormat( null, DEBUG_TXT_SIZE);
					
					lTxt.mouseEnabled	= false;
					lTxt.width			= 2000;
					lTxt.text			= pTxtDebug;
					lTxt.textColor		= 0x999999;
					lTxt.y				= -lContainer.numChildren * DEBUG_TXT_SIZE;
					lContainer.y		= lContainer.numChildren * DEBUG_TXT_SIZE;
					
					lContainer.addChild( lTxt);
				}
			}
		}
		
		/**
		 * capture de click sur bouton de console de debug
		 * @param	pE	event de souris
		 */
		protected static function onTraceDebugClicked( pE : MouseEvent) : void { _stage.getChildByName( TRACE_CONT_NAME).visible = ! _stage.getChildByName( TRACE_CONT_NAME).visible;}
		
		/**
		 * on définit l'objet Stage pour toute l'application ; attention, une seule initialisation est acceptée
		 */
		public static function set stage( pStage : Stage) : void {
			if ( _stage == null) {
				_stage	= pStage;
				_FPS	= tmpFPS = _stage.frameRate;
				
				_initialQuality = _stage.quality;
				
				_stage.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown);
				_stage.addEventListener( MouseEvent.MOUSE_UP, onMouseUp);
			}else trace( "WARNING : MyStstem::set stage : stage déjà défini, on ignore ce set !");
		}
		
		/**
		 * on vérifie si la souris est down sur le stage
		 * @return	true si souris down, false sinon
		 */
		public static function get isMouseDown() : Boolean { return _isMouseDown; }
		
		/**
		 * on récupère le stage de l'application
		 * @return	instance de stage de l'application, ou null si pas encore défini
		 */
		public static function get stage() : Stage { return _stage;}
		
		/**
		 * on récupère la qualité de rendu originale
		 * @return	tag de qualité temporisé lors du set de stage
		 */
		public static function get initialQuality() : String { return _initialQuality;}
		
		/**
		 * on réupcère le frame rate original de l'appli
		 * @return	FPS original ou -1 si non défini
		 */
		public static function get FPS() : Number { return _FPS;}
		
		/**
		 * on défini un fps conjoncturel pour l'appli. ce fps peut évoluer et être forcé (voir ::forceFPS) pour ensuite être restitué au dernier fps conjoncturel défini (voir ::restaureFPS)
		 * @param	pFPS	fps conjoncturel de l'appli
		 */
		public static function setFPS( pFPS : Number) : void {
			tmpFPS = pFPS;
			
			if ( ! isFPSForced) _stage.frameRate = pFPS;
		}
		
		/**
		 * on restitue le dernier FPS conjoncturel défini pour l'appli
		 */
		public static function restaureFPS() : void {
			isFPSForced			= false;
			_stage.frameRate	= tmpFPS;
		}
		
		/**
		 * on force le fps contextuel ; ce qui est défini en contextuel est ignoré tant qu'on n'invoque pas sa restauration (voir ::restaureFPS)
		 * @param	pFPS	fps forcé
		 */
		public static function forceFPS( pFPS : Number) : void {
			isFPSForced			= true;
			_stage.frameRate	= pFPS;
		}
		
		/**
		 * on définit le chemin de chargement de l'appli qui préfixe les fichiers à charger dont le chemin est non défini ; si besoin, doit être défini au début de l'appli pour que les chargement suivants en profitent ; attention, une seule initialisation est acceptée
		 * @param	chemin / url de préfixe de chargement ; doit se terminer par un séparateur de dossier (ie : "/")
		 */
		public static function set mainPath( pPath : String) : void {
			if( _mainPath == "") _mainPath = pPath;
			else trace( "WARNING : MySystem::set mainPath : mainPath déjà défini, on ignore ce set !");
		}
		
		/**
		 * on récupère le chemin de chargement qui préfixe les fichiers à charger dans l'appli qui n'ont pas de chemin défini
		 * @return	chemin / url de préfixe de chargement
		 */
		public static function get mainPath() : String { return _mainPath;}
		
		/**
		 * on ajoute un chemin de chargement pour l'extension spécifiée
		 * @param	pExt	nom d'extension ; la casse ne compte pas
		 * @param	pPath	le chemin / url de chargement à associer à cette extension de fichier
		 */
		public static function addExtPath( pExt : String, pPath : String) : void {
			pExt = pExt.toLowerCase();
			
			if( _extPath == null){
				_extPath		= new Object();
				_extPath[ pExt]	= pPath;
			}else if( _extPath[ pExt] == undefined) _extPath[ pExt] = pPath;
			else trace( "WARNING : MyStstem::addExtPath : path déjà défini pour l'extension " + pExt + ", on ignore !");
		}
		
		/**
		 * on récupère le chemin défini pour l'extension spécifiée
		 * @param	pExt	nom d'extension ; la casse ne compte pas
		 * @return	le path défini ou null si non défini
		 */
		public static function getExtPath( pExt : String) : String {
			pExt = pExt.toLowerCase();
			
			if( _extPath != null && _extPath[ pExt] != undefined) return _extPath[ pExt];
			else return null;
		}
		
		/**
		 * on ajoute un chemin de chargement pour le nom de tag spécifié
		 * @param	pTag	nom de tag
		 * @param	pPath	le chemin / url de chargement à associer à cette extension de fichier
		 */
		public static function addTagPath( pTag : String, pPath : String) : void {
			if( _tagPath == null){
				_tagPath		= new Object();
				_tagPath[ pTag]	= pPath;
			}else if( _tagPath[ pTag] == undefined) _tagPath[ pTag] = pPath;
			else trace( "WARNING : MyStstem::addTagPath : path déjà défini pour le tag " + pTag + ", on ignore !");
		}
		
		/**
		 * on récupère le chemin défini pour le nom de tag spécifié
		 * @param	pTag	nom de tag
		 * @return	le path défini ou null si non défini
		 */
		public static function getTagPath( pTag : String) : String {
			if( _tagPath != null && _tagPath[ pTag] != undefined) return _tagPath[ pTag];
			else return null;
		}
		
		/**
		 * on ajoute un nom de fichier pour le nom de tag spécifié
		 * @param	pTag		nom de tag
		 * @param	pFileName	nom de fichier
		 */
		public static function setTagFileName( pTag : String, pFileName : String) : void {
			if( _tagFileName == null){
				_tagFileName		= new Object();
				_tagFileName[ pTag]	= pFileName;
			}else if( _tagFileName[ pTag] == undefined) _tagFileName[ pTag] = pFileName;
			else trace( "WARNING : MySystem::setTagFileName : nom de fichier déjà défini pour le tag " + pTag + ", on ignore !");
		}
		
		/**
		 * on récupère un nom de fichier en fonction du tag spécifié
		 * @param	pTag		nom de tag
		 * @return	le nom de fichier asoocié à ce tag, ou null si pas défini
		 */
		public static function getTagFileName( pTag : String) : String {
			if( _tagFileName != null && _tagFileName[ pTag] != undefined) return _tagFileName[ pTag];
			else return null;
		}
		
		/**
		 * demande le passage du garbage collector
		 */
		public static function gc() : void { /*trace( "TODO : MySystem::gc : pas fonctionnel, à implémenter !");*//*System.pauseForGCIfCollectionImminent( .1);*/System.gc(); }
		
		/** 
		 * détermine si on est dans un player stand alone, ou si on est dans un player embarqué dans un navigateur ou AIR
		 * @return	true si stand alone, false sinon
		 */		
		public static function isStandalone() : Boolean { return ( Capabilities.playerType == "External" || Capabilities.playerType == "StandAlone");}
		
		/**
		 * détermine si le player est de type AIR
		 * @return	true si le player est de type AIR, false sinon
		 */		
		public static function isDesktop() : Boolean { return ( Capabilities.playerType == "Desktop");}
		
		/** 
		 * teste si on est en local sur sa machine
		 * @return	true si on est en local, false sinon
		 */	
		public static function isLocal() : Boolean { return ( ( new LocalConnection()).domain == "localhost");}
		
		/**
		 * détermine si on est dans un contexte "online" (http) ; on doit spécifier le stage du loader initial de l'application, ceci se mesure grâce à cette instance
		 * @param	pStage	instance de stage pour tester le contexte ou laisser vide pour utiliser celui que UtilsSystem définit
		 * @return	true si contexte "online", sinon false
		 */	
		public static function isHttp( pStage : Stage = null) : Boolean {
			if( pStage == null){
				if( _stage == null){
					trace( "ERROR : MySystem::isHttp : stage non défini, impossible de répondre correctement, par défaut on assume qu'on n'est pas en http");
					
					return false;
				}else pStage = _stage;
			}
			
			return ( pStage.root.loaderInfo.url.substr( 0, 4) == "http");
		}
		
		/**
		 * détermine si l'application est éxécutée par un player debug
		 * @return	true si player dedbug, false sinon
		 */
		public static function isDebugger() : Boolean { return Capabilities.isDebugger; }
		
		/**
		 * renvoie la callstack actuelle ; attention: cela renvoie null si on est pas en player debug 
		 * @return call stack à tracer, ou null si pas en player debug
		 */
		public static function getCallStack() : String { return new Error().getStackTrace(); }
		
		/**
		 * on est notifié que la souris est down sur le stage
		 * @param	pE	event de souris
		 */
		protected static function onMouseDown( pE : MouseEvent) : void {
			MySystem.traceDebug( "INFO : MySystem::onMouseDown");
			_isMouseDown = true;
		}
		
		/**
		 * on est notifié que la souris est up sur le stage
		 * @param	pE	event de souris
		 */
		protected static function onMouseUp( pE : MouseEvent) : void {
			MySystem.traceDebug( "INFO : MySystem::onMouseUp");
			_isMouseDown = false;
		}
	}
}