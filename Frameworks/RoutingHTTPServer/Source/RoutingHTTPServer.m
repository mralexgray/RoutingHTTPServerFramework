
#import "RoutingHTTPServer.h"
#import "RoutingConnection.h"
#import "Route.h"
#import <objc/message.h>

NSString * StringWithTrailingSlash(NSString* str){ return [str hasSuffix:@"/"] ? str : [str stringByAppendingString:@"/"]; }

@implementation RoutingHTTPServer { NSMutableDictionary *routes, *defaultHeaders;	dispatch_queue_t routeQueue; } @synthesize defaultHeaders;

- (BOOL) start:(NSError *__autoreleasing *)e { NSString *app = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];

	NSLog(@"Publishing to name: %@", app);
	[self setName:app ?: @"Bonjour App"];
	[self setType:@"_http._tcp."]; return [super start:e]; }

- (void) setDocumentRoot:(NSString*)dRoot { [super setDocumentRoot:dRoot.stringByResolvingSymlinksInPath.stringByStandardizingPath]; }

-   (id) init {	if (self != super.init) return nil;

	connectionClass = RoutingConnection.class;//[RoutingConnection self];
	routes					= NSMutableDictionary.new;
	defaultHeaders	= NSMutableDictionary.new;
	_mimeTypes  = @{
		@"js"			: @"application/x-javascript",
		@"gif"		: @"image/gif",
		@"jpg"		: @"image/jpeg",
		@"jpeg"		: @"image/jpeg",
		@"png"		: @"image/png",
		@"svg"		: @"image/svg+xml",
		@"tif"		: @"image/tiff",
		@"tiff"		: @"image/tiff",
		@"ico"		:	@"image/x-icon",
		@"bmp"		: @"image/x-ms-bmp",
		@"css"		: @"text/css",
		@"html"		: @"text/html",
		@"htm"		: @"text/html",
		@"txt"		: @"text/plain",
		@"xml"		: @"text/xml"}.mutableCopy;
	return self;
}

- (void) setDefaultHeaders:(NSDictionary*)hdrs	{	defaultHeaders = hdrs ? hdrs.mutableCopy : NSMutableDictionary.new; }

- (void) setDefaultHeader:(NSString*)f value:(NSString*)v	{ defaultHeaders[f] = v; }

- (dispatch_queue_t) routeQueue									{ return routeQueue; }

- (void) setRouteQueue:(dispatch_queue_t)queue	{
#if !OS_OBJECT_USE_OBJC_RETAIN_RELEASE
	if (queue)dispatch_retain(queue);if (routeQueue)dispatch_release(routeQueue);
#endif
	routeQueue = queue;
}

- (void) setMIMETypes:(id)types			{	_mimeTypes = (types) ? [types mutableCopy] : @{}.mutableCopy; }

- (void) setMIMEType:(NSString*)theType forExtension:(NSString*)ext {	_mimeTypes[ext] = theType; }

- (NSString*) mimeTypeForPath:(NSString *)path {	NSString *ext = path.pathExtension.lowercaseString;

	return !ext || !ext.length ? nil : self.mimeTypes[ext];
}

- (void) proxy: (NSString*)path via:(NSString*)other {

}
- (void) get:		 (NSString*)path withBlock:(RequestHandler)block	{	[self handleMethod:@"GET"    withPath:path block:block]; }
- (void) post:	 (NSString*)path withBlock:(RequestHandler)block	{	[self handleMethod:@"POST"   withPath:path block:block]; }
- (void) put:		 (NSString*)path withBlock:(RequestHandler)block	{	[self handleMethod:@"PUT"    withPath:path block:block]; }
- (void) delete: (NSString*)path withBlock:(RequestHandler)block	{	[self handleMethod:@"DELETE" withPath:path block:block]; }

-   (void) handleMethod:  (NSString*)method withPath:(NSString*)path target:(id)target selector:(SEL)selector { Route *route;

  (route = [self routeWithPath:path]).target = target;	route.selector = selector;	[self addRoute:route forMethod:method];
}
-   (void) handleMethod:  (NSString*)method withPath:(NSString*)path  block:(RequestHandler)block							{	Route *route;

	(route = [self routeWithPath:path]).handler = block; [self addRoute:route forMethod:method];
}
-   (void) addRoute:		     (Route*)route forMethod:(NSString*)method																				{

	[routes[method = method.uppercaseString] ?:	(routes[method] = NSMutableArray.new) addObject:route];
	[method isEqualToString:@"GET"] ? [self addRoute:route forMethod:@"HEAD"] : nil; 	// Define a HEAD route for all GET routes
}

-   (BOOL) supportsMethod:(NSString*)method {	return [routes objectForKey:method] != nil;	}		// Just a check if its in dict.

