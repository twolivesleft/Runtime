#import <Foundation/Foundation.h>
#import <Tools/Tools.h>

#import <RuntimeKit/OSCMessage.h>

@interface OSCClient : NSObject <GCDAsyncUdpSocketDelegate>

- (void)sendMessage:(OSCMessage*)message to:(NSString*)uri;
- (void)sendMessages:(NSArray*)messages to:(NSString*)uri;

@property (readonly) NSString *host;

@end
