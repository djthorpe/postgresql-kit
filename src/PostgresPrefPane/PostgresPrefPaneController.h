//
//  PrefPanePref.h
//  PrefPane
//
//  Created by David Thorpe on 11/02/2009.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface PostgresPrefPaneController : NSPreferencePane {
	NSConnection* connection;	
	NSTimer* timer;
	FLXServerState serverState;
	
	// IBOutlet
	IBOutlet NSTextField* ibVersionNumber;
	IBOutlet NSTextField* ibStatus;	
	IBOutlet NSTabView* ibTabView;
	IBOutlet NSImageView* ibStatusImage;
	IBOutlet NSImageView* ibRedballImage;
	IBOutlet NSImageView* ibGreenballImage;
	IBOutlet NSButton* ibStopButton;
	IBOutlet NSButton* ibStartButton;	
	IBOutlet NSButton* ibInstallButton;
	IBOutlet NSButton* ibUninstallButton;
	IBOutlet NSButton* ibRemoteAccessCheckbox;
	IBOutlet NSMatrix* ibPortMatrix;
	IBOutlet NSTextField* ibPortText;
	
}

@property (retain) NSConnection* connection;
@property (retain) NSTimer* timer;
@property (assign) FLXServerState serverState;

-(void)mainViewDidLoad;

// IBAction
-(IBAction)doStartServer:(id)sender;
-(IBAction)doStopServer:(id)sender;
-(IBAction)doInstall:(id)sender;
-(IBAction)doUninstall:(id)sender;

@end
