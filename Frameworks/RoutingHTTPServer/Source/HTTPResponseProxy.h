
#import <CocoaHTTPServer/HTTPResponse.h>

//	Wraps an HTTPResponse object to allow setting a custom status code
//	without needing to create subclasses of every response.

@interface HTTPResponseProxy : NSObject <HTTPResponse>

@property (nonatomic) NSObject<HTTPResponse> * response;
@property (nonatomic)								NSInteger  status;
@property  (readonly)							  NSInteger  customStatus;

@end
