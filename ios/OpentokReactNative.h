#import <Foundation/Foundation.h>

// This interface is specifically for Swift consumption
// The C++ interface is declared in OpentokNewArch.mm
@interface OpentokReactNative : NSObject

// Swift-accessible event emitter methods
- (void)emitOnConnectionCreated:(NSDictionary *)value;
- (void)emitOnConnectionDestroyed:(NSDictionary *)value;
- (void)emitOnSessionConnected:(NSDictionary *)value;
- (void)emitOnSessionDisconnected:(NSDictionary *)value;
- (void)emitOnSessionReconnecting:(NSDictionary *)value;
- (void)emitOnSessionReconnected:(NSDictionary *)value;
- (void)emitOnStreamCreated:(NSDictionary *)value;
- (void)emitOnStreamDestroyed:(NSDictionary *)value;
- (void)emitOnSignalReceived:(NSDictionary *)value;
- (void)emitOnSessionError:(NSDictionary *)value;
- (void)emitOnStreamPropertyChanged:(NSDictionary *)value;
- (void)emitOnMuteForced:(NSDictionary *)value;
- (void)emitOnArchiveStarted:(NSDictionary *)value;
- (void)emitOnArchiveStopped:(NSDictionary *)value;

@end
