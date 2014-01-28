
#import "RoutingHTTPServer.h"


@interface Route : NSObject

@property (nonatomic)              NSArray * keys;
@property (nonatomic)  NSRegularExpression * regex;
@property (nonatomic)                  SEL   selector;
@property (NATOMICWEAK)                 id   target;
@property (nonatomic,copy)  RequestHandler   handler;


@end
