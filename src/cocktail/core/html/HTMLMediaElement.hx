/*
	This file is part of Cocktail http://www.silexlabs.org/groups/labs/cocktail/
	This project is © 2010-2011 Silex Labs and is released under the GPL License:
	This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License (GPL) as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version. 
	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	To read the license please visit http://www.gnu.org/copyleft/gpl.html
*/
package cocktail.core.html;
import cocktail.core.dom.Node;
import cocktail.core.event.Event;
import cocktail.port.platform.nativeMedia.NativeMedia;
import haxe.Timer;
import cocktail.core.html.HTMLData;

/**
 * This is an abstract base class for media elements,
 * such as video and audio
 * 
 * TODO 1 : implement loop
 * 
 * @author Yannick DOMINGUEZ
 */
class HTMLMediaElement extends EmbeddedElement
{
	/**
	 * When selecting the resource to load, mean that the src
	 * attribute value will be used as the media url
	 */
	public static inline var RESOURCE_SELECTION_ATTRIBUTE_MODE:Int = 0;
	
	/**
	 * When selecting the resource to load, mean that a child
	 * source element src attribute will be used as the media url
	 */
	public static inline var RESOURCE_SELECTION_CHILDREN_MODE:Int = 1;
	
	/**
	 * The name of the src attribute
	 */
	private static inline var HTML_SRC_ATTRIBUTE:String = "src";
	
	/**
	 * The name of the autoplay attribute
	 */
	private static inline var HTML_AUTOPLAY_ATTRIBUTE:String = "autoplay";
	
	/**
	 * The name of the loop attribute
	 */
	private static inline var HTML_LOOP_ATTRIBUTE:String = "loop";
	
	/**
	 * the html tag name of a source
	 */
	private static inline var HTML_SOURCE_TAG_NAME:String = "source";
	
	/**
	 * the type attribute name
	 */
	private static inline var HTML_TYPE_ATTRIBUTE:String = "type";
	
	/**
	 * the media attribute name
	 */
	private static inline var HTML_MEDIA_ATTRIBUTE:String = "media";
	
	/**
	 * the frequence in milliseconds between each dispatch of
	 * a timeupdate event when the media is playing
	 */
	private static inline var TIME_UPDATE_FREQUENCY:Int = 350;
	
	/**
	 * the frequence in milliseconds between each dispatch of
	 * a progress event when a media is loading
	 */
	private static inline var PROGRESS_FREQUENCY:Int = 350;
	
	/////////////////////////////////
	// IDL ATTRIBUTES
	////////////////////////////////
	
	/**
	 * The src content attribute on media elements gives the
	 * address of the media resource (video, audio)
	 * to show. The attribute, if present, must
	 * contain a valid non-empty URL potentially surrounded by spaces.
	 */
	public var src(get_src, set_src):String;
	
	/**
	 * When true, automatically begins playback of the media
	 */
	public var autoplay(get_autoplay, set_autoplay):Bool;
	
	/**
	 * Determines wether the media element is to seek
	 * back to the start of the media resource upon reaching the end.
	 */
	public var loop(get_loop, set_loop):Bool;
	
	/////////////////////////////////
	// ATTRIBUTES
	////////////////////////////////
	
	//network state
	
	/**
	 * The element has not yet been initialized. All attributes are 
	 * in their initial states.
	 */
	public static inline var NETWORK_EMPTY:Int = 0;
	
	/**
	 * The element's resource selection algorithm is active and
	 * has selected a resource, but it is not actually using the network at this time.
	 */
	public static inline var NETWORK_IDLE:Int = 1;
	
	/**
	 * The user agent is actively trying to download data.
	 */
	public static inline var NETWORK_LOADING:Int = 2;
	
	/**
	 * The element's resource selection algorithm is active,
	 * but it has not yet found a resource to use.
	 */
	public static inline var NETWORK_NO_SOURCE:Int = 3;
	
	/**
	 * As media elements interact with the network,
	 * their current network activity is represented
	 * by the networkState attribute. On getting, it 
	 * returns the current network state of the
	 * element
	 */
	private var _networkState:Int;
	public var networkState(get_networkState, never):Int;
	
	//can play constants
	
	/**
	 * return maybe if the user agent might support 
	 * the format
	 */
	public static inline var CAN_PLAY_TYPE_MAYBE:String = "maybe";
	
