//
//  AppDelegate.m
//  SmartCopy
//
//  Created by Daniel on 25.08.13.
//  Copyright (c) 2013 Forrer. All rights reserved.
//

#import "AppDelegate.h"



@implementation AppDelegate



@synthesize folderPairs;
@synthesize isCopying;
@synthesize window;
@synthesize sourcesAndDestinations;
@synthesize log;
@synthesize buttonAdd;
@synthesize buttonRemove;
@synthesize buttonCopy;
@synthesize settingsPath;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	folderPairs = [[NSMutableArray alloc] init];
	[self loadPlist];
	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(flushLog) userInfo:nil repeats:YES];
	
}




- (void) flushLog {
	@autoreleasepool {
		if ([[[Singleton shared] logString] length] != 0){
			[self appendToMyTextView:[[[Singleton shared] logString] copy]];
			[[[Singleton shared] logString] setString:@""];
		}
		
		// Checks the NSTextView for "Smart Links" etc.
		[log checkTextInDocument:nil];
	}
}



- (void) loadPlist
{
	@autoreleasepool {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		settingsPath = [[NSString alloc] initWithString:[documentsDirectory stringByAppendingPathComponent:@"SmartCopy.plist"]];
		
		if ([fileManager fileExistsAtPath: settingsPath])
		{
			// load items into "folderPairs"
			
			NSArray * plist = [[NSArray alloc] initWithContentsOfFile: settingsPath];
			for (NSArray *item in plist)
			{
				CopyProcess * cp = [[CopyProcess alloc] initWithSource:[item objectAtIndex:0] andDestination:[item objectAtIndex:1]];
				[cp setLastSuccessfulExecution:[item objectAtIndex:2]];
				[cp setDropboxCompatibleCopy:[item objectAtIndex:3]];
				[folderPairs addObject:cp];
			}
			[sourcesAndDestinations reloadData];
		}
		else
		{
			// If the file doesn’t exist, create an empty array
			folderPairs = [[NSMutableArray alloc] init];
		}
	}
}



- (void) saveToPlist
{	@autoreleasepool {
	NSMutableArray * plist = [[NSMutableArray alloc] init];
	for (CopyProcess * cp in folderPairs)
	{
		NSMutableArray * item = [[NSMutableArray alloc] init];
		[item addObject:[cp source]];
		[item addObject:[cp destination]];
		[item addObject:[cp lastSuccessfulExecution]];
		[item addObject:[cp dropboxCompatibleCopy]];
		[plist addObject:item];
	}
	[plist writeToFile:settingsPath atomically:TRUE];
}
}



- (IBAction) addRow:(id)sender
{
	@autoreleasepool {
		NSLog(@"addRow");
		
		// SOURCE - Window
		
		NSURL *urlSource;
		
		// Create the File Open Dialog class.
		NSOpenPanel * openDlg   = [NSOpenPanel openPanel];
		[openDlg setTitle:@"Select the source folder..."];
		[openDlg setCanChooseFiles:NO];
		[openDlg setCanChooseDirectories:YES];
		[openDlg setAllowsMultipleSelection:NO];
		[openDlg setCanCreateDirectories:YES];
		[NSApp activateIgnoringOtherApps:YES]; // Activates the openDlg-Window
		
		// Display the dialog. If the OK button was pressed,
		// process the files.
		
		/*
		 
		[openDlg beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
			
			if (result == NSFileHandlingPanelOKButton)
			{
				NSLog(@"panel");
				//urlSource = [openDlg URL];
			}
		}];
		
		 */
		if ( [openDlg runModal] == NSOKButton )
		{
			urlSource = [openDlg URL];
		}
		else
		{
			return;
		}
		
		// DESTINATION - Window
		
		NSURL *urlDestination;
		
		// Create the File Open Dialog class.
		openDlg   = [NSOpenPanel openPanel];
		[openDlg setCanChooseFiles:NO];
		[openDlg setCanChooseDirectories:YES];
		[openDlg setAllowsMultipleSelection:NO];
		[openDlg setCanCreateDirectories:YES];
		[openDlg setTitle:@"Select the destination folder..."];
		[NSApp activateIgnoringOtherApps:YES]; // Activates the openDlg-Window
		
		// Display the dialog. If the OK button was pressed,
		// process the files.
		if ( [openDlg runModal] == NSOKButton )	{
			urlDestination = [openDlg URL];
		} else {
			return;
		}
		
		CopyProcess * cp = [[CopyProcess alloc] initWithSource:[urlSource path] andDestination:[urlDestination path]];
		
		
		[folderPairs addObject:cp];
		
		// updating the NSTableView
		
		[sourcesAndDestinations reloadData];
		
		// saving the folderPairs to disk
		
		[self saveToPlist];
	}
}



