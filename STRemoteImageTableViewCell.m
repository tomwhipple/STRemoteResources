//
//  RemoteImageTableViewCell.m
//
//  Created by Tom Whipple on 9/22/10.
//  Copyright 2010 Smartovation Technologies, LLC. All rights reserved.
//

#import "STRemoteImageTableViewCell.h"


@implementation STRemoteImageTableViewCell

@synthesize remoteImage;

-(void) setRemoteImage:(STRemoteImage *) r {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:remoteImage];
	[remoteImage release];
	remoteImage = [r retain];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateContent:)
												 name:kRemoteObjectUpdatedNotification object:remoteImage];

	[self setNeedsLayout];
}

- (void)updateContent:(id)sender {
  [self setNeedsLayout];
}

- (void)prepareForReuse {
	[super prepareForReuse];
	[remoteImage cancel];
}

-(void) layoutSubviews {
	self.imageView.image = remoteImage.image;
  [super layoutSubviews];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
  [super willMoveToSuperview:newSuperview];
  if (newSuperview == nil) {
    [remoteImage cancel];
  }
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[remoteImage release];
	
    [super dealloc];
}


@end
