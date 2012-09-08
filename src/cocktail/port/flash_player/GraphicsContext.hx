package cocktail.port.flash_player;

import cocktail.core.geom.Matrix;
import cocktail.core.graphics.AbstractGraphicsContext;
import cocktail.core.layer.LayerRenderer;
import cocktail.port.NativeBitmapData;
import cocktail.port.NativeElement;
import flash.display.Bitmap;
import cocktail.core.geom.GeomData;
import cocktail.core.css.CSSData;
import flash.display.BitmapData;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
 * The flash implementation of the graphics context. Use native
 * flash Sprite and Bitmap
 * 
 * @author Yannick DOMINGUEZ
 */
class GraphicsContext extends AbstractGraphicsContext
{
	/**
	 * The native flash BitmapData
	 */
	private var _nativeBitmap:Bitmap;
	
	/**
	 * The native flash Sprite, used a native
	 * layer
	 */
	private var _nativeLayer:Sprite;
	
	/**
	 * A container for the children layer of
	 * this GraphicContext. A container is necessary
	 * so that tha native Bitmap is always below the children
	 * layer
	 */
	private var _childrenNativeLayer:Sprite;
	
	/**
	 * the current width of the BitmapData
	 */
	private var _width:Int;
	
	/**
	 * the current height of the BitmapData
	 */
	private var _height:Int;
	
	/**
	 * A flash native rectanlge object, which
	 * is re-used for each bitmap drawing
	 */
	private var _flashRectangle:Rectangle;
	
	/**
	 * Same as above for flash native point
	 */
	private var _flashPoint:Point;
	
	/**
	 * Same as above for flash Matrix
	 */
	private var _flashMatrix:flash.geom.Matrix;
	
	/**
	 * A reuseable rectangle used for fillRect rectangle
	 */
	private var _fillRectRectangle:RectangleVO;
	
	/**
	 * A reuseable point used for fillRect rectangle
	 */
	private var _fillRectPoint:PointVO;
	
	/**
	 * class constructor
	 */
	public function new(layerRenderer:LayerRenderer = null, nativeLayer:NativeElement = null) 
	{
		super(layerRenderer);
		
		//create a new Sprite if no sprite is provided
		if (nativeLayer == null)
		{
			nativeLayer = new Sprite();
		}
		
		_nativeLayer = cast(nativeLayer);
		_childrenNativeLayer = new Sprite();
		_nativeBitmap = new Bitmap(new BitmapData(1, 1, true, 0x00000000), PixelSnapping.AUTO, true);
		_flashRectangle = new Rectangle();
		_flashPoint = new Point();
		_flashMatrix = new flash.geom.Matrix();
		_fillRectRectangle = new RectangleVO(0.0, 0.0, 0.0, 0.0);
		_fillRectPoint = new PointVO(0.0, 0.0);
		_width = 0;
		_height = 0;
		
		//build native display list
		_nativeLayer.addChild(_nativeBitmap);
		_nativeLayer.addChild(_childrenNativeLayer);
	}
	
	/**
	 * Create new BitmapData when the size of the window changes
	 */
	override public function initBitmapData(width:Int, height:Int):Void
	{
		_width = width;
		_height = height;
		
		_nativeBitmap.bitmapData.dispose();
		_nativeBitmap.bitmapData = new BitmapData(width, height, true, 0x00000000);
	}
	
	/**
	 * clear the BitmapData by filling it with
	 * transparent black
	 */
	override public function clear():Void
	{
		_flashRectangle.x = 0;
		_flashRectangle.y = 0;
		_flashRectangle.width = _width;
		_flashRectangle.height = _height;
		_nativeBitmap.bitmapData.fillRect(_flashRectangle, 0x00000000);
	}
	
	/////////////////////////////////
	// OVERRIDEN PUBLIC METHODS
	////////////////////////////////
	
	/**
	 * clean-up flash native objects
	 */
	override public function dispose():Void
	{
		_nativeBitmap.bitmapData.dispose();
		_nativeBitmap = null;
		_nativeLayer = null;
	}
	
	/**
	 * Apply a native flash trnasformation matrix to the 
	 * native layer Sprite
	 */
	override public function transform(matrix:Matrix):Void
	{
		var matrixData:MatrixData = matrix.data;
		_nativeLayer.transform.matrix = new flash.geom.Matrix(matrixData.a, matrixData.b, matrixData.c, matrixData.d, matrixData.e, matrixData.f);
	}
	
	/**
	 * When a child GraphicContext is added, also add the children native flash Sprite
	 */
	override public function appendChild(newChild:AbstractGraphicsContext):AbstractGraphicsContext
	{
		super.appendChild(newChild);
		
		//refresh all the native flash display list
		//TODO 3 : shouldn't have to re-attach all, should only attach new item at right index
		var length:Int = _orderedChildList.length;
		for (i in 0...length)
		{
			_childrenNativeLayer.addChild(_orderedChildList[i].nativeLayer);
		}
		
		return newChild;
	}
	
