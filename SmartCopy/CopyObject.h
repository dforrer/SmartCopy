//
//  CopyObject.h
//  SmartCopy
//
//  Created by Daniel on 25.08.13.
//  Copyright (c) 2013 Forrer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileHelper.h"


@interface CopyObject : NSObject



- (id) initWithSource: (NSString*) s;



@property (nonatomic, readwrite, strong) NSString * source;
@property (nonatomic, readwrite, strong) NSString * destination;
@property (nonatomic, readwrite) unsigned char isDirectory;
@property (nonatomic, readwrite) unsigned long long size;



@end
