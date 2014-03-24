//
//  CopyProcess.h
//  SmartCopy
//
//  Created by Daniel on 25.08.13.
//  Copyright (c) 2013 Forrer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileHelper.h"
#import "CopyObject.h"
#import "Singleton.h"

@interface CopyProcess : NSObject



-(id) initWithSource: (NSString*) s andDestination: (NSString*) d;
-(void) scanSource;
-(void) updateDestinationsOfCopyObjects:(BOOL)makeCompatible;
-(void) compare;
-(void) copyObjects;



@property (nonatomic, readwrite, strong) NSMutableArray * arrayCopyObjects;
@property (nonatomic, readwrite, strong) NSString * source;
@property (nonatomic, readwrite, strong) NSString * destination;
@property (nonatomic, readwrite, strong) NSDate * lastSuccessfulExecution;
@property (nonatomic, readwrite) unsigned char isCancelled;
@property (nonatomic, readwrite, strong) NSNumber * dropboxCompatibleCopy;

@end
