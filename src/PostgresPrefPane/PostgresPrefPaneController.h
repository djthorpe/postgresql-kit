//
//  PrefPanePref.h
//  PrefPane
//
//  Created by David Thorpe on 11/02/2009.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import "PostgresPrefPaneBindings.h"

@interface PostgresPrefPaneController : NSPreferencePane {
	NSConnection* connection;	
	NSTimer* timer;
	FLXServerState serverState;
	
	// bindings object
	IBOutlet PostgresPrefPaneBindings* bindings;	
	IBOutlet NSWindow* ibPasswordSheet;
	IBOutlet NSButton* ibStopButton;
	IBOutlet NSButton* ibStartButton;	
	IBOutlet NSButton* ibInstallButton;
	IBOutlet NSButton* ibUninstallButton;
}

// instance variables
@property (retain) NSConnection* connection;
@property (retain) NSTimer* timer;
@property (assign) FLXServerState serverState;

// IBAction
-(IBAction)doStartServer:(id)sender;
-(IBAction)doStopServer:(id)sender;
-(IBAction)doInstall:(id)sender;
-(IBAction)doUninstall:(id)sender;
-(IBAction)doPassword:(id)sender;
-(IBAction)doPasswordEndSheet:(id)sender;

@end