	/**
	 * return probably if the user agent is confident it 
	 * can play the format
	 */
	public static inline var CAN_PLAY_TYPE_PROBABLY:String = "probably";
	
	//ready state
	
	/**
	 * No information regarding the media resource
	 * is available. No data for the current playback 
	 * position is available. Media elements
	 * whose networkState attribute are set to NETWORK_EMPTY
	 * are always in the HAVE_NOTHING state.
	 */
	public static inline var HAVE_NOTHING:Int = 0;
	
	/**
	 * Enough of the resource has been obtained that the duration of
	 * the resource is available. In the case of a video element,
	 * the dimensions of the video are also available.
	 * The API will no longer throw an exception
	 * when seeking. No media data is available
	 * for the immediate current playback position.
	 */
	public static inline var HAVE_METADATA:Int = 1;
	
	/**
	 * Data for the immediate current playback position is available,
	 * but either not enough data is available that the user 
	 * agent could successfully advance the current playback position
	 * in the direction of playback at all without immediately
	 * reverting to the HAVE_METADATA state, or there is no more
	 * data to obtain in the direction of playback. For example,
	 * in video this corresponds to the user agent having data
	 * from the current frame, but not the next frame,
	 * when the current playback position is at the end
	 * of the current frame; and to when playback has ended.
	 */
	public static inline var HAVE_CURRENT_DATA:Int = 2;
	
	/**
	 * Data for the immediate current playback position is available,
	 * as well as enough data for the user agent to advance
	 * the current playback position in the direction
	 * of playback at least a little without immediately
	 * reverting to the HAVE_METADATA state, and the
	 * text tracks are ready. For example, in video
	 * this corresponds to the user agent having data
	 * for at least the current frame and the next frame
	 * when the current playback position is at the instant
	 * in time between the two frames, or to the user agent
	 * having the video data for the current frame and audio
	 * data to keep playing at least a little when the current
	 * playback position is in the middle of a frame. The user 
	 * agent cannot be in this state if playback has ended, 
	 * as the current playback position can never advance in this case.
	 */
	public static inline var HAVE_FUTURE_DATA:Int = 3;
	
	/**
	 * All the conditions described for the HAVE_FUTURE_DATA state 
	 * are met, and, in addition, the user agent estimates
	 * that data is being fetched at a rate where the current 
	 * playback position, if it were to advance at the effective
	 * playback rate, would not overtake the available data 
	 * before playback reaches the end of the media resource.
	 */
	public static inline var HAVE_ENOUGH_DATA:Int = 4;
	
	/**
	 * Returns a value that expresses the current state of the 
	 * element with respect to rendering the 
	 * current playback position, from the codes in the list below.
	 */
	private var _readyState:Int;
	public var readyState(get_readyState, never):Int;
	
	/**
	 * Returns true if the user agent is currently seeking.
	 */
	private var _seeking:Bool;
	public var seeking(get_seeking, never):Bool;
	
	//playback state
	
	/**
	 * on getting, return the media element's default playback start position, 
	 * unless that is zero, in which case it must return the element's official playback position.
	 * The returned value is expressed in seconds. 
	 */
	public var currentTime(get_currentTime, set_currentTime):Float;
	
	private var _currentSrc:String;
	public var currentSrc(get_currentSrc, null):String;
	
	/**
	 * Return the length of the media resource, in seconds,
	 * assuming that the start of the media resource is
	 * at time zero
	 */
	private var _duration:Float;
	public var duration(get_duration, never):Float;
	
	/**
	 * return a new static normalized TimeRanges object that represents
	 * the ranges of the media resource, if any, that the user agent has buffered,
	 * at the time the attribute is evaluated.
	 * 
	 * TODO 2 : Users agents must accurately determine the ranges available, 
	 * even for media streams where this can only be determined by tedious inspection.
	 */
	public var buffered(get_buffered, never):TimeRanges;
	
	/**
	 * The paused attribute represents whether the media
	 * element is paused or not. The attribute is initially true.
	 */
	private var _paused:Bool;
	public var paused(get_paused,  never):Bool;
	
	/**
	 * Returns true if playback has reached the
	 * end of the media resource.
	 */
	private var _ended:Bool;
	public var ended(get_ended, never):Bool;
	
	/**
	 * Returns true if audio is muted, overriding the volume attribute,
	 * and false if the volume attribute is being honored. Can be set,
	 * to change whether the audio is muted or not.
	 */
	private var _muted:Bool;
	public var muted(get_muted, set_muted):Bool;
	