- (IBAction) removeRow:(id)sender
{
	@autoreleasepool {
		NSLog(@"removeRow");
		NSInteger row = [sourcesAndDestinations selectedRow];
		if (row != -1)
		{
			[folderPairs removeObjectAtIndex:row];
			[sourcesAndDestinations reloadData];
		}
		
		// saving the folderPairs to disk
		
		[self saveToPlist];
	}
}



- (void) executeCopyProcesses
{
	@autoreleasepool {
		isCopying = YES;
		[buttonCopy setImage:[NSImage imageNamed:@"NSStopProgressTemplate"]];

		for (CopyProcess * cp in folderPairs)
		{
			@autoreleasepool {
				[[[Singleton shared] logString] appendString:@"————————————————————————————\n"];
				[[cp arrayCopyObjects] removeAllObjects];
				if (![FileHelper fileFolderExists:[cp source]])
				{
					[[[Singleton shared] logString] appendString:[NSString stringWithFormat:@"Source doesn't exist: %@\n", [cp source]]];
					continue;
				}
				if (![FileHelper fileFolderExists:[cp destination]])
				{
					[[NSFileManager defaultManager] createDirectoryAtPath:[cp destination] withIntermediateDirectories:YES attributes:nil error: nil];
				}
				[[[Singleton shared] logString] appendString:[NSString stringWithFormat:@"Scanning source: %@\n", [cp source]]];
				
				
				[cp scanSource];
				if ([cp isCancelled])
				{
					[[[Singleton shared] logString] appendString:[NSString stringWithFormat:@"Error while scanning source: %@\n", [cp source]]];
					continue;
				}
				[[[Singleton shared] logString] appendString:[NSString stringWithFormat:@"%li Files/Folders scanned\n", [[cp arrayCopyObjects] count]]];
				
				[cp updateDestinationsOfCopyObjects:[[cp dropboxCompatibleCopy] boolValue]];
				
				[cp compare];
				[[[Singleton shared] logString] appendString:[NSString stringWithFormat:@"%li Folders to create/Files to copy\n", [[cp arrayCopyObjects] count]]];
				
				if ([[cp arrayCopyObjects] count] == 0)
				{
					[[[Singleton shared] logString] appendString:@"Folders are in sync!\n"];
					[cp setLastSuccessfulExecution: [NSDate  date]];
					[[cp arrayCopyObjects] removeAllObjects];
					continue;
				}
				
				[[[Singleton shared] logString] appendString:@"Start copying files...\n\n"];
				[cp copyObjects];
				
				if ([cp isCancelled])
				{
					[[[Singleton shared] logString] appendString:@"\nCopying cancelled.\n"];
					
					continue;
				}
				
				[[[Singleton shared] logString] appendString:@"\nCopying finished!\n"];
				[cp setLastSuccessfulExecution: [NSDate  date]];
				[sourcesAndDestinations reloadData];
			}
		}
		isCopying = NO;
		[buttonCopy setImage:[NSImage imageNamed:@"NSRefreshTemplate"]];
		[sourcesAndDestinations reloadData];
	}
}


- (IBAction) clearLog:(id)sender
{
	@autoreleasepool {
		dispatch_async(dispatch_get_main_queue(), ^{
			
			// IMPORTENT: How to set the font of an NSTextView-Element
			
			[log setString:@""];
		});
	}
}


