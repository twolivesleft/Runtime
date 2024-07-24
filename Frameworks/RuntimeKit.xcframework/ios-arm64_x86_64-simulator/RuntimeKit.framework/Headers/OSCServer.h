#import <Foundation/Foundation.h>
#import <Tools/Tools.h>

#import <RuntimeKit/OSCMessage.h>

@protocol OSCServerDelegate <NSObject>

- (void)handleMessage:(OSCMessage*)message;

@end

@interface OSCServer : NSObject <GCDAsyncUdpSocketDelegate>

@property (strong) id <OSCServerDelegate> delegate;

@property (readonly) NSString *host;

- (BOOL)listen:(NSInteger)port error:(NSError**)error;
- (void)stop;

@end
