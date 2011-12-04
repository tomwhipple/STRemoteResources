//
//  RemoteTable.h
//
//  Created by Tom Whipple on 9/30/10.
//  Copyright 2010 Smartovation Technologies, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRemoteObject.h"

#define RemoteTableDidUpdate kRemoteObjectUpdatedNotification

@protocol STRemoteItem

-(id) initWithDictionary:(NSDictionary*) dict;

@end


@interface STRemoteTable : STRemoteObject 
{
	@protected
	NSMutableArray* array;
	NSString* className;

}

@property (nonatomic,readonly) NSArray* array;

-(id) initWithFile:(NSString*)f baseURL:(NSURL*)url className:(NSString*)cn;

@end
