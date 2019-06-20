/* KABubbleWindowController.h from Colloquy (colloquy.info).
 * Modified for CocoaDialog (cocoadialog.sf.net).
 * I think they got this from an old version of Growl (growl.info).
 */

#import <Cocoa/Cocoa.h>

typedef NS_OPTIONS(unsigned int, KABubblePosition) {
	BUBBLE_HORIZ_LEFT   = 0,
	BUBBLE_HORIZ_CENTER = 1,
	BUBBLE_HORIZ_RIGHT  = 2,

	BUBBLE_VERT_TOP     = 4,
	BUBBLE_VERT_CENTER  = 8,
	BUBBLE_VERT_BOTTOM  = 16
};

@protocol KABubbleWindowControllerDelegate;

@interface KABubbleWindowController : NSWindowController <NSWindowDelegate> {
	id<KABubbleWindowControllerDelegate> _delegate;
	NSTimer *_animationTimer;
	unsigned int _depth;
	BOOL _autoFadeOut;
	SEL _action;
	id _target;
	id _representedObject;
	NSTimeInterval _timeout;
}

- (id) initWithTextColor:(NSColor *)textColor 
			   darkColor:(NSColor *)darkColor 
			  lightColor:(NSColor *)lightColor 
			 borderColor:(NSColor *)borderColor
	  numExpectedBubbles:(NSInteger)numExpected 
		  bubblePosition:(KABubblePosition)position;

// position is a bitmask of the BUBBLE_* defines
+ (KABubbleWindowController *) bubbleWithTitle:(NSString *) title
                                          text:(id) text
                                          icon:(NSImage *) icon
                                       timeout:(NSTimeInterval) timeout
                                    lightColor:(NSColor *) lightColor
                                     darkColor:(NSColor *) darkColor
                                     textColor:(NSColor *) textColor
                                   borderColor:(NSColor *) borderColor
							numExpectedBubbles:(NSInteger)numExpected
								bubblePosition:(KABubblePosition)position;

- (void) startFadeIn;
- (void) startFadeOut;

@property BOOL automaticallyFadesOut;

@property (retain) id target;

@property SEL action;

@property (retain) id representedObject;

@property (assign) id<KABubbleWindowControllerDelegate> delegate;

@property NSTimeInterval timeout;

@end

@protocol KABubbleWindowControllerDelegate <NSObject>
@optional
- (void) bubbleWillFadeIn:(KABubbleWindowController *) bubble;
- (void) bubbleDidFadeIn:(KABubbleWindowController *) bubble;

- (void) bubbleWillFadeOut:(KABubbleWindowController *) bubble;
- (void) bubbleDidFadeOut:(KABubbleWindowController *) bubble;
@end
