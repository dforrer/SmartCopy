//
//  CopyProcess.m
//  SmartCopy
//
//  Created by Daniel on 25.08.13.
//  Copyright (c) 2013 Forrer. All rights reserved.
//

#import "CopyProcess.h"



@implementation CopyProcess



@synthesize source;
@synthesize destination;
@synthesize lastSuccessfulExecution;
@synthesize arrayCopyObjects;
@synthesize isCancelled;
@synthesize dropboxCompatibleCopy;



-(id) initWithSource: (NSString*) s andDestination: (NSString*) d
{
	@autoreleasepool
	{
		// superclass creates its Object
		// self = this in java
		self = [super init];
		
		// Check if superclass could create its object
		if (self)
		{
			// checking source
			
			source = s;
			
			
			// checking destination
			
			destination = d;
			
			
			lastSuccessfulExecution = [[NSDate alloc] initWithTimeIntervalSince1970:0];
			dropboxCompatibleCopy = [NSNumber numberWithBool:FALSE];
			isCancelled = FALSE;
			
			// Init array of CopyObjects
			
			arrayCopyObjects = [[NSMutableArray alloc] init];
			
		}
		
		// return our newly created object
		return self;
	}
	
}



-(void) scanSource
{
	@autoreleasepool
	{
		NSLog(@"FUNKTION: scanSource");
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
		
		NSDirectoryEnumerator *enumerator =
		[fileManager enumeratorAtURL:[NSURL fileURLWithPath:source] includingPropertiesForKeys:keys options:0 errorHandler:^(NSURL *url, NSError *error)
		 {
			 // Handle the error.
			 // Return YES if the enumeration should continue	after the error.
			 return YES;
		 }
		 ];
		
		for (NSURL *url in enumerator)
		{
			@autoreleasepool {
				if (isCancelled)
				{
					return;
				}
				NSError *error;
				NSNumber *isDirectory = nil;
				if ( ![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error])
				{
					// handle error
					NSLog(@"scanSource: ERROR");
					isCancelled = TRUE;
				}
				else
				{
					// No error and it’s a directory or file
					// Filter out .DS_Store Files
					
					if ([[url lastPathComponent] isEqualToString:@".DS_Store"]
						||
						[FileHelper isSymbolicLink:[url path]])
					{
						continue;
					}
					if ([[url lastPathComponent] isEqualToString:@"Thumbs.db"]
						||
						[FileHelper isSymbolicLink:[url path]])
					{
						continue;
					}
					CopyObject * co = [[CopyObject alloc] initWithSource:[url path]];
					[arrayCopyObjects addObject:co];
					//NSLog(@"count: %li", (unsigned long)[arrayCopyObjects count]);
					//NSLog(@"%@", [url path]);
				}
			}
		}
	}
}



-(void) updateDestinationsOfCopyObjects:(BOOL)makeCompatible
{
	NSLog(@"updateDestinationsOfCopyObjects");
	@autoreleasepool
	{
		//NSLog(@"count: %li", (unsigned long)[arrayCopyObjects count]);
		
		for (CopyObject * co in arrayCopyObjects)
		{
			// prepare new destination path of co
			
			NSString * relativeSource = [[co source] substringFromIndex:[source length]];
			
			if (makeCompatible)
			{
				relativeSource = [self makePathCompatible:relativeSource];
			}
			
			NSString * absoluteDestination = [NSString stringWithFormat:@"%@%@", destination, relativeSource];
			[co setDestination: absoluteDestination];
			//NSLog(@"%@", absoluteDestination);
		}
	}
}



-(NSString *) makePathCompatible: (NSString *) path
{
	@autoreleasepool
	{
		
		NSMutableString * rv = [[NSMutableString alloc] init];
		
		NSArray * pathElements = [path componentsSeparatedByString:@"/"];
		
		for (int i = 0; i<[pathElements count]; i++)
		{
			if (i>0)
			{
				[rv appendString:@"/"];
			}
			
			NSString * comp = [pathElements objectAtIndex:i];
			
			while ([comp hasSuffix:@" "])
			{
				//NSLog(@"%@", comp);
				if ([comp length] == 1)
				{
					comp = @"(Leerzeichen-Konflikt)";
					break;
				}
				comp = [comp substringToIndex:[comp length] - 1];
			}
			
			while ([comp hasSuffix:@"."])
			{
				comp = [comp substringToIndex:[comp length] - 1];
			}
			comp = [[comp componentsSeparatedByCharactersInSet:[NSCharacterSet controlCharacterSet]] componentsJoinedByString:@""];
			comp = [[comp componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
			comp = [[comp componentsSeparatedByCharactersInSet:[NSCharacterSet illegalCharacterSet]] componentsJoinedByString:@""];
			
			// append to rv comp
			
			[rv appendString:comp];
			
		}
	
		return rv;
	}
}



- (void) compare
{
	@autoreleasepool
	{
		NSMutableArray *discardedItems = [NSMutableArray array];
		for (CopyObject * co in arrayCopyObjects)
		{
			if (isCancelled)
			{
				return;
			}
			
			if ([co isDirectory])
			{
				// create folder
				
				if ([FileHelper fileFolderExists:[co destination]])
				{
					[discardedItems addObject:co];
				}
			}
			else
			{
				// copy the file
			
				if ([FileHelper fileFolderExists:[co destination]] &&  [[[NSFileManager defaultManager] attributesOfItemAtPath:[co destination] error:nil] fileSize] == [co size])
				{
					// Remove file
					[discardedItems addObject:co];
				}
			}
		}
	
		// Remove discardedItems from arrayCopyObjects
		
		[arrayCopyObjects removeObjectsInArray:discardedItems];
	}
}

-(void) copyObjects
{
	@autoreleasepool
	{
		for (CopyObject * co in arrayCopyObjects)
		{
			if (isCancelled)
			{
				return;
			}
			
			if ([co isDirectory])
			{
				// create folder
				
				[[NSFileManager defaultManager] createDirectoryAtPath:[co destination] withIntermediateDirectories:YES attributes:nil error: nil];
				
			}
			else
			{
				// copy the file
				
				if ([[NSFileManager defaultManager] isReadableFileAtPath:[co source]])
				{
					NSError *error;
					if (![[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:[co source]] toURL:[NSURL fileURLWithPath:[co destination]] error:&error])
					{
						// delete file first
						[[NSFileManager defaultManager] removeItemAtPath:[co destination] error:nil];
						// retry the copying
						[[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:[co source]] toURL:[NSURL fileURLWithPath:[co destination]] error:&error];
					}
				}
			}
			
			[[[Singleton shared] logString] appendString:[[NSURL fileURLWithPath:[co destination]] absoluteString]];
			[[[Singleton shared] logString] appendString:@"\n"];
		}
	}
}

@end
