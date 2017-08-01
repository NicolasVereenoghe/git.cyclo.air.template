package net.cyclo.effect {
	import flash.display.Sprite;
	import flash.geom.Point;
	import net.cyclo.shell.MySystem;
	import net.cyclo.utils.UtilsMaths;
	import net.cyclo.utils.UtilsMovieClip;
	
	/**
	 * fractal en spiral
	 * 
	 * @author	nico
	 */
	public class MyFractalMgr extends Sprite {
		/** angle d'ouverture de la base du motif supposé par défaut, en rad */
		protected var DEFAULT_ANGLE									: Number									= Math.PI / 3;
		/** nombre de motif par défaut dans un anneau de spirale */
		protected var DEFAULT_NB_MOTIF								: int										= 2;
		
		/** écart réel d'étapes vers l'intérieur max de rendu (on ignore au-delà) avec l'étape courante rendu à 100% */
		protected var DELT_STEP_MIN									: Number									= -15;
		/** écart réel d'étapes vers l'extérieur max de rendu (on ignore au-delà) avec l'étape courante rendu à 100% */
		protected var DELT_STEP_MAX									: Number									= 10;
		
		/** distance min dans repère général entre origine et un motif d'anneau en dessous de laquelle on ignore le rendu */
		protected var MIN_DIST										: Number									= .1;
		/** distance max dans repère général entre origine et un motif d'anneau au dessus de laquelle on ignore le rendu */
		protected var MAX_DIST										: Number									= 600;
		
		/**
		 * vitesse de rotation à taux plein à rad par itération de rendu avec la méthode ::doFrame ; définie pour le motif non applati car relative à l'angle d'ouverture de base
		 * on crée l'illusion de rotation car la progression d'étape, soit le zoom, génère un motif à une position tournée de l'angle d'ouverture déformé de la base
		 */
		protected var ROT_SPEED										: Number									= Math.PI / 30;
		
		/** tracé de spirale dans le sens des aiguilles d'une montre (true) ou invers (fale) : TODO : /!\ vers extérieur ou intérieur ? :) */
		protected var IS_CW											: Boolean									= true;
		
		/** true pour maintenir l'étape courante qui est zoomée à 100% à la même orientation si on change l'angle d'ouverture : on applique un offset de rotation aux anneaux par rapport à leur orientation naturelle d'étape réelle */
		protected var USE_SMOOTH_TRANS_ANGLE_OFFSET					: Boolean									= true;
		
		/** distance du sommet des motifs les plus éloignés, uniquement défini si on utilise le verrou de position de rendu par rapport à la position du somment du motif le plus éloigné lors de l'init ; -1 si non défini */
		protected var MAX_LOCKED_STEP_TOP_DIST						: Number									= -1;
		/** step de motif verrouillé ; uniquement utilisé si ::MAX_LOCKED_STEP_TOP_DIST est défini */
		protected var MAX_LOCKED_STEP								: int										= 0;
		/** orientation en deg du step de motif verrouillé */
		protected var MAX_LOCKED_STEP_ROT							: Number									= 0;
		
		/** identifiant d'asset du motif */
		protected var _ASSET_ID										: String									= "motif_tri";
		/** identifiant d'asset du motif alternatif */
		protected var _ASSET_ALT_ID									: String									= "motif_tri_alt";
		/** probabilité d'avoir un anneau de motifs alternatifs */
		protected var _ALT_RATE										: Number									= .05;
		
		/** taille de la base du motif non déformé */
		protected var BASE_SIZE										: Number									= 100;
		
		/** angle d'ouverture en rad de la base du motif non déformé */
		protected var BASE_A										: Number									= Math.PI / 3;
		
		/** tangeante de l'angle d'ouverture de la base du motif non déformé */
		protected var TAN_A											: Number									= 0;
		
		/** delta d'angle pour arriver à la prochaine étape de progression de zoom de fade en bordure de rendu ; valeur donnée pour le motif avec angle d'ouverture non déformé */
		protected var D_A_APPEAR									: Number									= .5237;
		
		/** delta d'étape de proression de zoom avec fade des anneaux en bordure ; valeur relative à l'angle d'ouverture, recalculée si changement */
		protected var dStepAppear									: Number									= -1;
		
		/** liste d'anneaux de motifs affichés ; par ordre croissant de scale (congruant distance du motif par rapport à l'origine) */
		protected var rings											: Array										= null;
		
		/** étape réelle qui est mise à 100% */
		protected var _curStep										: Number									= 0;
		
		/** écart réelle d'étapes vers les anneaux intérieurs avec l'étape rendue à 100% */
		protected var dStepMin										: Number									= 0;
		/** écart réelle d'étapes vers les anneaux extérieurs avec l'étape rendue à 100% */
		protected var dStepMax										: Number									= 0;
		
		/** coef de scale relatif à langle d'ouverture, élevé à la puissance de l'étape relative de rendu d'un anneau pour déterminer son scale (congruant distance motif à l'origine) */
		protected var scaleCoef										: Number									= -1;
		
		/** distance de l'étape réelle zoomée à 100% par rapport à l'origine ; on place les motifs dans les anneaux à cette distance, puis on scale l'anneau */
		protected var _dist0										: Number									= -1;
		/** liste de vecteur unitaires directeurs de la position en étoile des motifs autour d'un anneau (pré-calculés pour éviter de faire trop de Math.cos | Math.sin) ; indexé par indice de motif dans l'anneau (indice 0 toujours en 0°) */
		protected var _motifVectors0								: Array										= null;
		/** scale en x à appliquer aux motifs pour déformer le motif pour adapter l'angle d'ouverture de sa base */
		protected var _flattenCoef									: Number									= -1;
		/** nombre de motifs dans les anneaux du fractal à spirale */
		protected var _nbMotif										: int										= -1;
		/** angle d'ouverture de la base du motif déformé en rad */
		protected var _angle										: Number									= -1;
		
		/** écart d'angle en deg qu'il faut ajouter à la rotation d'anneau pour compenser le changement d'angle d'ouverture du motif, tout en gardant l'étape qui est rendue à 100% au même angle d'orientation ; propriété utilisée uniquement si ::USE_SMOOTH_TRANS_ANGLE_OFFSET défini à true lors de l'init */
		protected var angleOffset									: Number									= 0;
		
		public function MyFractalMgr() {
			super();
			
			rings = new Array();
		}
		
		/**
		 * initialisation et premier rendu de fractal spiral
		 * @param	pA							angle d'ouverture à rendre sur le motif (par scale) en rad ; -1 pour valeur par défaut ::DEFAULT_ANGLE
		 * @param	pNbMotif					nombre de motifs par anneau ; -1 pour valeur par défaut ::DEFAULT_NB_MOTIF
		 * @param	pIsCW						true pour une spirale dans le sens des aiguilles d'une montre
		 * @param	pMinDist					distance min de rendu des motifs par rapport à l'origine, en dessous on ignore ; -1 pour valeur par défaut ::MIN_DIST
		 * @param	pMaxDist					distance max de rendu des motifs par rapport à l'origine, au dessus on ignore ; -1 pour valeur par défaut ::MAX_DIST
		 * @param	pAssetId					identifiant d'asset du motif ; null pour valeur par défaut ::_ASSET_ID
		 * @param	pAssetAltId					identifiant alternatif de motif ; null pour valeur par défaut ::_ASSET_ALT_ID
		 * @param	pAltRate					taux de probabilité de générer un anneau de motifs alternatifs ; -1 pour valeur par défaut ::_ALT_RATE
		 * @param	pBaseSize					taille de la base du motif ; -1 pour valeur par défaut ::BASE_SIZE
		 * @param	pBaseA						angle d'ouverture du motif non déformé en rad ; -1 pour valeur par défaut ::BASE_A
		 * @param	pRotSpeed					vitesse de rotation à taux plein en rad par frame relative à l'ouverture naturelle du motif de base ; utilisé si lors du rendu de frame (::doFrame) on ne précise pas d'étape réelle de rendu forcée ; 0 pour valeur par défaut ::ROT_SPEED
		 * @param	pDAAppear					delta d'angle en rad de fade du motif en approche des limites min ou max ; -1 pour valeur par défaut ::D_A_APPEAR
		 * @param	pStepInitOffset				étape de rendu initial
		 * @param	pUseSmoothTransAngleOffset	true pour générer la transition interpolée d'angle sans faire tourner l'anneau avec motif à 100%
		 * @param	pIgnoreDeltMin				true pour ignorer la limite de nombre d'étapes depuis la distance 0, laisser false pour garder une borne basse en nombre d'étapes
		 * @param	pLockOnCurMaxStep			true pour verrouiller le rendu par rapport à la distance du sommet des motifs les plus éloignés (position et rotation verrouillées), laisser false pour un rendu en itération libre en niveau de zoom
		 */
		public function init( pA : Number = -1, pNbMotif : int = -1, pIsCW : Boolean = true, pMinDist : Number = -1, pMaxDist : Number = -1, pAssetId : String = null, pAssetAltId : String = null, pAltRate : Number = -1, pBaseSize : Number = -1, pBaseA : Number = 0, pRotSpeed : Number = 0, pDAAppear : Number = -1, pStepInitOffset : Number = 0, pUseSmoothTransAngleOffset : Boolean = true, pIgnoreDeltMin : Boolean = false, pLockOnCurMaxStep : Boolean = false) : void {
			var lRing	: MyFractalRing;
			
			if ( pMinDist > 0) MIN_DIST = pMinDist;
			if ( pMaxDist > 0) MAX_DIST = pMaxDist;
			if ( pAssetId != null) _ASSET_ID = pAssetId;
			if ( pAssetAltId != null) _ASSET_ALT_ID = pAssetAltId;
			if ( pAltRate >= 0) _ALT_RATE = pAltRate;
			if ( pBaseSize > 0) BASE_SIZE = pBaseSize;
			if ( pBaseA != 0) BASE_A = pBaseA;
			if ( pRotSpeed != 0) ROT_SPEED = pRotSpeed;
			if ( pDAAppear > -1) D_A_APPEAR = pDAAppear;
			if ( pIgnoreDeltMin) DELT_STEP_MIN = Number.NEGATIVE_INFINITY;
			
			TAN_A = Math.tan( BASE_A);
			
			if ( pNbMotif > 0) _nbMotif = pNbMotif;
			else _nbMotif = DEFAULT_NB_MOTIF;
			
			if ( pA > 0) _angle = pA;
			else _angle = DEFAULT_ANGLE;
			
			IS_CW							= pIsCW;
			_curStep						= pStepInitOffset;
			USE_SMOOTH_TRANS_ANGLE_OFFSET	= pUseSmoothTransAngleOffset;
			
			updateAngleProperties();
			updateNbMotifProperties();
			
			buildRings();
			
			if ( pLockOnCurMaxStep) {
				lRing						= ( rings[ rings.length - 1] as MyFractalRing);
				MAX_LOCKED_STEP_TOP_DIST	= lRing.scaleX * ( _dist0 + Math.tan( _angle) * BASE_SIZE / 2);
				MAX_LOCKED_STEP				= lRing.relativeStep;
				MAX_LOCKED_STEP_ROT			= lRing.rotation;
			}
		}
		
		/**
		 * destruction du fractal spiral
		 */
		public function destroy() : void {
			var lRing	: MyFractalRing;
			var lI		: int;
			
			for ( lI = 0 ; lI < rings.length ; lI++) {
				lRing = rings[ lI] as MyFractalRing;
				
				lRing.destroy();
				
				UtilsMovieClip.clearFromParent( lRing);
			}
			
			rings = null;
		}
		
		/**
		 * accès à la liste des vecteurs directeurs unitaires des positions de motifs autour des anneaux
		 * @return	liste de vecteur unitaire, indexé par indice de motif dans l'anneau (indice 0 toujours en 0°)
		 */
		public function get motifVectors0() : Array { return _motifVectors0; }
		
		/**
		 * scale d'applatissement pour adapter l'angle d'ouverture des motifs
		 * @return	scale d'applatissement de motif
		 */
		public function get flattenCoef() : Number { return _flattenCoef; }
		
		/**
		 * identifiant d'asset de motif
		 * @return	identifiant d'asset
		 */
		public function get ASSET_ID() : String { return _ASSET_ID; }
		
		/**
		 * identifiant d'asset de motif alternatif
		 * @return	identifiant d'asset
		 */
		public function get ASSET_ALT_ID() : String { return _ASSET_ALT_ID; }
		
		/**
		 * probabilité de tirage d'anneau avec motif alternatif
		 * @return	probabilité [ 0 .. 1]
		 */
		public function get ALT_RATE() : Number { return _ALT_RATE; }
		
		/**
		 * nombre de motifs par anneaux
		 * @return	nombre de motifs [1 .. n[
		 */
		public function get nbMotif() : int { return _nbMotif; }
		
		/**
		 * angle d'ouverture du motif déformé
		 * @return	angle d'ouverture en rad
		 */
		public function get angle() : Number { return _angle; }
		
		/**
		 * distance à l'origine des motifs d'anneau de l'étape réelle théorique courante zoomée à 100%
		 * @return	distance à l'origine dans repère général
		 */
		public function get dist0() : Number { return _dist0; }
		
		/**
		 * première étape effective entière à être rendu depuis le bord intérieur
		 * @return	étape entière effective de la suite d'anneaux
		 */
		public function get firstStep() : int { return Math.ceil( _curStep + dStepMin); }
		
		/**
		 * nombre d'anneaux de la suite à être rendus entre les bords intérieur et extérieur du niveau de zoom actuel
		 * @return	nombre d'anneaux de la suite à être rendus
		 */
		public function get nbSteps() : int { return Math.floor( _curStep + dStepMax) - Math.ceil( _curStep + dStepMin); }
		
		/**
		 * on change le nombre de motifs qu'il y a sur les anneaux
		 * @param	pNb	nouveau nombre de motifs
		 */
		public function updateNbMotif( pNb : int) : void {
			_nbMotif = pNb;
			
			updateNbMotifProperties();
			
			refreshNbMotif();
		}
		
		/**
		 * on effctue le rendu de fractal en spirale
		 * @param	pSpRate			taux de vitese de rotation [ 0 .. 1 .. ?[ (vitesse relative à taux plein définie lors de l'init en rad par itération de rendu) : ignoré
		 * @param	pAngle			angle d'ouverture de la base du motif en rad ; 0 <=> garder courant
		 * @param	pIsForcedStep	on force le zoom à 100% à cette étape réelle (true) et dans ce cas pSpRate désigne cette étape de rendu réelle ; ou laisser false pour piloter le rendu par la vitesse
		 * @param	pMaxDist		on force et met à jour la distance max de rendu de la base du dernier plus motif d'anneau ; laisser -1 pour ne rien changer au contrôle par défaut de ::MAX_DIST
		 */
		public function doFrame( pSpRate : Number = 1, pAngle : Number = 0, pIsForcedStep : Boolean = false, pMaxDist : Number = -1) : void {
			var lUpdateMotif	: Boolean	= false;
			
			if ( MAX_LOCKED_STEP_TOP_DIST <= 0) {
				if ( pAngle != 0 && pAngle != _angle) {
					if ( pMaxDist > 0) MAX_DIST = pMaxDist;
					
					lUpdateMotif = true;
					
					updateAngle( pAngle);
				}else if ( pMaxDist > 0 && pMaxDist != MAX_DIST) updateMaxDist( pMaxDist);
				
				if ( pIsForcedStep) _curStep = pSpRate;
				else _curStep += pSpRate * ROT_SPEED / BASE_A;
				
				if( USE_SMOOTH_TRANS_ANGLE_OFFSET){
					if ( IS_CW) angleOffset = ( _curStep * ( BASE_A - pAngle) * UtilsMaths.COEF_RAD_2_DEG) % 360;
					else angleOffset = ( _curStep * ( pAngle - BASE_A) * UtilsMaths.COEF_RAD_2_DEG) % 360;
				}
			}else {
				// traitement spé de verrou de motif à distance max fixe
				if ( pAngle != 0 && pAngle != _angle) {
					lUpdateMotif = true;
					
					updateAngleTopMaxDistLocked( pAngle);
				}
			}
			
			refreshRingsStep( lUpdateMotif);
		}
		
		/**
		 * on change l'angle d'ouverture de la base du motif pour le mode de rendu verrouillé en distance max du sommet du motif max à l'init
		 * pas de rendu, on paramètre pour l'appel à ::refreshRingsStep
		 * config l'étape de zoom à avoir pour avoir ce motif verrouilé pour ce nouvel angle
		 * @param	pAngle	nouvel angle d'ouverture de la base en rad
		 */
		protected function updateAngleTopMaxDistLocked( pAngle : Number) : void {
			var lTanA	: Number	= Math.tan( pAngle);
			var lLnS	: Number;
			
			_angle			= pAngle;
			_dist0			= BASE_SIZE / ( 2 * lTanA);
			scaleCoef		= 1 / Math.cos( _angle);
			lLnS			= Math.log( scaleCoef);
			_flattenCoef	= lTanA / TAN_A;
			dStepAppear		= D_A_APPEAR / _angle;
			_curStep		= MAX_LOCKED_STEP - ( Math.log( MAX_LOCKED_STEP_TOP_DIST / ( _dist0 + lTanA * BASE_SIZE / 2)) / lLnS);
			dStepMin		= Math.max( Math.log( MIN_DIST / _dist0) / lLnS, DELT_STEP_MIN);
			dStepMax		= Math.ceil( MAX_LOCKED_STEP - _curStep); // round / floor ?
			
			if ( IS_CW) angleOffset = MAX_LOCKED_STEP_ROT - pAngle * UtilsMaths.COEF_RAD_2_DEG * MAX_LOCKED_STEP;
			else angleOffset = MAX_LOCKED_STEP_ROT + pAngle * UtilsMaths.COEF_RAD_2_DEG * MAX_LOCKED_STEP;
		}
		
		/**
		 * on effectue le rendu de la suite d'anneaux entre les bords min et max du niveau de zoom actuel
		 * on retire les anneaux hors borne par rapport au niveau de zoom
		 * on ajoute les anneaux manquants dans le niveau de zoom actuel
		 * @param	pIsUpdateMotif	true si l'angle d'ouverture du motif a changé, pour recaluler les valeurs dépendantes ; false si identique à dernière itération
		 */
		protected function refreshRingsStep( pIsUpdateMotif : Boolean) : void {
			var lMin	: int			= Math.ceil( _curStep + dStepMin);
			var lMax	: int			= Math.floor( _curStep + dStepMax);
			var lDStep	: int			= lMin - ( rings[ 0] as MyFractalRing).relativeStep;
			var lADeg	: Number		= _angle * UtilsMaths.COEF_RAD_2_DEG;
			var lRing	: MyFractalRing;
			var lI		: int;
			var lIBeg	: int;
			var lIEnd	: int;
			
			if ( lDStep > 0) {
				for ( lI = 0 ; lI < lDStep ; lI++){
					lRing	= rings.shift() as MyFractalRing;
					
					lRing.destroy();
					
					UtilsMovieClip.clearFromParent( lRing);
				}
				
				lIBeg	= 0;
			}else if ( lDStep < 0) {
				for ( lI = 0 ; lI > lDStep ; lI--) {
					lRing	= instanciateRingAt( 0);
					
					rings.unshift( lRing);
					
					lRing.init( this, lMin - lDStep + lI - 1);
					
					if ( IS_CW) lRing.rotation = ( angleOffset + lADeg * lRing.relativeStep) % 360;
					else lRing.rotation = ( angleOffset - lADeg * lRing.relativeStep) % 360;
					
					lRing.scaleX = lRing.scaleY = Math.pow( scaleCoef, lRing.relativeStep - _curStep);
					updateRingAlpha( lRing);
				}
				
				lIBeg = -lDStep;
			}else lIBeg = 0;
			
			lDStep = ( rings[ rings.length - 1] as MyFractalRing).relativeStep - lMax;
			if ( lDStep > 0) {
				for ( lI = 0 ; lI < lDStep ; lI++) {
					lRing	= rings.pop() as MyFractalRing;
					
					lRing.destroy();
					
					UtilsMovieClip.clearFromParent( lRing);
				}
				
				lIEnd = rings.length - 1;
			}else if ( lDStep < 0) {
				for ( lI = 0 ; lI > lDStep ; lI--) {
					lRing	= instanciateRingAt();
					
					rings.push( lRing);
					
					lRing.init( this, lMax + lDStep - lI + 1);
					
					if ( IS_CW) lRing.rotation = ( angleOffset + lADeg * lRing.relativeStep) % 360;
					else lRing.rotation = ( angleOffset - lADeg * lRing.relativeStep) % 360;
					
					lRing.scaleX = lRing.scaleY = Math.pow( scaleCoef, lRing.relativeStep - _curStep);
					updateRingAlpha( lRing);
				}
				
				lIEnd = rings.length + lDStep - 1;
			}else lIEnd = rings.length - 1;
			
			for ( lI = lIBeg ; lI <= lIEnd ; lI++) {
				lRing = rings[ lI] as MyFractalRing;
				
				lRing.scaleX = lRing.scaleY = Math.pow( scaleCoef, lRing.relativeStep - _curStep);
				updateRingAlpha( lRing);
				
				if ( pIsUpdateMotif) {
					if ( IS_CW) lRing.rotation = ( angleOffset + lADeg * lRing.relativeStep) % 360;
					else lRing.rotation = ( angleOffset - lADeg * lRing.relativeStep) % 360;
					
					lRing.refreshMotif();
				}
			}
		}
		
		/**
		 * on dispatche le changement de nombre de motifs par anneau à tous les anneaux de la suite
		 */
		protected function refreshNbMotif() : void {
			var lI	: int;
			
			for ( lI = 0 ; lI < rings.length ; lI++) ( rings[ lI] as MyFractalRing).refreshNbMotif();
		}
		
		/**
		 * on met à jour l'alpha d'un anneau de la suite, pour gérer l'effet de fade en bordure (ou restituer l'alpha en plein)
		 * @param	pRing	anneau dont on met à jour l'alpha
		 */
		protected function updateRingAlpha( pRing : MyFractalRing) : void {
			var lStep	: Number	= pRing.relativeStep - _curStep;
			
			if ( lStep < dStepMin + dStepAppear) pRing.alpha = ( lStep - dStepMin) / dStepAppear;
			else if( lStep > dStepMax - dStepAppear) pRing.alpha = 1 - ( lStep - dStepMax + dStepAppear) / dStepAppear;
			else if ( pRing.alpha != 1) pRing.alpha = 1;
		}
		
		/**
		 * on effectue la mise à jour d'angle d'ouverture de la base du motif ; cas "normal" : l'étape en cours de rendu ne change pas
		 * @param	pAngle	nouvel angle d'ouverture en rad
		 */
		protected function updateAngle( pAngle : Number) : void {
			_angle = pAngle;
			
			updateAngleProperties();
		}
		
		/**
		 * mise à jour de propriétés pré-calculée depuis l'angle d'ouverturer de la base du motif ; cas "normal" : l'étape en cours de rendu ne change pas
		 */
		protected function updateAngleProperties() : void {
			var lTanA	: Number	= Math.tan( _angle);
			var lLnS	: Number;
			
			_dist0			= BASE_SIZE / ( 2 * lTanA);
			scaleCoef		= 1 / Math.cos( _angle);
			lLnS			= Math.log( scaleCoef);
			_flattenCoef	= lTanA / TAN_A;
			dStepMin		= Math.max( Math.log( MIN_DIST / _dist0) / lLnS, DELT_STEP_MIN);
			dStepMax		= Math.min( Math.log( MAX_DIST / _dist0) / lLnS, DELT_STEP_MAX);
			dStepAppear		= D_A_APPEAR / _angle;
		}
		
		/**
		 * on met à jour la distance max de motif d'anneau à l'origine dans le repère général sur le bord extérieur
		 * on recalcule l'écart d'étapes réelles entre le bord extérieur et l'étape zoomée à 100%
		 * @param	pMaxDist	distance origine motif max
		 */
		protected function updateMaxDist( pMaxDist : Number) : void {
			MAX_DIST		= pMaxDist;
			dStepMax		= Math.min( Math.log( pMaxDist / _dist0) / Math.log( scaleCoef), DELT_STEP_MAX);
		}
		
		/**
		 * on recalcule la pile de vecteur directeur unitaire des motifs sur leurs anneaux suite à un changement de nombre de motif
		 */
		protected function updateNbMotifProperties() : void {
			var lI	: int;
			var lA	: Number;
			
			_motifVectors0	= new Array();
			
			for ( lI = 0 ; lI < _nbMotif ; lI++) {
				lA = lI * 2 * Math.PI / _nbMotif;
				_motifVectors0.push( new Point( Math.cos( lA), Math.sin( lA)));
			}
		}
		
		/**
		 * on construit la première vu du fractal à la suite de l'intialisation
		 */
		protected function buildRings() : void {
			var lI		: int			= Math.ceil( _curStep + dStepMin);
			var lMax	: int			= Math.floor( _curStep + dStepMax);
			var lADeg	: Number		= _angle * UtilsMaths.COEF_RAD_2_DEG;
			var lRing	: MyFractalRing;
			
			for ( ; lI <= lMax ; lI++) {
				lRing = instanciateRingAt();
				
				rings.push( lRing);
				
				lRing.init( this, lI);
				
				if ( IS_CW) lRing.rotation = ( angleOffset + lADeg * lI) % 360;
				else lRing.rotation = ( angleOffset - lADeg * lI) % 360;
				
				lRing.scaleX = lRing.scaleY = Math.pow( scaleCoef, lI - _curStep);
				updateRingAlpha( lRing);
			}
		}
		
		/**
		 * on instancie et pose un anneau de pétales
		 * @param	pIndex	0 pour désigner l'anneau central, -1 non défini pour les autres anneaux ajoutés successivement
		 * @return	instance créée et posée
		 */
		protected function instanciateRingAt( pIndex : int = -1) : MyFractalRing {
			if ( pIndex > -1) return addChildAt( new MyFractalRing(), pIndex) as MyFractalRing;
			else return addChild( new MyFractalRing()) as MyFractalRing;
		}
	}
}