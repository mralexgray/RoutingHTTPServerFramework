
#import <CocoaHTTPServer/HTTPConnection.h>

@class				      	RoutingHTTPServer ;
@interface            RoutingConnection : HTTPConnection
@property  (readonly) RoutingHTTPServer * router;
@property			             NSDictionary * headers;
@end
