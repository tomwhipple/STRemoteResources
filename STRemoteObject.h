//
//  RemoteObject.h
//
//  Created by Tom Whipple on 12/20/10.
//  Copyright 2010 Smartovation Technologies, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kRemoteObjectUpdatedNotification    @"RemoteObjectUpdated"
#define kRemoteObjectLoadFailedNotification @"RemoteObjectLoadFailed"

#ifdef DEBUG_REMOTE_OBJECT
#define STDebugRemoteLog(x,...)	NSLog(x,##__VA_ARGS__)
#else
#define STDebugRemoteLog( x, ... )
#endif

// This is a NSURLConnection delegate (informal)

@interface STRemoteObject : NSObject {
	
	@protected
	NSURL* originalURL;
	NSURL* resourceURL;
	
	NSString* filename;
	NSString* mimeType;
	NSString* cacheFileName;
  
  NSURLRequestCachePolicy cachePolicy;
	
	@private
	NSURLConnection* connection;
	NSData*   contentData;
	NSMutableData* downloadDataStore;
	NSMutableSet* duplicateObjects;
    
	BOOL shouldCheckServer;
  BOOL shouldCheckBundle;
}

-(id) initWithURL:(NSURL*) url;
-(void) fetch;

// subclasses can override these if they call super. 
- (void) dataDidLoad;
- (void) dataLoadFailed:(NSError*)error;

- (void) cancel;
	
@property (nonatomic,readonly) NSString* mimeType;
@property (nonatomic,readonly) NSData* contentData;
@property (nonatomic,readonly) BOOL downloadInProgress;
@property (nonatomic,assign)   BOOL shouldCheckServer;
@property (nonatomic,assign)   BOOL shouldCheckBundle;


@property (nonatomic,readonly) NSURL* originalURL;
@property (nonatomic,readonly) NSURL* resourceURL;
@property (nonatomic,readonly) NSURL* cacheFileURL;

@property (nonatomic,retain) NSString* cacheFileName;

@property (nonatomic,readonly) NSMutableSet* duplicateObjects;

// mostly useful for debugging -- will delete everything in the App's cache directory
+(void) deleteAllCachedObjects;

@end
