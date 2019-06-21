/* KABubbleWindow from Colloquy (colloquy.info).
 * I think they got this from an old version of Growl (growl.info).
 */
#import "KABubbleWindow.h"

@implementation KABubbleWindow

- (id)initWithContentRect:(NSRect)contentRect
				styleMask:(NSWindowStyleMask)aStyle
				  backing:(NSBackingStoreType)bufferingType
					defer:(BOOL)flag {
	
	//use NSWindow to draw for us
	KABubbleWindow* result = [super initWithContentRect:contentRect
											  styleMask:NSWindowStyleMaskBorderless
												backing:NSBackingStoreBuffered
												  defer:NO];
	
	//set up our window
	[result setBackgroundColor: [NSColor clearColor]];
	[result setLevel: NSStatusWindowLevel];
	[result setAlphaValue:0.15];
	[result setOpaque:NO];
	[result setHasShadow: YES];
	[result setCanHide:NO ];
	
	return result;
}

@end
