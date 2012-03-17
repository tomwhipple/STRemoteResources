//
//  RemoteImage.m
//
//  Created by Tom Whipple on 9/5/10.
//  Copyright 2010 Smartovation Technologies, LLC. All rights reserved.
//

#import "STRemoteImage.h"

@implementation STRemoteImage
@synthesize use2xImage;

+(BOOL) deviceUses2x {
	BOOL hasHighResScreen = NO;
	if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
		if ([[UIScreen mainScreen] scale] > 1.0) {
			hasHighResScreen = YES;
		}
	}
	return hasHighResScreen;
}

-(id) initWithFilename:(NSString*)file baseURL:(NSURL*)_url {
	if ((self = [self initWithURL:[NSURL URLWithString:file relativeToURL:_url]])) {
		filename = [file retain];
	}
	return self;
}

-(id) initWithURL:(NSURL *)_url {
	STDebugRemoteLog(@"remote image url:%@",[_url absoluteURL]);
	if ((self = [super initWithURL:_url])) {
		use2xImage = [[self class] deviceUses2x];
		self.shouldCheckServer = NO;
    cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	}
	return self;
}

-(NSString*) description {
	return [NSString stringWithFormat:@"remoteImage with URL: %@ image: %@",[self.resourceURL absoluteURL],image];
}

-(void) loadImage {
	[image release];image = nil;
	self.shouldCheckServer = NO;
	
	if (use2xImage) {
		image = [UIImage imageWithCGImage:[[UIImage imageWithData:self.contentData] CGImage]
									scale:2.0
							  orientation:UIImageOrientationUp];
	}
	else {
		image = [UIImage imageWithData:self.contentData];
	}
	[image retain];
}

-(void) dataDidLoad {
	[self loadImage];
	
	[super dataDidLoad];
}

- (void) dataLoadFailed:(NSError*)error {
	if (use2xImage) {
		NSLog(@"failed to load hi-rez url (%@) retrying...",resourceURL);
		[resourceURL release]; resourceURL = nil;
		use2xImage = NO;
    for (STRemoteImage* ri in self.duplicateObjects) {
      ri.use2xImage = NO;
      ri.shouldCheckServer = NO;
    }
		[self fetch];
	}
  else {
    [super dataLoadFailed:error];
  }
}

-(UIImage*) image {
	
	// accomodate bundled images
	if (!image && self.shouldCheckBundle) {
		image = [[UIImage imageNamed:filename] retain];
	}
	
	if (!image) {
		
		if (use2xImage) {
			NSMutableString* imgFile2x = [NSMutableString stringWithString:[originalURL absoluteString]];
			[imgFile2x insertString:@"@2x" atIndex:imgFile2x.length-4];
			resourceURL = [[NSURL alloc] initWithString:imgFile2x];
		}
		
		[self fetch];
		if (self.contentData) [self loadImage];
	}
	return image;
}


-(void) dealloc {
	[image release];
	
	[super dealloc];
}

@end
