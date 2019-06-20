/* KABubbleWindowView.h from Colloquy (colloquy.info).
 * Modified for CocoaDialog (cocoadialog.sf.net).
 * I think they got this from an old version of Growl (growl.info).
 */

#import <Cocoa/Cocoa.h>

@interface KABubbleWindowView : NSView {
	NSImage *_icon;
	NSString *_title;
	NSAttributedString *_text;
	SEL _action;
	__unsafe_unretained id _target;
	CGFloat _darkColorFloat[4];   // Cache these rather than
	CGFloat _lightColorFloat[4];  // calculating over and over.
	NSColor *_darkColor;
	NSColor *_lightColor;
	NSColor *_textColor;
	NSColor *_borderColor;
}
@property (nonatomic, retain, nullable) NSImage *icon;
@property (nonatomic, copy, nullable) NSString *title;
- (void) setAttributedText:(NSAttributedString *_Nullable) text;
- (void) setText:(NSString *_Nullable) text;

@property (readonly, nonnull) const CGFloat *darkColorFloat; // returns { r, g, b, a }
@property (readonly, nonnull) const CGFloat *lightColorFloat; // returns { r, g, b, a }
@property (nonatomic, retain, nullable) NSColor *darkColor;
@property (nonatomic, retain, nullable) NSColor *lightColor;
@property (retain, nullable) NSColor *textColor;
@property (retain, nullable) NSColor *borderColor;

@property (assign, nullable) id target;

@property (nullable) SEL action;

@end
