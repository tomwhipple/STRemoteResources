//
//  RemoteObject.m
//
//  Created by Tom Whipple on 12/20/10.
//  Copyright 2010 Smartovation Technologies, LLC. All rights reserved.
//

#import "STRemoteObject.h"

#import <UIKit/UIKit.h>

@implementation STRemoteObject

static NSUInteger numberOfActiveDownloads = 0;
static NSMutableDictionary* masterRequestList = nil;
static NSUInteger numberOfRemoteObjects = 0;

#define cacheDir() [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) objectAtIndex:0]

+(NSString*) cachePathFromURL:(NSURL*)url {
	NSString* cachePath = [cacheDir() stringByAppendingPathComponent:[[url host] stringByAppendingPathComponent:[url path]]];
	if ([url query]) {
    cachePath = [cachePath stringByAppendingString:[[url query] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  }
	return cachePath;
}

+(void) deleteAllCachedObjects {
  for (NSString* filename in [[NSFileManager defaultManager] enumeratorAtPath:cacheDir()]) {
    NSError* error = nil;
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:filename] 
        && ![[NSFileManager defaultManager] removeItemAtPath:filename error:&error  ]) {
      NSLog(@"Error deleting %@: %@\n%@",filename, [error localizedDescription], [error userInfo]);
    }
  }
}

#pragma mark -
#pragma mark Properties

@synthesize originalURL;
@synthesize shouldCheckServer, shouldCheckBundle;
@synthesize contentData;
@synthesize cacheFileName;
@synthesize mimeType;

- (NSURL*) resourceURL {
	if (!resourceURL) return originalURL;
	return resourceURL;
}

- (BOOL) downloadInProgress {
	return (connection != nil 
            && [masterRequestList objectForKey:[originalURL absoluteString]]!= nil);
}

- (NSURL*) cacheFileURL {
	NSURL* url = nil;

	NSString* cachePath = [STRemoteObject cachePathFromURL:self.resourceURL];
	if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
		url = [NSURL fileURLWithPath:cachePath];
	}
	return url;
}

-(NSMutableSet*) duplicateObjects {
    if (!duplicateObjects) {
        duplicateObjects = [[NSMutableSet alloc] initWithCapacity:10];
    }
    return duplicateObjects;
}

#pragma mark -

- (id) initWithURL:(NSURL*) url {
	if ((self = [super init])) {
		originalURL = [url retain];
		shouldCheckServer = YES;
    shouldCheckBundle = YES;
    numberOfRemoteObjects++;
	}
	return self;
}

-(void) loadCachedRequest:(NSURLRequest*) request {
    NSCachedURLResponse* cacheResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    if (cacheResponse) {
        STDebugRemoteLog(@"cache hit (mem) for %@: %@",[request URL],[cacheResponse userInfo]);
        contentData = [[NSData alloc] initWithData:[cacheResponse data]];
    }
	
	NSString* file = [[[request URL] path] lastPathComponent];
	
	if (!contentData) {
		NSString* cacheFile = [[self class] cachePathFromURL:[request URL]];
		if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
			contentData = [[NSData alloc] initWithContentsOfMappedFile:cacheFile];
			STDebugRemoteLog(@"cache hit (disk) for %@", [request URL]);
		}
	}	
	
	if (!contentData && shouldCheckBundle) {
		NSString* bundlePath = [[NSBundle mainBundle] pathForResource:file ofType:nil];
		if (bundlePath) {
			STDebugRemoteLog(@"bundle hit for %@",[request URL]);
			contentData = [[NSData alloc] initWithContentsOfMappedFile:bundlePath];
		}
	}
	
	if (contentData) [self dataDidLoad];
}

-(void) cancel {
	if (self.downloadInProgress && (!duplicateObjects || duplicateObjects.count == 0)) {
		[connection cancel];
		[connection release]; connection = nil;
		[downloadDataStore release]; downloadDataStore = nil;
		
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(--numberOfActiveDownloads >0)];
        
        [masterRequestList removeObjectForKey:[self.originalURL absoluteString]];
	}
}



-(void) fetch {
	// speedup
	if (!contentData && cacheFileName) {
		NSString* cachePath = [cacheDir() stringByAppendingPathComponent:cacheFileName];
		contentData = [[NSData alloc] initWithContentsOfMappedFile:cachePath];
	}
  
  if (!masterRequestList) {
    masterRequestList = [[NSMutableDictionary alloc] initWithCapacity:10];
  }
  STRemoteObject* existingObject = [masterRequestList objectForKey:[self.originalURL absoluteString]];
  if (existingObject) {
    [existingObject.duplicateObjects addObject:self];
  }
	else if (shouldCheckServer || !contentData) {
		if (!resourceURL) {
			resourceURL = [originalURL copy];
		}
		
		NSURLRequest* request = [NSURLRequest requestWithURL:resourceURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:3.0];
		
		[self loadCachedRequest:request];
		
		if ((shouldCheckServer || !contentData) && !self.downloadInProgress) {
			connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
			numberOfActiveDownloads++;
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
      
      [masterRequestList setObject:self forKey:[self.originalURL absoluteString]];
		}
	}
}

//- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {}
//- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {}
//- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {}
//- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {}

- (void)connection:(NSURLConnection *)_connection didReceiveResponse:(NSURLResponse *)response {
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]] && [(NSHTTPURLResponse*)response statusCode] >= 400) {
        [self cancel];
        
        NSInteger errorCode = [(NSHTTPURLResponse*)response statusCode];

        NSError* e = [NSError errorWithDomain:@"STRemoteResources"
                                         code:errorCode
                                     userInfo:[NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:errorCode] forKey:NSLocalizedDescriptionKey]];
        STDebugRemoteLog(@"request for %@ failed with %i",[response URL],errorCode);
        [self dataLoadFailed:e];
        return;
    }
  
  STDebugRemoteLog(@"response from : %@", [response URL]);
  
	[resourceURL release];
	resourceURL = [[response URL] retain];
    
	[mimeType release];
	mimeType = [[response MIMEType] retain];
	
	if (!filename) {
		filename = [[response suggestedFilename] retain];
	}
	
	long long contentLength = [response expectedContentLength];
	if (contentLength == NSURLResponseUnknownLength || contentLength < 0) {
		contentLength = 1024 * 200; // 200 kB
	}
	[downloadDataStore release];
	downloadDataStore = [[NSMutableData alloc] initWithCapacity:contentLength];
}

- (void)connection:(NSURLConnection *)_connection didReceiveData:(NSData *)data {
	[downloadDataStore appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)_connection {
	STDebugRemoteLog(@"RemoteObject(%@) finished loading",[resourceURL absoluteString]);
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(--numberOfActiveDownloads >0)];
    
	[connection release]; connection = nil;
  
  if (resourceURL) {
    
    [contentData release];
    contentData = [downloadDataStore retain];
    
    NSError* error = nil;
    if (cacheFileName) {
      NSString* cachePath = [cacheDir() stringByAppendingPathComponent:cacheFileName];
      
      if (![contentData writeToFile:cachePath options:NSDataWritingAtomic error:&error]) {
        NSLog(@"p for %@:\n%@",cachePath,[error userInfo]);
      }
    }
    else {
      NSString* cacheFile = [[self class] cachePathFromURL:originalURL];
      NSString* cacheDir = [cacheFile stringByDeletingLastPathComponent];
      
      BOOL directoryExists = NO;
      [[NSFileManager defaultManager] fileExistsAtPath:cacheDir isDirectory:&directoryExists];
      if (!directoryExists 
          && ![[NSFileManager defaultManager] createDirectoryAtPath:cacheDir  withIntermediateDirectories:YES attributes:nil error:&error] ) {
            NSLog(@"ERROR: Failed to create cache dir %@:\n%@",cacheDir,[error userInfo]);
            
          }
      else if (![contentData writeToFile:cacheFile options:NSDataWritingAtomic error:&error]) {
        NSLog(@"ERROR: Cache write failed for %@:\n%@",cacheFile,[error userInfo]);
      }
    }
  }
  
	[self dataDidLoad];
}

- (void)connection:(NSURLConnection *)_connection didFailWithError:(NSError *)error {
	NSLog(@"RemoteObject %@ failed to download: %@",[resourceURL absoluteString],[error localizedDescription]);
	[connection release]; connection = nil;
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(--numberOfActiveDownloads >0)];

	[self dataLoadFailed:error];
	[downloadDataStore release]; downloadDataStore = nil;
}

- (void) dataDidLoad {
	[[NSNotificationCenter defaultCenter] postNotificationName:kRemoteObjectUpdatedNotification object:self];
    [masterRequestList removeObjectForKey:[self.originalURL absoluteString]];
    for (id dup in duplicateObjects) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kRemoteObjectUpdatedNotification object:dup];
    }
}

- (void) dataLoadFailed:(NSError*)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:kRemoteObjectLoadFailedNotification
														object:self
													  userInfo:[error userInfo]];
    [masterRequestList removeObjectForKey:[self.originalURL absoluteString]];
    for (id dup in duplicateObjects) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kRemoteObjectLoadFailedNotification object:dup userInfo:[error userInfo]];
    }
}

- (void) dealloc {
	if (self.downloadInProgress) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(--numberOfActiveDownloads >0)];
	}
    
  numberOfRemoteObjects--;
  if (numberOfRemoteObjects==0) {
      [masterRequestList release]; masterRequestList = nil;
  }

  [duplicateObjects release];
    
	[connection cancel];
	[connection release];
	
	[contentData release];
	[downloadDataStore release];
	[cacheFileName release];
	
	[originalURL release];
	[resourceURL release];
	
	[filename release];
	[mimeType release];
	
	[super dealloc];
}

@end
