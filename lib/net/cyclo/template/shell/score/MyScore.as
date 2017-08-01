package net.cyclo.template.shell.score {
	
	/**
	 * descripteur de score obtenu en fin de partie
	 * @author	nico
	 */
	public class MyScore {
		/** représentation par valeur numérique de score obtenu en fin de partie */
		protected var _score						: int						= -1;
		
		/**
		 * constructeur
		 * @param	pScore	représentation par valeur numérique de score obtenu en fin de partie
		 */
		public function MyScore( pScore : int) { _score = pScore; }
		
		/**
		 * on récupère la valeur numérique du score obtenu en fin de partie
		 * @return	valeur de score
		 */
		public function get score() : int { return _score;}
	}
}