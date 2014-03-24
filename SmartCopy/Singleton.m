
#import "Singleton.h"

@implementation Singleton

@synthesize logString;
@synthesize myQueue;

#pragma mark -----------------------
#pragma mark Singleton Methods




- (id) init
{
	if (self = [super init])
	{
		logString	= [[NSMutableString alloc] init];
		myQueue	= [[NSOperationQueue alloc] init];
	}
	return self;
}




+ (id) shared
{
    static Singleton *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}




@end