	/**
	 * Returns the current playback volume, as a number in
	 * the range 0.0 to 1.0, where 0.0 is the quietest and
	 * 1.0 the loudest. Can be set, to change the volume.
	 */
	private var _volume:Float;
	public var volume(get_volume, set_volume):Float;
	
	/**
	 * a reference to the proxy class allowing
	 * access to runtime specific API for 
	 * video and audio
	 */
	private var _nativeMedia:NativeMedia;
	
	private var _initialPlaybackPosition:Float;
	
	private var _officialPlaybackPosition:Float;
	
	private var _currentPlaybackPosition:Float;
	
	private var _defaultPlaybackStartPosition:Float;
	
	private var _earliestPossiblePosition:Float;
	
	private var _loadedDataWasDispatched:Bool;
	
	private var _autoplaying:Bool;
	
	/**
	 * class constructor
	 */
	public function new(tagName:String)
	{
		super(tagName);
		
		_networkState = NETWORK_EMPTY;
		_ended = false;
		_duration = 0;
		_paused = true;
		_seeking = false;
		_readyState = HAVE_NOTHING;
		_autoplaying = true;
		_muted = false;
		_volume = 1.0;
		
		_loadedDataWasDispatched = false;
		_defaultPlaybackStartPosition = 0;
		_officialPlaybackPosition = 0;
		_currentPlaybackPosition = 0;
		_initialPlaybackPosition = 0;
		_earliestPossiblePosition = 0;
	}
	
	/**
	 * overriden to also init the native media
	 */
	override private function init():Void
	{
		initNativeMedia();
		super.init();
	}
	
