//
//  RemoteImageView.h
//
//  Created by Tom Whipple on 10/18/10.
//  Copyright 2010 Smartovation Technologies, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STRemoteImage.h"

@interface STRemoteImageView : UIImageView {
	STRemoteImage* remoteImage;
}

@property (nonatomic,retain) 	STRemoteImage* remoteImage;


@end
