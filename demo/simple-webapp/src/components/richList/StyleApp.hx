/*
This file is part of Silex - see http://projects.silexlabs.org/?/silex

Silex is © 2010-2011 Silex Labs and is released under the GPL License:

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License (GPL) as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version. 

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

To read the license please visit http://www.gnu.org/copyleft/gpl.html
*/

package components.richList;

// DOM
import cocktail.domElement.ContainerDOMElement;
import cocktail.domElement.DOMElement;

// Native Elements
import cocktail.nativeElement.NativeElementManager;
import cocktail.nativeElement.NativeElementData;

// Style
import cocktail.style.StyleData;
import cocktail.unit.UnitData;

// RichList
import components.richList.RichListModels;


/**
 * This class defines the styles used by the App RichList,
 * i.e. a list with each cell containing an image over a text, and having each cell next to the previous one

 * @author Raphael Harmel
 */

class StyleApp
{

	public static function getDefaultStyle(domElement:DOMElement):Void
	{
		domElement.style.paddingLeft = PaddingStyleValue.length(px(15));
		domElement.style.paddingRight = PaddingStyleValue.length(px(15));
		domElement.style.paddingTop = PaddingStyleValue.length(px(15));
		domElement.style.paddingBottom = PaddingStyleValue.length(px(15));
		
		domElement.style.display = DisplayStyleValue.inlineBlock;
		domElement.style.position = PositionStyleValue.relative;
	}
	
	public static function getCellStyle(domElement:ContainerDOMElement):Void
	{
		//getDefaultStyle(domElement);
		
		domElement.style.fontFamily = [FontFamilyStyleValue.familyName('Helvetica'), FontFamilyStyleValue.genericFamily(GenericFontFamilyValue.sansSerif)];
		domElement.style.fontSize = FontSizeStyleValue.length(px(12));
		domElement.style.textAlign = TextAlignStyleValue.center;
		domElement.style.color = ColorValue.keyword(ColorKeywordValue.white);

		domElement.style.height = DimensionStyleValue.auto;
		domElement.style.width = DimensionStyleValue.auto;
		domElement.style.marginLeft = domElement.style.marginRight = MarginStyleValue.length(px(12));
		domElement.style.marginBottom = MarginStyleValue.length(px(12));
		domElement.style.textAlign = TextAlignStyleValue.center;

		domElement.style.display = DisplayStyleValue.inlineBlock;
		domElement.style.color = ColorValue.hex('BDBDCE');
	}
	
	public static function getCellImageStyle(domElement:DOMElement):Void
	{
		//getDefaultStyle(domElement);

		domElement.style.display = DisplayStyleValue.block;
		domElement.style.width = domElement.style.height = DimensionStyleValue.length(px(48));
		domElement.style.marginBottom = MarginStyleValue.length(px(0));
	}
	
	public static function getCellMouseOverStyle(domElement:ContainerDOMElement):Void
	{
		//getCellStyle(domElement);

		domElement.style.color = ColorValue.hex('DDDDDD');
	}
	
	public static function getCellMouseOutStyle(domElement:ContainerDOMElement):Void
	{
		//getCellStyle(domElement);

		domElement.style.color = ColorValue.hex('BDBDCE');
	}
	
	public static function getCellMouseDownStyle(domElement:ContainerDOMElement):Void
	{
		//getCellStyle(domElement);

		domElement.style.color = ColorValue.keyword(ColorKeywordValue.white);
	}
	
	public static function getCellMouseUpStyle(domElement:ContainerDOMElement):Void
	{
		//getCellStyle(domElement);

		domElement.style.color = ColorValue.hex('BDBDCE');
	}
}