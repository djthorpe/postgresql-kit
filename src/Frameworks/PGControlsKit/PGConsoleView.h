
@protocol PGConsoleViewDelegate <NSObject>
@required
	-(NSUInteger)numberOfRowsInConsoleView:(PGConsoleView* )view;
	-(NSString* )consoleView:(PGConsoleView* )view stringForRow:(NSUInteger)row;
@optional
	-(void)appendString:(NSString* )string;
@end

@interface PGConsoleView : NSViewController <NSTableViewDataSource, NSTableViewDelegate> {
	NSFont* _textFont;
	NSColor* _textColor;
	NSColor* _backgroundColor;
	BOOL _showGutter;
	BOOL _editable;
	NSMutableString* _editBuffer;
}

// properties
@property (assign) IBOutlet NSTableView* tableView;
@property (weak,nonatomic) id<PGConsoleViewDelegate> delegate;
@property NSFont* textFont;
@property NSColor* textColor;
@property NSColor* backgroundColor;
@property (readonly) CGFloat textHeight;
@property BOOL showGutter;
@property CGFloat defaultGutterWidth;
@property BOOL editable;
@property (readonly) NSMutableString* editBuffer;

// methods
-(void)reloadData;
-(void)scrollToBottom;

@end
