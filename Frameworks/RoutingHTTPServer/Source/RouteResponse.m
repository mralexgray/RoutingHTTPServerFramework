
#import "RoutingConnection.h"
#import "RouteResponse.h"
#import "RoutingHTTPServer.h"
#import "HTTPResponseProxy.h"

#import <CocoaHTTPServer/HTTPConnection.h>
#import <CocoaHTTPServer/HTTPDataResponse.h>
#import <CocoaHTTPServer/HTTPFileResponse.h>
#import <CocoaHTTPServer/HTTPAsyncFileResponse.h>

@implementation RouteResponse {	NSMutableDictionary *headers;	HTTPResponseProxy *proxy; } @synthesize connection, headers; 


- (id)initWithConnection:(HTTPConnection *)theConnection {	return self = super.init ?

	connection = theConnection, headers = NSMutableDictionary.new,	proxy = HTTPResponseProxy.new, self : nil;
}

- (NSObject <HTTPResponse>*)response {	return proxy.response; }

- (void)setResponse:(NSObject <HTTPResponse>*)response {	proxy.response = response; }

- (NSObject <HTTPResponse>*)proxiedResponse { return proxy.response || proxy.customStatus || headers.count ? proxy : nil; }

- (NSInteger)statusCode {	return proxy.status; }

- (void)setStatusCode:(NSInteger)status {	proxy.status = status; }

- (void)setHeader:(NSString *)field value:(NSString *)value {	[headers setObject:value forKey:field]; }

- (void)respondWithString:(NSString *)string {	[self respondWithString:string encoding:NSUTF8StringEncoding]; }

- (void)respondWithString:(NSString *)string encoding:(NSStringEncoding)encoding {	[self respondWithData:[string dataUsingEncoding:encoding]]; }

- (void)respondWithData:(NSData *)data {	self.response = [HTTPDataResponse.alloc initWithData:data]; }

- (void)respondWithFile:(NSString *)path { [self respondWithFile:path async:NO]; }

- (void)respondWithFile:(NSString *)path async:(BOOL)async {

		self.response = async ? [HTTPAsyncFileResponse.alloc initWithFilePath:path forConnection:connection]
													: [HTTPFileResponse.alloc initWithFilePath:path forConnection:connection];
}

@end
