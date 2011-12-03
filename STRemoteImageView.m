//
//  RemoteImageView.m
//
//  Created by Tom Whipple on 10/18/10.
//  Copyright 2010 Smartovation Technologies, LLC. All rights reserved.
//

#import "STRemoteImageView.h"
#import "Debug.h"

@implementation STRemoteImageView
@synthesize remoteImage;

-(void) layoutSubviews {
	[super layoutSubviews];
	super.image = remoteImage.image;
}


- (void)setRemoteImage:(STRemoteImage*) ri {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRemoteObjectUpdatedNotification object:remoteImage];
	[remoteImage release];
	
	remoteImage = [ri retain];
	if (remoteImage) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(setNeedsLayout)
													 name:kRemoteObjectUpdatedNotification
												   object:remoteImage];
	}
	[self setNeedsLayout];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
  [super willMoveToSuperview:newSuperview];
  if (newSuperview == nil) {
    [remoteImage cancel];
  }
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  [remoteImage cancel];
	[remoteImage release];
	remoteImage = nil;
  
  [super dealloc];
}


@end
