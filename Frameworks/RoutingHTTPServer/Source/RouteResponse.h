
#import <CocoaHTTPServer/HTTPResponse.h>

//@class HTTPConnection, HTTPResponseProxy;

@interface RouteResponse : NSObject

@property (assign,readonly)						 HTTPConnection * connection;
@property (readonly)										 NSDictionary * headers;
@property (nonatomic,strong)	 NSObject<HTTPResponse> * response;
@property (readonly)					 NSObject<HTTPResponse> * proxiedResponse;
@property (nonatomic)											  NSInteger   statusCode;

-   (id) initWithConnection:(HTTPConnection*)theConnection;

- (void) respondWithData:    (NSData*)data;
- (void) respondWithFile:    (NSString*)path;
- (void) respondWithString:  (NSString*)string;
- (void) setHeader:          (NSString*)field	    value:(NSString *)value;
- (void) respondWithFile:    (NSString*)path			async:(BOOL)async;
- (void) respondWithString:  (NSString*)string encoding:(NSStringEncoding)encoding;

@end
