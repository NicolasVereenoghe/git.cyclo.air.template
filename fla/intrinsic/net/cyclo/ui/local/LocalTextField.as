package net.cyclo.ui.local {
	import flash.display.Sprite;
	
	public class LocalTextField extends Sprite {
		[Inspectable(name="1 nom d'instance de TextField géré",type="String",defaultValue="")]
		public var targetName				: String		= "";
		
		[Inspectable(name = "2 id de localisation", type = "String", defaultValue = "")]
		public var localId					: String		= "";
		
		[Inspectable(name = "3 html ?", type = "Boolean", defaultValue = false)]
		public var isHtml					: Boolean		= false;
		
		[Inspectable(name = "4 force lang indice", type = "Number", defaultValue = -1)]
		public var forceLangInd				: int			= -1;
		
		[Inspectable(name = "5 autoSize", type = "Boolean", defaultValue = false)]
		public var autoSize					: Boolean		= false;
	}
}