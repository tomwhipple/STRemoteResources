//
//  RemoteImage.h
//
//  Created by Tom Whipple on 9/5/10.
//  Copyright 2010 Smartovation Technologies, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRemoteObject.h"

#define RemoteImageDidUpdate kRemoteObjectUpdatedNotification

@interface STRemoteImage : STRemoteObject {
	@protected
//	NSURL* baseURL;
	UIImage* image;
	
	BOOL use2xImage;
	
//	NSString* cacheFileName;
}

-(id) initWithFilename:(NSString*)file baseURL:(NSURL*)_url;
-(id) initWithURL:(NSURL*)_url;

+(BOOL) deviceUses2x;

@property (nonatomic,readonly) 	UIImage* image;
//@property (nonatomic,readonly)	NSString* filename;
@property (nonatomic,assign) 	BOOL use2xImage;

// setting this disables @2x Images
//@property (nonatomic,retain) 	NSString* cacheFileName;

@end

