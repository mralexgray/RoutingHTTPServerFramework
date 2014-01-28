
#import <CocoaHTTPServer/HTTPMessage.h>
#import "RoutingConnection.h"
#import "RoutingHTTPServer.h"
#import "HTTPResponseProxy.h"

@implementation RoutingConnection	@synthesize headers;

- (RoutingHTTPServer*) router { return (RoutingHTTPServer*)self.config.server; }

- (id)initWithAsyncSocket:(GCDAsyncSocket*)newSocket configuration:(HTTPConfig*)aConfig {

	if (self = [super initWithAsyncSocket:newSocket configuration:aConfig])
		NSAssert([self.router isKindOfClass:RoutingHTTPServer.class],
				 @"A RoutingConnection is being used with a server that is not a RoutingHTTPServer");
//		http = (RoutingHTTPServer *)config.server;
	return self;
}

- (BOOL)supportsMethod:(NSString*)method atPath:(NSString *)path {

	return [self.router supportsMethod:method] ?: [super supportsMethod:method atPath:path];
}

/** The default implementation is strict about the use of Content-Length. Either a given method + path combination must *always* include
		data or *never* include data. The routing connection is lenient, a POST that sometimes does not include data or a GET that sometimes
		does is fine. It is up to the route implementations to decide how to handle these situations. */

-    (BOOL) shouldHandleRequestForMethod:(NSString*)method atPath:(NSString*)path { return YES; } // YES

-    (void) processBodyData:(NSData*)postDataChunk {  if (![request appendData:postDataChunk])  { /* TODO: Log */ } }

- (NSObject<HTTPResponse>*) httpResponseForMethod:(NSString *)method URI:(NSString *)path {  // Don't mess with it, for now.

				       headers = nil;
	NSURL           *url = request.url;
	NSString      *query = nil;
	NSDictionary *params = NSDictionary.new;

	if (url) {		  path = url.path; // Strip the query string from the path
								 query = url.query;
		if (query) 	params = [self parseParams:query];
	}
	RouteResponse *response = [self.router routeMethod:method withPath:path parameters:params request:request connection:self];
	if (response != nil) {	headers = response.headers;	return response.proxiedResponse;	}

	// Set a MIME type for static files if possible
	NSObject<HTTPResponse> *staticResponse = [super httpResponseForMethod:method URI:path];
	if (staticResponse && [staticResponse respondsToSelector:@selector(filePath)]) {
		NSString *mimeType = [self.router mimeTypeForPath:[staticResponse performSelector:@selector(filePath)]];
		if (mimeType) headers = [NSDictionary dictionaryWithObject:mimeType forKey:@"Content-Type"];
	}
	return staticResponse;
}

-    (void) responseHasAvailableData:(NSObject<HTTPResponse>*)sender {

	if (((HTTPResponseProxy*)httpResponse).response == sender) [super responseHasAvailableData:httpResponse]; // httpResponse = proxy
}
-    (void) responseDidAbort:				 (NSObject<HTTPResponse>*)sender {
	if (((HTTPResponseProxy *)httpResponse).response == sender) [super responseDidAbort:httpResponse];  // httpResponse = proxy
}
-    (void) setHeadersForResponse:	 (HTTPMessage*)response isError:(BOOL)isError {

	[self.router.defaultHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL*stop){ [response setHeaderField:field value:value];	}];
	if (headers && !isError)
		[headers					 enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL*stop){ [response setHeaderField:field value:value]; }];

	if (![response headerField:@"Connection"]) 	// Set the connection header if not already specified
		[response setHeaderField:@"Connection" value:self.shouldDie ? @"close" : @"keep-alive"];
}
- (NSData*) preprocessResponse:			 (HTTPMessage*)response {

//	NSLog(@"right now I could preprocess: %@", [NSString.alloc initWithData:response.body encoding:NSUTF8StringEncoding]);

	return 	[self setHeadersForResponse:response isError:NO], [super preprocessResponse:response];
}
- (NSData*) preprocessErrorResponse: (HTTPMessage*)response {

	return 	[self setHeadersForResponse:response isError:YES], [super preprocessErrorResponse:response];
}
-    (BOOL) shouldDie {	__block BOOL shouldDie; if (((shouldDie = super.shouldDie)) || headers == nil) return shouldDie;

	// Allow custom headers to determine if the connection should be closed
	[headers enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
		if ([field caseInsensitiveCompare:@"connection"] != NSOrderedSame) return;
		shouldDie = [value caseInsensitiveCompare:@"close"] == NSOrderedSame;
		*stop = YES;
	}];
	return shouldDie;
}

@end
