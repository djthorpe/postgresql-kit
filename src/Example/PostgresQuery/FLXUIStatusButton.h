
#import <Cocoa/Cocoa.h>

@interface FLXUIStatusButton : NSButton {
  NSImage* m_theImage;
  NSImage* m_theTriangleImage;
  NSImage* m_theGradientImage;
  NSPopUpButtonCell* m_thePopUpButton;  
  CGFloat m_thePadding;
}

@end
