//
//  RemoteImageTableViewCell.h
//
//  Created by Tom Whipple on 9/22/10.
//  Copyright 2010 Smartovation Technologies, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STRemoteImage.h"

@interface STRemoteImageTableViewCell : UITableViewCell {
	STRemoteImage* remoteImage;
}

@property (nonatomic,retain) STRemoteImage* remoteImage;

@end