	/**
	 * Instantiate the right native media
	 * manager
	 */
	private function initNativeMedia():Void
	{
		//abstract
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN NODE METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * overriden to invoke the resource selection algorithm
	 * as needed if a source child is added
	 */
	override public function appendChild(newChild:Node):Node
	{
		super.appendChild(newChild);
		
		//if there is no source and no selected resource for
		//this media element
		if (src == null && _networkState == NETWORK_EMPTY)
		{
			//invoke the select resource algorithm if a source
			//child was just added
			if (newChild.nodeName == HTML_SOURCE_TAG_NAME)
			{
				selectResource();
			}
		}
		
		return newChild;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN ATTRIBUTES METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * overriden to call the right setter for 
	 * html media attributes
	 */
	override public function setAttribute(name:String, value:String):Void
	{
		if (name == HTML_SRC_ATTRIBUTE)
		{
			src = value;
		}
		else
		{
			super.setAttribute(name, value);
		}
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PRIVATE RENDERING TREE METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Overriden to pause the media element
	 * if necessary when detaching from
	 * rendering tree
	 * 
	 * TODO 2 : should be instead when detached 
	 * from DOM ?
	 */
	override private function detachFromParentElementRenderer():Void
	{
		super.detachFromParentElementRenderer();
		
		if (_networkState != NETWORK_EMPTY)
		{
			pause();
		}
	}
	
	/////////////////////////////////
	// PUBLIC METHODS
	////////////////////////////////
	
	/**
	 * Sets the paused attribute to false, loading the media resource
	 * and beginning playback if necessary.
	 * If the playback had ended, will restart it from the start.
	 * 
	 * this method is an implementation of the following algorithm :
	 * http://www.w3.org/TR/2012/WD-html5-20120329/media-elements.html#dom-media-play
	 * 
	 * TODO 2 incomplete implementation
	 */
	public function play():Void
	{
		if (_networkState == NETWORK_EMPTY)
		{
			selectResource();
		}
		
		if (_ended == true)
		{
			seek(0);
		}
		
		if (_paused == true)
		{
			_paused = false;
			
			fireEvent(Event.PLAY, false, false);
			
			switch (_readyState)
			{
				case HAVE_NOTHING, HAVE_METADATA, HAVE_CURRENT_DATA:
					fireEvent(Event.WAITING, false, false);
					
				case HAVE_FUTURE_DATA, HAVE_ENOUGH_DATA:
					fireEvent(Event.PLAYING, false, false);
			}
		}
		
		_autoplaying = false;
		
		_nativeMedia.play();
		
		onTimeUpdateTick();
	}
	
	/**
	 * Sets the paused attribute to true, 
	 * loading the media resource if necessary.
	 * 
	 * this method is an implementation of the following algorithm :
	 * http://www.w3.org/TR/2012/WD-html5-20120329/media-elements.html#dom-media-pause
	 */
	public function pause():Void
	{
		if (_networkState == NETWORK_EMPTY)
		{
			selectResource();
		}
		
		_autoplaying = false;
		
		if (_paused == false)
		{
			_paused = true;
			
			fireEvent(Event.TIME_UPDATE, false, false);
			
			fireEvent(Event.PAUSE, false, false);
			
			_officialPlaybackPosition = _currentPlaybackPosition;
		}
		
		_nativeMedia.pause();
	}
	
	/**
	 * Returns the empty string (a negative response), 
	 * "maybe", or "probably" based on how confident
	 * the user agent is that it can play media resources of the given type.
	 */
	public function canPlayType(type:String):String
	{
		return _nativeMedia.canPlayType(type);
	}
	
	/////////////////////////////////
	// PRIVATE METHODS
	////////////////////////////////
	
	/**
	 * Start the loading of a media element, this 
	 * is an implementation of the following alogithm :
	 * http://www.w3.org/TR/2012/WD-html5-20120329/media-elements.html#media-element-load-algorithm
	 * 
	 * TODO 2 : implementation is incomplete
	 */
	private function loadResource():Void
	{
		switch (_networkState)
		{
			case NETWORK_LOADING, NETWORK_IDLE:
				fireEvent(Event.ABORT, false, false);
		}
		
		if (_networkState != NETWORK_EMPTY)
		{
			fireEvent(Event.EMPTIED, false, false);
			
			_nativeMedia.src = null;
			
			_networkState = NETWORK_EMPTY;
			
			
			_readyState = HAVE_NOTHING;
			
			_paused = true;
			
			_seeking = false;
			
			_currentPlaybackPosition = 0;
			
			if (_officialPlaybackPosition > 0)
			{
				_officialPlaybackPosition = 0;
				fireEvent(Event.TIME_UPDATE, false, false);
			}
			else
			{
				_officialPlaybackPosition = 0;
			}
			
			_initialPlaybackPosition = 0;
			
			_duration = Math.NaN;
		}
		
		_loadedDataWasDispatched = false;
		
		selectResource();
	}
	
	/**
	 * Select a resource, from the src attribute of the
	 * node or from a child source node.
	 * 
	 * this is an implementation of the following alogithm :
	 * http://www.w3.org/TR/2012/WD-html5-20120329/media-elements.html#media-element-load-algorithm
	 *
	 * TODO 2 : implementation is incomplete
	 */
	private function selectResource():Void
	{
		_networkState = NETWORK_NO_SOURCE;
		
		var mode:Int;
		var candidate:HTMLSourceElement;
		
		if (src != null)
		{
			mode = RESOURCE_SELECTION_ATTRIBUTE_MODE;
		}
		else if (hasChildSourceElement() == true)
		{
			mode = RESOURCE_SELECTION_CHILDREN_MODE;
			
			//retrieve the first source child
			for (i in 0..._childNodes.length)
			{
				if (_childNodes[i].nodeName == HTML_SOURCE_TAG_NAME)
				{
					candidate = cast(_childNodes[i]);
					break;
				}
			}
		}
		else
		{
			_networkState = NETWORK_EMPTY;
			return;
		}
		
		_networkState = NETWORK_LOADING;
		
		fireEvent(Event.LOAD_START, false, false);
		
		if (mode == RESOURCE_SELECTION_ATTRIBUTE_MODE)
		{
			if (src == "")
			{
				//TODO 1 : Set the error attribute to a new MediaError object whose code attribute is set to MEDIA_ERR_SRC_NOT_SUPPORTED.
				
				_networkState = NETWORK_NO_SOURCE;
				
				fireEvent(Event.ERROR, false, false);
				
				return;
			}
			
			//TODO 2 : Let absolute URL be the absolute URL that would have resulted 
			//from resolving the URL specified by the src attribute's value relative
			//to the media element when the src attribute was last changed.
			
			_currentSrc = src;
			fetchResource(_currentSrc);	
		}
		else if (mode == RESOURCE_SELECTION_CHILDREN_MODE)
		{
			//TODO 2 : short cut for now, not implemented like the spec
			for (i in 0..._childNodes.length)
			{
				if (_childNodes[i].nodeName == HTML_SOURCE_TAG_NAME)
				{
					var sourceChild:HTMLSourceElement = cast(_childNodes[i]);
					if (sourceChild.type != null)
					{
						
						if (canPlayType(sourceChild.type) == CAN_PLAY_TYPE_PROBABLY)
						{
							_currentSrc = sourceChild.src;
							fetchResource(_currentSrc);
							return;
						}
					}
					else if (sourceChild.src != null)
					{
						if (canPlayType(sourceChild.src) == CAN_PLAY_TYPE_PROBABLY)
						{
							_currentSrc = sourceChild.src;
							fetchResource(_currentSrc);
							return;
						}
					}
				}
			}
			
			_networkState = NETWORK_EMPTY;
		}
	}
	
	private function fetchResource(url:String):Void
	{
		_nativeMedia.onLoadedMetaData = onLoadedMetaData;
		_nativeMedia.src = url;
	}
	
	/**
	 * Seeks to a given position of the media
	 * 
	 * This is an implementation of the following
	 * algorithm :
	 * http://www.w3.org/TR/2012/WD-html5-20120329/media-elements.html#dom-media-seeking
	 * 
	 * @param	newPlaybackPosition the time to seek to, in seconds
	 */
	private function seek(newPlaybackPosition:Float):Void
	{
		if (_readyState == HAVE_NOTHING)
		{
			return;
		}
		
		if (_seeking == true)
		{
			//TODO 1 : If the element's seeking IDL attribute is true, 
			//then another instance of this algorithm is already running. 
			//Abort that other instance of the algorithm without waiting for
			//the step that it is running to complete.
		}
		
		_seeking = true;
		
		if (newPlaybackPosition > _duration)
		{
			newPlaybackPosition = _duration;
		}
		
		if (newPlaybackPosition < _earliestPossiblePosition)
		{
			newPlaybackPosition = 0;
		}
		
		//TODO 2 : If the (possibly now changed) new playback position is 
		//not in one of the ranges given in the seekable attribute, then let 
		//it be the position in one of the ranges given in the seekable
		//attribute that is the nearest to the new playback position. If 
		//two positions both satisfy that constraint (i.e. the new playback
		//position is exactly in the middle between two ranges in the seekable
		//attribute) then use the position that is closest to the current 
		//playback position. If there are no ranges given in the seekable 
		//attribute then set the seeking IDL attribute to false and abort these steps.
		
		fireEvent(Event.SEEKING, false, false);
		
	
		_currentPlaybackPosition = newPlaybackPosition;
		
		_nativeMedia.seek(newPlaybackPosition);
		
		//TODO 2 : Wait until the user agent has established whether or not 
		//the media data for the new playback position is available, and, if
		//it is, until it has decoded enough data to play back that position.
		
		fireEvent(Event.TIME_UPDATE, false, false);
		
		fireEvent(Event.SEEKED, false, false);
	}
	
	/**
	 * When the ready state of the media element
	 * changes, fire the right events.
	 * 
	 * This is an implementation of the following algorithm:
	 * http://www.w3.org/TR/2012/WD-html5-20120329/media-elements.html#dom-media-load
	 */
	private function setReadyState(newReadyState:Int):Void
	{
		if (_readyState == HAVE_NOTHING && newReadyState == HAVE_METADATA)
		{
			fireEvent(Event.LOADED_METADATA, false, false);
		}
		
		if (_readyState == HAVE_METADATA && (newReadyState == HAVE_CURRENT_DATA || newReadyState == HAVE_ENOUGH_DATA 
		|| newReadyState == HAVE_FUTURE_DATA))
		{
			if (_loadedDataWasDispatched == false)
			{
				fireEvent(Event.LOADED_DATA, false, false);
				_loadedDataWasDispatched = true;
			}
			
			if (newReadyState == HAVE_ENOUGH_DATA || newReadyState == HAVE_FUTURE_DATA)
			{
				if ((_readyState >= HAVE_FUTURE_DATA && newReadyState <= HAVE_CURRENT_DATA))
				{
					if (isPotentiallyPlaying() == true)
					{
						fireEvent(Event.TIME_UPDATE, false, false);
						fireEvent(Event.WAITING, false, false);
					}
				}
				
				if (_readyState <= HAVE_CURRENT_DATA && newReadyState == HAVE_FUTURE_DATA)
				{
					fireEvent(Event.CAN_PLAY, false, false);
					
					if (_paused == false)
					{
						fireEvent(Event.PLAYING, false, false);
					}
				}
				
				if (newReadyState == HAVE_ENOUGH_DATA)
				{
					if (_readyState == HAVE_CURRENT_DATA)
					{
						fireEvent(Event.CAN_PLAY, false, false);
						
						if (_paused == false)
						{
							fireEvent(Event.PLAYING, false, false);
						}
					}
					
					if (_autoplaying == true)
					{
						if (_paused == true)
						{
							if (autoplay == true)
							{
								_paused = false;
								fireEvent(Event.PLAY, false, false);
								
								play();
								
								fireEvent(Event.PLAYING, false, false);
							}
						}
					}
					
					fireEvent(Event.CAN_PLAY_THROUGH, false, false);
				}
			}
		}
		
		_readyState = newReadyState;
	}
	
	/**
	 * A media element is said to be potentially playing when
	 * its paused attribute is false, the element has not ended
	 * playback, playback has not stopped due to errors,
	 * the element either has no current media controller
	 * or has a current media controller but is not blocked
	 * on its media controller, and the element is not
	 * a blocked media element.
	 * 
	 * TODO 2 : incomplete
	 * 
	 */
	private function isPotentiallyPlaying():Bool
	{
		if (_paused == true)
		{
			return false;
		}
		
		if (_ended == true)
		{
			return false;
		}
		
		return true;
	}
	
	/**
	 * called after the metadata of the media
	 * have been loaded
	 * 
	 * This is an implementation of the following
	 * algorithm :
	 * http://www.w3.org/TR/2012/WD-html5-20120329/media-elements.html#concept-media-load-algorithm
	 */
	private function establishMediaTimeline():Void
	{
		_currentPlaybackPosition = 0;
		_initialPlaybackPosition = 0;
		_officialPlaybackPosition = 0;
		
		_duration = _nativeMedia.duration;
		fireEvent(Event.DURATION_CHANGE, false, false);
		
		setReadyState(HAVE_METADATA);
		
		var jumped = false;
		
		if (_defaultPlaybackStartPosition > 0)
		{
			seek(_defaultPlaybackStartPosition);
			jumped = true;
		}
		
		_defaultPlaybackStartPosition = 0;
		
		//TODO 2 : If either the media resource or the address of the
		//current media resource indicate a particular start time,
		//then set the initial playback position to that time and,
		//if jumped is still false, seek to that time and let jumped be true.	
	}
	
	/**
	 * Utils method determining if the media element
	 * has at least one source element child
	 */
	private function hasChildSourceElement():Bool
	{
		for (i in 0..._childNodes.length)
		{
			if (_childNodes[i].nodeName == HTML_SOURCE_TAG_NAME)
			{
				return true;
			}
		}
		
		return false;
	}
	
	/////////////////////////////////
	// RESOURCE CALLBACKS
	////////////////////////////////
	
	private function onLoadingError(error:Event):Void
	{
		selectResource();
	}
	
	/**
	 * When the metadata of the media have been 
	 * loaded, update the intrinisc dimensions
	 * of the html element and all the attributes
	 * which can retrieved through this metadata
	 */
	private function onLoadedMetaData(e:Event):Void
	{
		_intrinsicHeight = _nativeMedia.height;
		_intrinsicWidth = _nativeMedia.width;
		_intrinsicRatio = _intrinsicHeight / _intrinsicWidth;
		
		//update playback times and duration
		establishMediaTimeline();
		
		//refresh the layout
		invalidateLayout();
		
		//start listening to loading event, as it begins
		//as soon as the metadata are loaded
		onProgressTick();
	}
	
	/**
	 * Called at a regular frequency while
	 * the media is playing
	 */
	private function onTimeUpdateTick():Void
	{
		//stop dispatching time updates if the
		//media is paused
		if (_paused == true)
		{
			return;
		}
		
		//update playback position
		_currentPlaybackPosition = _nativeMedia.currentTime;
		_officialPlaybackPosition = _currentPlaybackPosition;
		
		//check if the end of the media is reached
		if (Math.round(_currentPlaybackPosition) >= Math.round(_duration))
		{
			_ended = true;
			fireEvent(Event.ENDED, false, false);
			return;
		}
		
		//if the media has not ended playing, dispatch a time update
		//event, then set this method to be called again 
		fireEvent(Event.TIME_UPDATE, false, false);
		Timer.delay(onTimeUpdateTick, TIME_UPDATE_FREQUENCY);
	}
	
	/**
	 * Called at a regular frequency whild the media is
	 * being loaded
	 */
	private function onProgressTick():Void
	{
		//check if all of the media has been loaded
		if (_nativeMedia.bytesLoaded >= _nativeMedia.bytesTotal)
		{
			setReadyState(HAVE_ENOUGH_DATA);
			
			_networkState == NETWORK_IDLE;
			fireEvent(Event.SUSPEND, false, false);
			
			return;
		}
		
		//if not all of the media has been loaded, dispatch
		//a progress event and set this method to be called again
		fireEvent(Event.PROGRESS, false, false);
		Timer.delay(onTimeUpdateTick, TIME_UPDATE_FREQUENCY);
	}
	
	/////////////////////////////////
	// IDL GETTER/SETTER
	////////////////////////////////
	
	private function get_src():String 
	{
		return getAttribute(HTML_SRC_ATTRIBUTE);
	}
	
	private function set_src(value:String):String 
	{
		//TODO 2 : awkward to call super, but else infinite loop
		super.setAttribute(HTML_SRC_ATTRIBUTE, value);
		loadResource();
		return value;
	}
	
	private function get_autoplay():Bool
	{
		if (getAttribute(HTML_AUTOPLAY_ATTRIBUTE) != null)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	
	private function set_autoplay(value:Bool):Bool
	{
		//TODO 2 : awkward to call super, but else infinite loop
		super.setAttribute(HTML_AUTOPLAY_ATTRIBUTE, Std.string(value));
		return value;
	}
	
	private function get_loop():Bool
	{
		if (getAttribute(HTML_LOOP_ATTRIBUTE) != null)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	
	private function set_loop(value:Bool):Bool
	{
		//TODO 2 : awkward to call super, but else infinite loop
		super.setAttribute(HTML_LOOP_ATTRIBUTE, Std.string(value));
		return value;
	}
	
	/////////////////////////////////
	// GETTER/SETTER
	////////////////////////////////
	
	private function get_muted():Bool
	{
		return _muted;
	}
	
	private function set_muted(value:Bool):Bool
	{
		//update the volume of the native media
		//if sound is no longer muted
		if (value == false)
		{
			_nativeMedia.volume = _volume;
		}
		//muting consist on setting volume of native
		//media to 0
		else
		{
			_nativeMedia.volume = 0;
		}
		
		_muted = value;
		fireEvent(Event.VOLUME_CHANGE, false, false);
		
		return _muted;
	}
	
	private function set_volume(value:Float):Float
	{
		if (_muted == false)
		{
			_nativeMedia.volume = value;
		}
		
		_volume = value;
		fireEvent(Event.VOLUME_CHANGE, false, false);
		
		return _volume;
	}
	
	private function get_volume():Float
	{
		return _volume;
	}
	
	private function get_buffered():TimeRanges
	{
		var ranges:Array<Range> = new Array<Range>();
		
		//return one range which is the number of seconds
		//already loaded of the media
		ranges.push( {
			start : 0.0,
			end: _duration * (_nativeMedia.bytesLoaded / _nativeMedia.bytesTotal)
		});
		
		var timeRanges:TimeRanges = new TimeRanges(ranges);
		return timeRanges;
	}
	
	private function get_currentSrc():String 
	{
		return _currentSrc;
	}
	
	private function get_networkState():Int 
	{
		return _networkState;
	}
	
	private function get_currentTime():Float 
	{
		//if default playback position is different from 0,
		//it means that the media has not loaded yet, as it takes
		//the default playback start position and reset it as soon
		//as it is loaded
		if (_defaultPlaybackStartPosition != 0)
		{
			return _defaultPlaybackStartPosition;
		}
		
		return _officialPlaybackPosition;
	}
	
	private function set_currentTime(value:Float):Float 
	{
		switch(_readyState)
		{
			//if current time is set before the media loading,
			//store in the default playback position which will
			//be applied as soon as the media is loaded
			case HAVE_NOTHING:
				_defaultPlaybackStartPosition = value;
				
			default:
				_officialPlaybackPosition = value;
				seek(value);
		}
		
		return value;
	}
	
	private function get_duration():Float
	{
		return _duration;
	}
	
	private function get_paused():Bool
	{
		return _paused;
	}
	
	private function get_ended():Bool 
	{
		return _ended;
	}
	
	private function get_readyState():Int
	{
		return _readyState;
	}
	
	private function get_seeking():Bool
	{
		return _seeking;
	}
}