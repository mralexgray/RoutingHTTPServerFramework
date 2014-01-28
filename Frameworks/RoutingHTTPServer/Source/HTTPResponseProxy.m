
#import "HTTPResponseProxy.h"

@implementation HTTPResponseProxy

-      (void) forwardInvocation:(NSInvocation*)inv { // if our "response" can handle it.. do so

	[_response respondsToSelector:inv.selector] ? [inv invokeWithTarget:_response]
                                              : [super forwardInvocation:inv];
}  // Forward all other invocations to the actual response object
-      (BOOL) respondsToSelector:(SEL)sel          {

  return [super respondsToSelector:sel] ?: [_response respondsToSelector:sel];
}

- (NSInteger) customStatus                    { return _status;                                          }
-    (UInt64) contentLength                   {	return _response ?  _response.contentLength	      :   0; }		 /* Implement the required HTTPResponse methods */
-    (UInt64) offset                          { return _response ?  _response.offset              :   0; }
-      (void) setOffset:(UInt64)off           {        _response ? [_response setOffset:off]      : nil; }
-   (NSData*) readDataOfLength:(NSUInteger)l	{ return _response ? [_response readDataOfLength:l] : nil; }
-      (BOOL) isDone													{ return _response ?  _response.isDone							: YES; }
- (NSInteger) status                          { return _status   ?: [_response respondsToSelector:@selector(status)]
                                                                 ?   _response.status : 200;
}

@end


//-      (void) setStatus:(NSInteger)sCode	{ status = sCode; }
// @synthesize response, status;