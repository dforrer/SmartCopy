//
//  AppDelegate.h
//  SmartCopy
//
//  Created by Daniel on 25.08.13.
//  Copyright (c) 2013 Forrer. All rights reserved.
//

#import "CopyProcess.h"
#import "CopyObject.h"
#import "Singleton.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource>


- (void) flushLog;


@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *sourcesAndDestinations;
@property (assign) IBOutlet NSTextView *log;
@property (assign) IBOutlet NSButton * buttonAdd;
@property (assign) IBOutlet NSButton * buttonRemove;
@property (assign) IBOutlet NSButton * buttonCopy;

@property (nonatomic, readwrite, strong) NSString * settingsPath;

@property (nonatomic, readwrite, strong) NSMutableArray * folderPairs;

@property (nonatomic, readwrite) unsigned char isCopying;

@end
