
#import <CocoaHTTPServer/HTTPMessage.h>
#import "RouteRequest.h"


@implementation RouteRequest {		}	// @synthesize params;

- (id)initWithHTTPMessage:(HTTPMessage*)msg parameters:(NSDictionary*)parameters {

	return self = super.init ?	_params = parameters, _message = msg, self : nil;
}
- (NSDictionary*)headers							{	return _message.allHeaderFields;		  }
- (NSString*)header:(NSString*)field	{	return [_message headerField:field];	}

- (id)param:(NSString*)name						{	return _params[name];   }
- (NSString*) method									{	return _message.method; }
-    (NSURL*) URL											{	return _message.url;		}
-   (NSData*)	body										{	return _message.body;   }
- (NSString*) description							{	return [NSString.alloc initWithData:_message.messageData encoding:NSASCIIStringEncoding]; }

- (NSArray*) wildcards { return [self param:@"wildcards"]; }

@end

//-    (NSURL*) url											{	return message.url;	   }
