package net.cyclo.bitmap {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.PixelSnapping;
	import flash.display.Stage;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.filters.BevelFilter;
	import flash.filters.BitmapFilter;
	import flash.filters.BlurFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.filters.GradientBevelFilter;
	import flash.filters.GradientGlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	
	import net.cyclo.utils.UtilsMovieClip;
	import net.cyclo.shell.MySystem;
	
	/**
	 * spécialisation d'un movie clip dans le rendu de bitmap
	 * 
	 * @author	nico
	 */
	public class BitmapMovieClip extends MovieClip {
		/** nom de clip de cadrage de bitmap généré ; si ce clip de cadrage n'est pas défini, on utilise les dimensions dse rendus trouvés ; /!\ : les effets bitmaps ne sont pas bien pris en compte */
		public static const CADRE_NAME			: String					= "mcCadre";
		
		/** nombre de pixels de marge si on la stabilisation de rendu est utilisé (voir _isStabil) */
		protected var STABIL_OFFSET				: int						= 2;
		
		/** temps max toléré pour la génération bitmap lors d'une itération, en ms */
		protected var MAX_GEN_TIME				: int						= 500;
		
		/** snapping du bitmap généré ; utiliser les constantes de PixelSnapping ; uniquement utilisé lors de la génération ; si déjà généré, on ignore cette propriété */
		protected var _pixelSnap				: String;
		/** false pas de rendu bitmap avec smoothing, true avec ; uniquement utilisé lors de la génération ; si déjà généré, on ignore cette propriété */
		protected var _isSmooth					: Boolean;
		/** true pour utiliser la "stabilisation du rendu d'une anime bitmap" pour éviter l'effet de "flottaison" ; false sinon ; uniquement utilisé lors de la génération ; si déjà généré, on ignore cette propriété */
		protected var _isStabil					: Boolean;
		
		/** indique si le movie clip modèle à parser pour générer le bitmap est déjà un clone (true), ou si on doit le cloner avant le parsing (false, par défaut) */
		protected var isModelClone				: Boolean					= false;
		
		/** identifiant de bitmap ; identifiant unique au rendu bitmap */
		protected var _bmpId					: String;
		
		/** numéro de frame virtuelle courrante */
		protected var _curFrame					: int;
		
		/** flag indiquant si la time line virtuelle du clip rasterisé est en train de jouer (true) ou pas (false) */
		protected var _isPlaying				: Boolean;
		
		/** clip dont on générère le contenu bitmap de manière asynchrone ; la position de sa tête de lecture indique l'état d'avancement du traitement (la prochaine position à traiter) ; null si pas de génération asynchrone en cours */
		protected var asyncGenTarget			: MovieClip					= null;
		/** instance qui reçoit la notification de fin de traitement de génération bitmap ; null si pas de génération asynchrone en cours */
		protected var asyncGenCallBack			: INotifyBitmapGenerate		= null;
		/** pas d'avancement du parsing bitmap lors de la génération asynchrone */
		protected var asyncGenStep				: int;
		
		/**
		 * génération de BitmapMovieClip en mémoire à partir d'un movie clip ; pas de contrôle, on suppose que le clip n'a pas encore été généré
		 * @param	pDisp			movie clip dont on parse le contenu
		 * @param	pBMPId			identifiant de BitmapMovieClip
		 * @param	pPixelSnap		optionnel : snapping du bitmap généré ; utiliser les constantes de PixelSnapping
		 * @param	pIsSmooth		optionnel : false pas de smoothing, true avec
		 * @param	pIsStabil		optionnel : true pour utiliser la "stabilisation du rendu d'une anime bitmap" pour éviter l'effet de "flottaison" ; false sinon
		 * @param	pQualityMtrx	optionnel : une matrice de transformation pour controler la qualité de rasterisation ; lors du rendu, on appliquera la transformation inverse pour rendre à la taille d'origine ; pas besoin de cloner la matrice transmise, elle l'est dans le code
		 * @param	pINotifyBmpGen	optionnel : instance qui reçoit la notification de fin de génération bitmap ; laisser null si génération synchrone sans notification
		 * @param	pStep			optionnel : pas d'avancement du parsing bitmap ; par défaut 1, on parse toutes les frames du clip
		 * @param	pIsClone		optionnel : indique si le movie clip modèle est déjà un clone (true), ou si on doit le cloner avant le parsing (false, par défaut)
		 * @param	pFixedQ			optionnel : indique si le bmp généré prend en compte le scale global appliqué sur l'appli (false), ou si on a une qualité fixe quelque soit le scale global (true)
		 * @return	instance de BitmapMovieClip utilisée pour effectuer la génération de contenu bitmap ; peut servir à interroger si elle a finie sa génération ou si elle effectue un travail asynchrone (voir ::isAsyncGenComplete) ; attention, ce n'est pas une instance qui peut servir pour le rendu !
		 */
		public static function generateFromMovieClip( pDisp : MovieClip, pBMPId : String, pPixelSnap : String = "never"/*PixelSnapping.NEVER*/, pIsSmooth : Boolean = false, pIsStabil : Boolean = false, pQualityMtrx : Matrix = null, pINotifyBmpGen : INotifyBitmapGenerate = null, pStep : int = 1, pIsClone : Boolean = false, pFixedQ : Boolean = false) : BitmapMovieClip {
			var lBMC	: BitmapMovieClip	= new BitmapMovieClip( pBMPId, pPixelSnap, pIsSmooth, pIsStabil);
			
			//MySystem.traceDebug( "BitmapMovieClip::generateFromMovieClip " + lBMC.bmpId);
			
			lBMC.removeEventListener( Event.ADDED_TO_STAGE, lBMC.onAddedToStage);
			lBMC.isModelClone = pIsClone;
			lBMC.generate( pDisp, pQualityMtrx, pINotifyBmpGen, pStep, pFixedQ);
			
			return lBMC;
		}
		
		/**
		 * génération de BitmapMovieClip en mémoire à partir d'un bitmap ; pas de contrôle, on suppose que le clip n'a pas encore été généré
		 * @param	pDisp			movie clip dont on parse le contenu
		 * @param	pBMPId			identifiant de BitmapMovieClip
		 * @param	pPixelSnap		optionnel : snapping du bitmap généré ; utiliser les constantes de PixelSnapping
		 * @param	pIsSmooth		optionnel : false pas de smoothing, true avec
		 * @param	pIsStabil		optionnel : true pour utiliser la "stabilisation du rendu d'une anime bitmap" pour éviter l'effet de "flottaison" ; false sinon
		 * @param	pINotifyBmpGen	optionnel : instance qui reçoit la notification de fin de génération bitmap ; laisser null si génération synchrone sans notification
		 * @return	instance de BitmapMovieClip utilisée pour effectuer la génération de contenu bitmap ; peut servir à interroger si elle a finie sa génération ou si elle effectue un travail asynchrone (voir ::isAsyncGenComplete) ; attention, ce n'est pas une instance qui peut servir pour le rendu !
		 */
		public static function generateFromBitmap( pBMP : Bitmap, pBMPId : String, pPixelSnap : String = "never"/*PixelSnapping.NEVER*/, pIsSmooth : Boolean = false, pIsStabil : Boolean = false, pINotifyBmpGen : INotifyBitmapGenerate = null) : BitmapMovieClip {
			var lBMC	: BitmapMovieClip	= new BitmapMovieClip( pBMPId, pPixelSnap, pIsSmooth, pIsStabil);
			var lInfos	: BmpInfos			= new BmpInfos( pPixelSnap, pIsSmooth);
			
			//MySystem.traceDebug( "BitmapMovieClip::generateFromBitmap " + lBMC.bmpId);
			
			lBMC.removeEventListener( Event.ADDED_TO_STAGE, lBMC.onAddedToStage);
			
			BitmapMovieClipMgr.addBmpInfos( lBMC.bmpId, lInfos);
			
			lInfos.addFrameInfos( 1, new BmpFrameInfos( pBMP.bitmapData, 0, 0));
			
			return lBMC;
		}
		
		/**
		 * constructeur
		 * @param	pId			identifiant de bitmap à rendre ; si non spécifié, on utilise l'instance même pour savoir si on a déjà généré son contenu en bitmap, ou si la rasterisation doit être faite à partir de son contenu vecto
		 * @param	pPixelSnap	optionnel : snapping du bitmap généré ; utiliser les constantes de PixelSnapping
		 * @param	pIsSmooth	optionnel : false pas de smoothing, true avec
		 * @param	pIsStabil	optionnel : true pour utiliser la "stabilisation du rendu d'une anime bitmap" pour éviter l'effet de "flottaison" ; false sinon
		 */
		public function BitmapMovieClip( pId : String = null, pPixelSnap : String = "never"/*PixelSnapping.NEVER*/, pIsSmooth : Boolean = false, pIsStabil : Boolean = false) {
			super();
			
			_pixelSnap		= pPixelSnap;
			_isSmooth		= pIsSmooth;
			_isStabil		= pIsStabil;
			
			_curFrame		= 1;
			_isPlaying		= false;
			
			super.stop();
			
			setBmpId( pId);
			
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
		}
		
		/**
		 * on récupère l'identifiant de bitmap associé à l'instance
		 * @return	identifiant de bitmap
		 */
		public function get bmpId() : String { return _bmpId;}
		
		/**
		 * on vérifie si l'instance est en train d'opérer un traitement asynchrone de génération bitmap 
		 * @return	true si génération asynchrone en cours, false sinon
		 */
		public function isAsyncGen() : Boolean { return asyncGenTarget != null;}
		
		/** @inheritDoc */
		public override function play() : void {
			if( totalFrames > 1 && ! _isPlaying){
				_isPlaying = true;
				
				addEventListener( Event.ENTER_FRAME, doFrame);
			}
		}
		
		/** @inheritDoc */
		public override function stop() : void {
			if( _isPlaying){
				_isPlaying = false;
				
				removeEventListener( Event.ENTER_FRAME, doFrame);
			}
		}
		
		/** @inheritDoc */
		public override function nextFrame() : void {
			stop();
			
			if( _curFrame < totalFrames){
				_curFrame++;
				
				updateBmp();
			}
		}
		
		/** @inheritDoc */
		public override function prevFrame() : void {
			stop();
			
			if( _curFrame > 1){
				_curFrame--;
				
				updateBmp();
			}
		}
		
		/** @inheritDoc */
		public override function get currentFrame() : int { return _curFrame;}
		
		/** @inheritDoc */
		public override function get totalFrames() : int { return BitmapMovieClipMgr.getBmpInfos( _bmpId).totalFrames;}
		
		/**
		 * le paramètre frame doit être un entier, et on ignore le paramètre scene <br>
		 * @inheritDoc
		 */
		public override function gotoAndPlay( frame : Object, scene : String = null) : void {
			gotoFrame( int( frame));
			
			play();
		}
		
		/**
		 * le paramètre frame doit être un entier, et on ignore le paramètre scene <br>
		 * @inheritDoc
		 */
		public override function gotoAndStop( frame : Object, scene : String = null) : void {
			gotoFrame( int( frame));
			
			stop();
		}
		
		/**
		 * on effectue un saut de frame virtuel vers la frame spécifiée
		 * @param	pFrame	numéro de frame virtuelle vers où faire sauter l'affichage
		 */
		protected function gotoFrame( pFrame : int) : void {
			if( pFrame != _curFrame){
				_curFrame = pFrame;
				
				updateBmp();
			}
		}
		
		/**
		 * accès à la méthode MovieClip::currentFrame
		 * @return	numéro de frame courrant déterminé par la méthode MovieClip::currentFrame
		 */
		protected function get mcCurrentFrame() : int { return super.currentFrame;}
		
		/**
		 * accès à la méthode MovieClip::totalFrames
		 * @return	longueur de l'anim en nombre de frame déterminé par la méthode MovieClip::totalFrames
		 */
		protected function get mcTotalFrames() : int { return super.totalFrames;}
		
		/**
		 * accès à la méthode MovieClip::gotoAndStop
		 * @param	pFrame	numéro d'image ou nom de label de time line
		 */
		protected function mcGotoAndStop( pFrame : Object) : void { super.gotoAndStop( pFrame);}
		
		/**
		 * on récupère la méthode d'évaluation de la propriété MovieClip::currentFrame de l'instance spécifiée
		 * @param	pTarget	instance dont on cherche la méthode
		 * @return	référence sur méthode cherchée
		 */
		protected static function getCurrentFrameMethod( pTarget : MovieClip) : Function {
			if( pTarget is BitmapMovieClip) return ( function() : int { return BitmapMovieClip( pTarget).mcCurrentFrame;});
			else return ( function() : int { return pTarget.currentFrame;});
		}
		
		/**
		 * on récupère la méthode d'évaluation de la propriété MovieClip::totalFrames de l'instance spécifiée
		 * @param	pTarget	instance dont on cherche la méthode
		 * @return	référence sur méthode cherchée
		 */
		protected static function getTotalFramesMethod( pTarget : MovieClip) : Function {
			if( pTarget is BitmapMovieClip) return ( function() : int { return BitmapMovieClip( pTarget).mcTotalFrames;});
			else return ( function() : int { return pTarget.totalFrames;});
		}
		
		/**
		 * on récupère la méthode MovieClip::gotoAndStop de l'instance spécifiée
		 * @param	pTarget	instance dont on cherche la méthode
		 * @return	référence sur méthode cherchée
		 */
		protected static function getGotoAndStopFrameMethod( pTarget : MovieClip) : Function {
			if( pTarget is BitmapMovieClip) return BitmapMovieClip( pTarget).mcGotoAndStop;
			else return pTarget.gotoAndStop;
		}
		
		/**
		 * méthode d'itération par frame pour simuler la progression de la tête de lecture
		 * @param	pE	évènement di'tération de frame
		 */
		protected function doFrame( pE : Event) : void {
			if( ++_curFrame > totalFrames) _curFrame = 1;
			
			updateBmp();
		}
		
		/**
		 * le clip est posé sur la scène, on lance la rasterisation si celle-ci n'a pas déjà été faite, et le rendu bitmap
		 * @param	pE	évènement d'ajout sur scène
		 */
		protected function onAddedToStage( pE : Event) : void {
			removeEventListener( Event.ADDED_TO_STAGE, onAddedToStage);
			
			initialize();
			
			addEventListener( Event.REMOVED_FROM_STAGE, onRemove);
		}
		
		/**
		 * le clip est retiré de la scène, on libère la mémoire
		 * @param	pE	évènement de virage de scène ; peut être levé pour tout enfant du clip, on doit contrôler qu'il s'agit bien de l'instance
		 */
		protected function onRemove( pE : Event) : void {
			if( pE.currentTarget == this){
				removeEventListener( Event.REMOVED_FROM_STAGE, onRemove);
				
				stop();
			}
		}
		
		/**
		 * on initialise le contenu bitmap et on lance sa lecture ; si le contenu n'a pas encore été généré en bipmap, on fait la rasterisation
		 */
		protected function initialize() : void {
			var lChild	: DisplayObject;
			
			if( ! BitmapMovieClipMgr.isBmpInfos( _bmpId)) generate( this);
			
			while( numChildren > 0) UtilsMovieClip.free( getChildAt( 0));
			
			attachBmp();
			
			play();
		}
		
		/**
		 * on pose le rendu bitmap de la frame virtuelle courrante
		 */
		protected function attachBmp() : void {
			var lInfos		: BmpInfos		= BitmapMovieClipMgr.getBmpInfos( _bmpId);
			var lMtrx		: Matrix		= lInfos.transMtrx;
			var lFrInfos	: BmpFrameInfos	= lInfos.getFrameInfos( _curFrame);
			var lBmp		: Bitmap		= new Bitmap( lFrInfos.bmp, lInfos.snap, lInfos.smooth);
			var lOrigX		: Number;
			var lOrigY		: Number;
			var lMRes		: Matrix;
			
			if( lMtrx != null){
				lMRes	= transform.matrix;
				lOrigX	= lMRes.tx;
				lOrigY	= lMRes.ty;
				
				lMRes.concat( lMtrx);
				
				// le scale de la matrice de transformation change le x, y aussi ... on remet comme à l'origine
				lMRes.tx	= lOrigX;
				lMRes.ty	= lOrigY;
				
				transform.matrix = lMRes;
			}
			
			lBmp.x	= lFrInfos.x;
			lBmp.y	= lFrInfos.y;
			
			addChild( lBmp);
		}
		
		/**
		 * on met à jour le rendu bitmap à la frame virtuelle courrante
		 */
		protected function updateBmp() : void {
			var lBmp	: Bitmap		= Bitmap( getChildAt( 0));
			var lBInfos	: BmpInfos		= BitmapMovieClipMgr.getBmpInfos( _bmpId);
			var lInfos	: BmpFrameInfos	= lBInfos.getFrameInfos( _curFrame);
			
			lBmp.x			= lInfos.x;
			lBmp.y			= lInfos.y;
			lBmp.bitmapData	= lInfos.bmp;
			lBmp.smoothing	= lBInfos.smooth;
		}
		
		/**
		 * on lance la génération bitmap du contenu vecto du clip ; on suppose que rien n'a déjà été généré pour un clip ayant cet identifiant bitmap (_bmpId)
		 * @param	pTarget			movie clip dont on parse le contenu
		 * @param	pQualityMtrx	optionnel : une matrice de transformation pour controler la qualité de rasterisation ; lors du rendu, on appliquera la transformation inverse pour rendre à la taille d'origine ; pas besoin de cloner la matrice transmise, elle l'est dans le code
		 * @param	pINotifyBmpGen	optionnel : instance qui reçoit la notification de fin de génération bitmap ; laisser null si génération synchrone sans notification
		 * @param	pStep			optionnel : pas d'avancement du parsing bitmap ; par défaut 1, on parse toutes les frames du clip
		 * @param	pFixedQ			optionnel : indique si le bmp généré prend en compte le scale global appliqué sur l'appli (false), ou si on a une qualité fixe quelque soit le scale global (true)
		 * @return	true si fin de génération, false si on a spécifié une instance à notifier et si besoin de traitement asynchrone
		 */
		protected function generate( pTarget : MovieClip, pQualityMtrx : Matrix = null, pINotifyBmpGen : INotifyBitmapGenerate = null, pStep : int = 1, pFixedQ : Boolean = false) : Boolean {
			var lBaseMtrx	: Matrix		= pFixedQ ? null : BitmapMovieClipMgr.getBaseTransMtrx();
			var lQual		: String		= MySystem.stage.quality;
			var lTotal		: int;
			var lCtr		: int;
			var lInfos		: BmpInfos;
			var lFrInfos	: BmpFrameInfos;
			var lCurFr		: int;
			var lMtrx		: Matrix;
			var lFromTime	: int;
			var lGoto		: Function;
			var lCurrent	: Function;
			
			if ( lBaseMtrx != null) {
				if ( pQualityMtrx != null) lBaseMtrx.concat( pQualityMtrx);
				
				pQualityMtrx = lBaseMtrx;
			}
			
			lInfos	= new BmpInfos( _pixelSnap, _isSmooth, pQualityMtrx);
			
			if( pQualityMtrx != null){
				lMtrx = pTarget.transform.matrix;
				lMtrx.concat( pQualityMtrx);
				pTarget.transform.matrix = lMtrx;
			}
			
			BitmapMovieClipMgr.addBmpInfos( _bmpId, lInfos);
			
			lFromTime				= getTimer();
			lTotal					= getTotalFramesMethod( pTarget)();
			lGoto					= getGotoAndStopFrameMethod( pTarget);
			lCurrent				= getCurrentFrameMethod( pTarget);
			MySystem.stage.quality	= StageQuality.BEST;
			
			do{
				lCurFr		= Math.max( lCurrent(), 1);
				lFrInfos	= generateFrame( pTarget);
				
				for ( lCtr = 0 ; lCtr < pStep && lCurFr + lCtr <= lTotal ; lCtr++) lInfos.addFrameInfos( lCurFr + lCtr, lFrInfos);
				
				if( lCurFr + pStep <= lTotal) lGoto( lCurFr + pStep);
				else {
					if ( pTarget is INotifyBitmapGenerate) ( pTarget as INotifyBitmapGenerate).onBitmapGenerateComplete( _bmpId);
					
					break;
				}
				
				if( pINotifyBmpGen != null && getTimer() - lFromTime > MAX_GEN_TIME){
					startAsyncGenerate( pINotifyBmpGen, pTarget, pStep);
					
					MySystem.stage.quality	= lQual;
					
					return false;
				}
			}while( true);
			
			MySystem.stage.quality	= lQual;
			
			//MySystem.traceDebug( "BitmapMovieClip::generate end " + _bmpId);
			
			return true;
		}
		
		/**
		 * on amorce la génération bitmap asynchrone à partir de l'endroit où la tête de lecture a été laissée sur le clip à parser
		 * @param	pINotifyBmpGen	instance qui reçoit la notification de fin de génération bitmap asynchrone
		 * @param	pTarget			clip dont on génère le contenu bitmap ; la position de sa tête de lecture indique la prochaine frame à traiter
		 * @param	pStep			pas d'avancement du parsing bitmap
		 */
		protected function startAsyncGenerate( pINotifyBmpGen : INotifyBitmapGenerate, pTarget : MovieClip, pStep : int) : void {
			asyncGenTarget		= pTarget;
			asyncGenCallBack	= pINotifyBmpGen;
			asyncGenStep		= pStep;
			
			addEventListener( Event.ENTER_FRAME, doAsyncGenerate);
		}
		
		/**
		 * on effectue le traitement asynchrone de génération bitmap du clip temporisé dans ::asyncGenTarget
		 * @param	pE	évènement d'itération
		 */
		protected function doAsyncGenerate( pE : Event) : void {
			var lFromTime	: int				= getTimer();
			var lInfos		: BmpInfos			= BitmapMovieClipMgr.getBmpInfos( _bmpId);
			var lQual		: String			= MySystem.stage.quality;
			var lCurrent	: Function			= getCurrentFrameMethod( asyncGenTarget);
			var lGoto		: Function			= getGotoAndStopFrameMethod( asyncGenTarget);
			var lTotal		: int				= getTotalFramesMethod( asyncGenTarget)();
			var lCurFr		: int;
			var lFrInfos	: BmpFrameInfos;
			var lCtr		: int;
			
			MySystem.stage.quality	= StageQuality.BEST;
			
			do {
				lCurFr		= Math.max( lCurrent(), 1);
				lFrInfos	= generateFrame( asyncGenTarget);
				
				for ( lCtr = 0 ; lCtr < asyncGenStep && lCurFr + lCtr <= lTotal ; lCtr++) lInfos.addFrameInfos( lCurFr + lCtr, lFrInfos);
				
				if( lCurFr + asyncGenStep <= lTotal) lGoto( lCurFr + asyncGenStep);
				else {
					//MySystem.traceDebug( "BitmapMovieClip::doAsyncGenerate end " + _bmpId);
					
					removeEventListener( Event.ENTER_FRAME, doAsyncGenerate);
					
					asyncGenCallBack.onBitmapGenerateComplete( _bmpId);
					
					if ( asyncGenTarget is INotifyBitmapGenerate) ( asyncGenTarget as INotifyBitmapGenerate).onBitmapGenerateComplete( _bmpId);
					
					asyncGenTarget		= null;
					asyncGenCallBack	= null;
					
					break;
				}
				
				if( getTimer() - lFromTime > MAX_GEN_TIME) break;
			}while ( true);
			
			MySystem.stage.quality	= lQual;
		}
		
		/**
		 * on clone un modèle de movie clip qui sert à générer une suite de bitmaps
		 * @param	pModel	movie clip modèle qui setr à la génération bitmap
		 * @return	clone du modèle, positionné à la même frame et avec la même matrice de transformation ; on retourne le modèle si on n'a pas pu le cloner (si le modèle n'a pas de classe spécifique permettant de le dupliquer)
		 */
		protected function cloneModel( pModel : MovieClip) : MovieClip {
			var lClone	: MovieClip;
			
			if ( isModelClone || Object( pModel).constructor == MovieClip) return pModel;
			else {
				lClone = MovieClip( new ( Class( Object( pModel).constructor))());
				lClone.transform.matrix = pModel.transform.matrix;
				
				getGotoAndStopFrameMethod( lClone)( getCurrentFrameMethod( pModel)());
				
				if( lClone is BitmapMovieClip) lClone.removeEventListener( Event.ADDED_TO_STAGE, BitmapMovieClip( lClone).onAddedToStage);
				
				return lClone;
			}
		}
		
		/**
		 * on parcourt un objet graphique en profondeur pour adapter les filtres bitmaps rencontrés au scale précisé
		 * @param	pDisp	objet graphique à parcourir en profondeur
		 * @param	pScale	scale à appliquer
		 */
		protected function recursiveAdjustFiltersScaling( pDisp : DisplayObject, pScale : Number) : void {
			var lI		: int;
			var lCont	: DisplayObjectContainer;
			
			if ( pDisp is DisplayObjectContainer) {
				lCont = DisplayObjectContainer( pDisp);
				
				for ( lI = 0 ; lI < lCont.numChildren ; lI++) recursiveAdjustFiltersScaling( lCont.getChildAt( lI), pScale);
			}
			
			adjustFiltersScaling( pDisp, pScale);
		}
		
		/**
		 * on ajuste les filtres d'un objet graphique à un scale défini
		 * @param	pDisp	objet graphique dont on ajuste les filtres
		 * @param	pScale	scale à appliquer
		 */
		protected function adjustFiltersScaling( pDisp : DisplayObject, pScale : Number) : void {
			var lFilters	: Array			= new Array();
			var lFilter		: Object;
			var lI			: int;
			
			if( pDisp.filters && pDisp.filters.length > 0){
				for( lI = 0 ; lI < pDisp.filters.length ; lI++) {
					lFilter = pDisp.filters[ lI];
					
					switch( lFilter.constructor) {
						case BevelFilter:
						case DropShadowFilter:
						case GradientBevelFilter:
						case GradientGlowFilter:
							lFilter.distance *= pScale;
						case BlurFilter:
						case GlowFilter:
							lFilter.blurX *= pScale;
							lFilter.blurY *= pScale;
							break;
						default:
							break;
					}
					
					lFilters.push( lFilter);
				}
			}
			
			pDisp.filters = lFilters;
		}
		
		/**
		 * on génère la frame courrante en bitmap et on retourne ses infos de bitmap de frame
		 * @param	pTarget		movie clip dont on parse le contenu
		 * @return	infos bitmap de la frame générée
		 */
		protected function generateFrame( pTarget : MovieClip) : BmpFrameInfos {
			var lTarget		: MovieClip		= cloneModel( pTarget);
			var lCadre		: DisplayObject	= pTarget.getChildByName( CADRE_NAME);
			var lZone		: Rectangle;
			var lMtrx		: Matrix;
			var lBmp		: BitmapData;
			var lW			: int;
			var lH			: int;
			
			if( lCadre != null) lZone = lCadre.getBounds( pTarget);
			else lZone = pTarget.getBounds( pTarget);
			
			lZone.width		= Math.ceil( lZone.width);
			lZone.height	= Math.ceil( lZone.height);
			lZone.x			= Math.floor( lZone.x);
			lZone.y			= Math.floor( lZone.y);
			
			if( lZone.width > 0 && lZone.height > 0){
				if( _isStabil){
					lZone.width		+= STABIL_OFFSET * 2;
					lZone.height	+= STABIL_OFFSET * 2;
					lZone.x			-= STABIL_OFFSET;
					lZone.y			-= STABIL_OFFSET;
				}
				
				lMtrx		= pTarget.transform.matrix;
				lW			= Math.max( 1, Math.abs( Math.round( lZone.width * pTarget.scaleX)));
				lH			= Math.max( 1, Math.abs( Math.round( lZone.height * pTarget.scaleY)));
				lMtrx.tx	= Math.round( -lZone.x * pTarget.scaleX);
				lMtrx.ty	= Math.round( -lZone.y * pTarget.scaleY);
				lBmp		= new BitmapData( lW, lH, true, 0x00000000);
				
				if ( lTarget != pTarget) recursiveAdjustFiltersScaling( lTarget, lTarget.transform.matrix.a);
				
				lBmp.draw( lTarget, lMtrx/*, null, null, null, _isSmooth*/);
				
				return new BmpFrameInfos(
					lBmp,
					-lMtrx.tx,
					-lMtrx.ty
				);
			}else{
				return new BmpFrameInfos(
					new BitmapData( 1, 1, true, 0x00000000),
					0,
					0
				);
			}
		}
		
		/**
		 * on set l'id de bitmap movieclip ; on effectue une vérification sur le formalisme de l'id pour regarder si quelque chose n'existe pas déjà avec la notation "getQualifiedClassName"
		 * @param	pId	identifiant de bitmap à rendre, ou null si on utilise l'identifiant de liaison du symbole
		 */
		protected function setBmpId( pId : String) : void {
			var lId2	: String;
			
			if( pId == null) _bmpId = getQualifiedClassName( this);
			else{
				if( ! BitmapMovieClipMgr.isBmpInfos( pId)){
					lId2 = UtilsMovieClip.fromClassIdToQualifiedClassName( pId);
					
					if( BitmapMovieClipMgr.isBmpInfos( lId2)) _bmpId = lId2;
					else _bmpId = pId;
				}else _bmpId = pId;
			}
		}
	}
}