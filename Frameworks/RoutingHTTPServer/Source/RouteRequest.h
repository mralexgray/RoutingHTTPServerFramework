

@class			HTTPMessage ;
@interface RouteRequest : NSObject

-        (id) initWithHTTPMessage:(HTTPMessage*)msg parameters:(NSDictionary*)params;

@property HTTPMessage *message;

- (NSString*) header:(NSString*)field;
-        (id) param: (NSString*)name;

@property (readonly)     NSString * method;
@property (readonly)        NSURL * URL;
@property (readonly)       NSData * body;
@property (readonly) NSDictionary * headers,
																	* params;

@property (readonly)      NSArray * components, *wildcards;

@end
