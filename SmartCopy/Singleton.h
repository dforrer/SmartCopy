
#import <foundation/Foundation.h>



@interface Singleton : NSObject

@property (nonatomic, readwrite, strong) NSMutableString *logString;
@property (nonatomic, readonly , strong) NSOperationQueue * myQueue;

+ (id) shared;

@end