	/**
	 * Also remove the children native flash Sprite
	 */
	override public function removeChild(oldChild:AbstractGraphicsContext):AbstractGraphicsContext
	{
		super.removeChild(oldChild);
		_childrenNativeLayer.removeChild(oldChild.nativeLayer);
		return oldChild;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// Overriden High level pixel manipulation method
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Draw bitmap data into the bitmap display object.
	 */
	override public function drawImage(bitmapData:NativeBitmapData, matrix:Matrix = null, sourceRect:RectangleVO = null):Void
	{	
		//init destination point and sourceRect if null
		
		if (matrix == null)
		{
			matrix = new Matrix();
		}
		
		if (sourceRect == null)
		{
			var width:Float = bitmapData.width;
			var height:Float = bitmapData.height;
			sourceRect = new RectangleVO(0.0, 0.0, width, height);
		}
		
		//convert the cross-platform rectangle into flash native one
		_flashRectangle.x = sourceRect.x;
		_flashRectangle.y = sourceRect.y;
		_flashRectangle.width = sourceRect.width;
		_flashRectangle.height = sourceRect.height;
		
		var matrixData:MatrixData = matrix.data;
		
		_flashMatrix.a = matrixData.a;
		_flashMatrix.b = matrixData.b;
		_flashMatrix.c = matrixData.c;
		_flashMatrix.d = matrixData.d;
		_flashMatrix.tx = matrixData.e;
		_flashMatrix.ty = matrixData.f;
		
		var colorTransform:ColorTransform = null;
		
		//use a colorTransform to apply the alphe if 
		//transparency is used
		if (_useTransparency == true)
		{
			colorTransform = new ColorTransform(1.0, 1.0, 1.0, _alpha);
		}
		
		//draw the bitmap data onto the current bitmap data with the right transformations
		_nativeBitmap.bitmapData.draw(bitmapData, _flashMatrix, colorTransform, null, _flashRectangle, true);
	}
	
	/**
	 * Uses flash native copyPixels method for fast pixel 
	 * manipulation
	 */
	override public function copyPixels(bitmapData:NativeBitmapData, sourceRect:RectangleVO, destPoint:PointVO):Void
	{
		_flashRectangle.x = sourceRect.x;
		_flashRectangle.y = sourceRect.y;
		_flashRectangle.width = sourceRect.width;
		_flashRectangle.height = sourceRect.height;
		
		_flashPoint.x = destPoint.x;
		_flashPoint.y = destPoint.y;
		
		var alphaBitmapData:BitmapData = null;
		var alphaPoint:Point = null;
		
		//create a transparency bitmap data if transparency is
		//used
		if (_useTransparency == true)
		{
			var color:Int = 0x000000;
			var alpha:Int = Math.round(255 * _alpha);
			color += alpha << 24;
			
			alphaBitmapData = new BitmapData(Math.round(sourceRect.width), Math.round(sourceRect.height), true, color);
			alphaPoint = new Point(0,0);
		}
		
		_nativeBitmap.bitmapData.copyPixels(bitmapData, _flashRectangle, _flashPoint, alphaBitmapData, alphaPoint, true);
		
		if (alphaBitmapData != null)
		{
			alphaBitmapData.dispose();
		}
	}
	
	/**
	 * Uses flash native fillRect method for fast
	 * rectangle drawing
	 */
	override public function fillRect(rect:RectangleVO, color:ColorVO):Void
	{
		var argbColor:Int = color.color;
		var alpha:Int = Math.round(255 * color.alpha);
		argbColor += alpha << 24;
		
		//if the color is transparent, a new bitmap data
		//must be created to composite alpha
		if (color.alpha != 1.0)
		{
			_fillRectRectangle.width = rect.width;
			_fillRectRectangle.height = rect.height;
			_fillRectPoint.x = rect.x;
			_fillRectPoint.y = rect.y;
			
			var fillRectBitmapData:BitmapData = new BitmapData(Math.round(rect.width), Math.round(rect.height), true, argbColor);
			copyPixels(fillRectBitmapData, _fillRectRectangle, _fillRectPoint );
			fillRectBitmapData.dispose();
		}
		//else, the faster native flash method can be used
		else
		{
			_flashRectangle.x = rect.x;
			_flashRectangle.y = rect.y;
			_flashRectangle.width = rect.width;
			_flashRectangle.height = rect.height;
			_nativeBitmap.bitmapData.fillRect(_flashRectangle, argbColor);
		}
	
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN GETTER
	//////////////////////////////////////////////////////////////////////////////////////////
	
	override private function get_nativeBitmapData():NativeBitmapData
	{
		return _nativeBitmap.bitmapData;
	}
	
	override private function get_nativeLayer():NativeElement
	{
		return _nativeLayer;
	}
	
}