- (Route*) routeWithPath: (NSString*)path		{	Route *route = Route.new;	NSMutableArray *keys = NSMutableArray.new;

	if (path.length > 2 && [path characterAtIndex:0] == '{')
		path = [path substringWithRange:NSMakeRange(1, path.length - 2)]; 		// This is a custom regular expression, just remove the {}

	else {

		// Escape regex characters
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[.+()]" options:0 error:nil];
		path = [regex stringByReplacingMatchesInString:path options:0 range:NSMakeRange(0, path.length) withTemplate:@"\\\\$0"];

		// Parse any :parameters and * in the path
		regex = [NSRegularExpression regularExpressionWithPattern:@"(:(\\w+)|\\*)" options:0 error:nil];
		NSMutableString *regexPath = path.mutableCopy;
		__block NSInteger diff = 0;
		[regex enumerateMatchesInString:path options:0 range:NSMakeRange(0, path.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {

				NSRange replacementRange											= NSMakeRange(diff + result.range.location, result.range.length);
				NSString *replacementString, *capturedString	= [path substringWithRange:result.range];

				if	([capturedString isEqualToString:@"*"]) {
					[keys addObject:@"wildcards"];
					replacementString = @"(.*?)";
				} else {
					[keys addObject:[path substringWithRange:[result rangeAtIndex:2]]]; /* keystring */
					replacementString = @"([^/]+)";
				}
				[regexPath replaceCharactersInRange:replacementRange withString:replacementString];
				diff += replacementString.length - result.range.length;
		}];
		path = [NSString stringWithFormat:@"^%@$", regexPath];
	}
	route.regex = [NSRegularExpression regularExpressionWithPattern:path options:NSRegularExpressionCaseInsensitive error:nil];
	route.keys = keys.count ? keys : route.keys;
	return route;

}		// Meat + Potatoes

-   (void) handleRoute:(Route*)route withRequest:(RouteRequest*)request response:(RouteResponse*)response {

	if (route.handler) { route.handler(request, response); return; }
	objc_msgSend(route.target, route.selector,request,response,nil);
}

- (RouteResponse*) routeMethod:(NSString*)method withPath:(NSString*)path parameters:(NSDictionary*)params
											 request:(HTTPMessage*)httpMessage                  connection:(HTTPConnection *)connection {

	NSMutableArray *methodRoutes; if (!(methodRoutes = [routes objectForKey:method]))	return nil;

	for (Route *route in methodRoutes) {	NSTextCheckingResult *result;

		if (!( result = [route.regex firstMatchInString:path options:0 range:NSMakeRange(0, path.length)])) continue;
		NSUInteger captureCount = result.numberOfRanges; 		// The first range is all of the text matched by the regex.
		if (route.keys) {
			// Add the route's parameters to the parameter dictionary, accounting for the first range containing the matched text.
			if (captureCount == [route.keys count] + 1) {
				NSMutableDictionary *newParams = params.mutableCopy;
				NSUInteger							 index = 1;
				BOOL						 firstWildcard = YES;
				for (NSString *key in route.keys) {							    NSString   *capture = [path substringWithRange:[result rangeAtIndex:index]];
					if ([key isEqualToString:@"wildcards"]) {		NSMutableArray *wildcards = newParams[key];
						if (firstWildcard) {	newParams[key] = (wildcards = NSMutableArray.new);	firstWildcard = NO; } // Create a new array and replace any existing object with the same key
						[wildcards addObject:capture];
					} else [newParams setObject:capture forKey:key];				index++;
				}
				params = newParams;
			}
		} else if (captureCount > 1) {	// For custom regular expressions place the anonymous captures in the captures parameter
			NSMutableDictionary *newParams = params.mutableCopy;
			NSMutableArray			 *captures = NSMutableArray.new;
			for (NSUInteger i = 1; i < captureCount; i++) [captures addObject:[path substringWithRange:[result rangeAtIndex:i]]];
													 newParams[@"captures"] = captures;	params = newParams;
		}
		RouteRequest   *request	= [RouteRequest.alloc  initWithHTTPMessage:httpMessage parameters:params];
		RouteResponse *response = [RouteResponse.alloc initWithConnection:connection];

		return					 !routeQueue  ?												[self handleRoute:route withRequest:request response:response]:
				dispatch_sync(routeQueue, ^{	@autoreleasepool {	[self handleRoute:route withRequest:request response:response];		}	}), response;
	}
	return nil;
}

#if !OS_OBJECT_USE_OBJC_RETAIN_RELEASE
- (void)dealloc {	if (routeQueue)	dispatch_release(routeQueue); }
#endif

@end

//	#pragma clang diagnostic push
//	#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//	[route.target performSelector:route.selector withObject:request withObject:response];
//	#pragma clang diagnostic pop
