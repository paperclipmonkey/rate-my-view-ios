//
//  DAReachability.h
//  ADHD Angel
//
//  Created by Daniel Anderton on 31/12/2012.
//  Copyright (c) 2012 Daniel Anderton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>


#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000 // iOS 6.0 or later
#define NEEDS_DISPATCH_RETAIN_RELEASE 0
#else                                         // iOS 5.X or earlier
#define NEEDS_DISPATCH_RETAIN_RELEASE 1
#endif

/**
 DAReachability: Reachabilty controller. Tells the application if we have network or not. Based on Apples documentation
 */

NSString *const kReachabilityChangedNotification;

typedef enum
{
	// Apple NetworkStatus Compatible Names.
	NotReachable     = 0,
	ReachableViaWiFi = 2,
	ReachableViaWWAN = 1
} NetworkStatus;


@interface DAReachability : NSObject

typedef void (^NetworkReachable)(DAReachability * reachability);
typedef void (^NetworkUnreachable)(DAReachability * reachability);


@property (nonatomic, copy) NetworkReachable    reachableBlock;
@property (nonatomic, copy) NetworkUnreachable  unreachableBlock;


@property (nonatomic, assign) BOOL reachableOnWWAN;

+(DAReachability*)reachabilityWithHostname:(NSString*)hostname;
+(DAReachability*)reachabilityForInternetConnection;
+(DAReachability*)reachabilityWithAddress:(const struct sockaddr_in*)hostAddress;
+(DAReachability*)reachabilityForLocalWiFi;

-(DAReachability *)initWithReachabilityRef:(SCNetworkReachabilityRef)ref;

-(BOOL)startNotifier;
-(void)stopNotifier;

-(BOOL)isReachable;
-(BOOL)isReachableViaWWAN;
-(BOOL)isReachableViaWiFi;

// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
-(BOOL)isConnectionRequired; // Identical DDG variant.
-(BOOL)connectionRequired; // Apple's routine.



-(NetworkStatus)currentReachabilityStatus;
-(SCNetworkReachabilityFlags)reachabilityFlags;
-(NSString*)currentReachabilityString;
-(NSString*)currentReachabilityFlags;

@end