- (IBAction) copyButtonPressed:(id)sender
{
	@autoreleasepool {
		NSLog(@"startCopying");
		
		if (isCopying)
		{
			
			for (CopyProcess *cp in folderPairs)
			{
				[cp setIsCancelled:YES];
			}
			
		} else {
			
			for (CopyProcess *cp in folderPairs)
			{
				[cp setIsCancelled:NO];
			}
			
			[self performSelectorInBackground:@selector(executeCopyProcesses) withObject:nil];
			
		}
		// saving the folderPairs to disk
		
		[self saveToPlist];
	}
}



- (void)appendToMyTextView:(NSString*)text
{
	@autoreleasepool {
		dispatch_async(dispatch_get_main_queue(), ^{
			
			// IMPORTENT: How to set the font of an NSTextView-Element
			
			NSFont *font = [NSFont fontWithName:@"Monaco" size:11.0];
			NSDictionary *attrsDictionary =
			[NSDictionary dictionaryWithObject:font
										forKey:NSFontAttributeName];
			NSAttributedString* attr = [[NSAttributedString alloc] initWithString:text attributes:attrsDictionary];
			
			[[log textStorage] appendAttributedString:attr];
			[log scrollRangeToVisible:NSMakeRange([[log string] length], 0)];
		});
	}
}



/**
 * OVERRIDE
 */
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	return (long)[folderPairs count];
}



/**
 * OVERRIDE: Getter for NSTableView
 */
- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	@autoreleasepool {
		CopyProcess * dataObject = (CopyProcess *)
		[folderPairs objectAtIndex:rowIndex];
		if (! dataObject)
		{
			NSLog(@"tableView: objectAtIndex:%ld = NULL",(long)rowIndex);
			return NULL;
		}
		
		//NSLog(@"pTableColumn identifier = %@",[aTableColumn identifier]);
		
		if ([[aTableColumn identifier] isEqualToString:@"Source"])
		{
			return [dataObject source];
		}
		
		if ([[aTableColumn identifier] isEqualToString:@"Destination"])
		{
			return [dataObject destination];
		}
		
		if ([[aTableColumn identifier] isEqualToString:@"Dropbox compatible copy"])
		{
			return [dataObject dropboxCompatibleCopy];
		}
		if ([[aTableColumn identifier] isEqualToString:@"Last Successful Execution"])
		{
			if ([[dataObject lastSuccessfulExecution] isEqualToDate:[[NSDate alloc] initWithTimeIntervalSince1970:0]])
			{
				return @"never";
			}
			
			
			NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:[dataObject lastSuccessfulExecution]];
			
			//NSLog(@"%f", interval);
			
			if (interval < 60) {
				return @"less than 1 minute ago";
			}
			if (interval < 3600) {
				return [NSString stringWithFormat:@"%i minutes ago", (int)(interval/60+1)];
			}
			
			
			NSString * currDate = [NSString stringWithCString:[[[dataObject lastSuccessfulExecution]
																descriptionWithCalendarFormat:@"%y/%m/%d - %H:%M:%S" timeZone:nil
																locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]]
															   UTF8String] encoding:NSUTF8StringEncoding];
			return currDate;
			
			
		}
		NSLog(@"***ERROR** dropped through pTableColumn identifiers");
		
		return NULL;
	}
}

/**
 * OVERRIDE: Set values of table
 */
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	@autoreleasepool {
		CopyProcess * cp = [folderPairs objectAtIndex:rowIndex];
		if ([[aTableColumn identifier] isEqualToString:@"Source"])
		{
			[cp setSource:anObject];
		}
		
		if ([[aTableColumn identifier] isEqualToString:@"Destination"])
		{
			[cp setDestination:anObject];
		}
		
		if ([[aTableColumn identifier] isEqualToString:@"Dropbox compatible copy"])
		{
			[cp setDropboxCompatibleCopy:anObject];
		}
		
		[sourcesAndDestinations reloadData];
	}
}

/**
 * Terminates the App when the window is
 * closed. It does not have to be linked
 * up, in the .xib-File
 */
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)theApplication
{
	[self saveToPlist];
	return YES;
}



@end
