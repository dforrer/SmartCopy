//
//  CopyObject.m
//  SmartCopy
//
//  Created by Daniel on 25.08.13.
//  Copyright (c) 2013 Forrer. All rights reserved.
//

#import "CopyObject.h"

@implementation CopyObject


@synthesize source;
@synthesize destination;
@synthesize isDirectory;
@synthesize size;


- (id) initWithSource: (NSString*) s
{
	@autoreleasepool {
		
		// superclass creates its Object
		// self = this in java
		self = [super init];
		
		// Check if superclass could create its object
		if (self)
		{
			source = s;
			if ([FileHelper isDirectory:s])
			{
				size = 0;
				isDirectory = 1;
			}else{
				size = [[[NSFileManager defaultManager] attributesOfItemAtPath:source error:nil] fileSize];
				isDirectory = 0;
			}
		}
		
		// return our newly created object
		return self;
	}
}



@end
