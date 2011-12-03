//
//  RemoteTable.m
//
//  Created by Tom Whipple on 9/30/10.
//  Copyright 2010 Smartovation Technologies, LLC. All rights reserved.
//

#import "STRemoteTable.h"

#ifdef ST_REMOTE_TABLE_USE_CSV
#import "CSVParser.h"
#endif

#import "debug.h"

@implementation STRemoteTable

-(id) initWithFile:(NSString*)f baseURL:(NSURL*)url className:(NSString*)cn {
	if (self = [super initWithURL:[NSURL URLWithString:f relativeToURL:url]]) {
		className = [cn retain];
	}

	return self;
}
				
-(NSArray*) array {
	if (!array) {
		[self fetch];
	}
	return array;
}

-(void) dataDidLoad {
	NSString* csv= [[NSString alloc] initWithData:self.contentData encoding:NSUTF8StringEncoding];
#ifdef ST_REMOTE_TABLE_USE_CSV
	CSVParser* parser = [[CSVParser alloc] initWithString:csv
												separator:@","
												hasHeader:YES 
											   fieldNames:nil];
	[csv release];
	
	NSArray* records = [parser arrayOfParsedRows];
	
	[array release];
	array = [[NSMutableArray alloc] initWithCapacity:records.count];
	
	[parser release];
#endif
	for (NSDictionary* d in records) {
		NSObject* obj = [[NSClassFromString(className) alloc] initWithDictionary:d];
		[array addObject:obj];
		[obj release];
	}
	
	[super dataDidLoad];
}


- (void) dealloc {
	
	[array release];
	[className release];
	
	[super dealloc];
}

@end
