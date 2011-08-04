//
//  URLController.m
//
//  Created by Graeme Knopp.
//

#import "URLController.h"


@implementation URLController


@synthesize myDelegate;


#pragma mark - Init and Dealloc


- (id)init {
  
  self = [super init];
  if (self) {
    // Initialization code here.
  }
  
  uploader = [[UploadController alloc] init];
  downloader = [[DownloadController alloc] init];
  
  uploadQueue = [[NSMutableArray alloc] init];
  downloadQueue = [[NSMutableArray alloc] init];
  
  myDelegate = self;
  state = STATE_READY;
  
  return self;
}

- (void)dealloc {
  
  [uploadQueue release];
  [downloadQueue release];
  [uploader release];
  [downloader release];
  
  [super dealloc];
}



#pragma mark - Delegate Methods - Download


- (void) downloadHasFailedWith:(NSString*) error_message {
  // pass-thru 
  [myDelegate downloadFailed:error_message];
  
  if (state == STATE_DOWNLOADQUEUE) {
    // pop off the first one and start downloading more
    [downloadQueue removeObjectAtIndex:0];
    [self startDownloading];
  }
}

- (void) downloadIsFinishedWith:(NSData*)newData {

  NSMutableData* data = [[NSMutableData alloc] initWithData:[newData retain]];
  
  if (myDelegate != self)  
    [myDelegate downloadFinished:data forContent:currentType];
  
  [data release];
  
  if (state == STATE_DOWNLOADQUEUE) {
    // pop off the first one and start downloading more
    [downloadQueue removeObjectAtIndex:0];
    [self startDownloading];
  }
}



#pragma mark - Delegate Methods - Uploads


- (void) uploadHasFailedWith:(NSString*)errorMessage { 
  // pass-thru 
  [myDelegate uploadFailed:errorMessage];
  
  if (state == STATE_UPLOADQUEUE) {
    // pop off the first one and start uploading more
    [uploadQueue removeObjectAtIndex:0];
    [self startUploading];
  }
}

- (void) uploadHasFinished:(NSData*)response {

  NSMutableData* data = [[NSMutableData alloc] initWithData:[response retain]];
  
  if (myDelegate != self)
    [myDelegate uploadFinished:data];
  
  [data release];
  
  if (state == STATE_UPLOADQUEUE) {
    // pop off the first one and start uploading more
    [uploadQueue removeObjectAtIndex:0];
    [self startUploading];
  }
}



#pragma mark - Miscellaneous Methods


-(void) setCredentials:(id)controller withUser:(NSString*)newUser withPass:(NSString*)newPass {
  [controller setUserName:newUser];
  [controller setPassWord:newPass];
}



#pragma mark - Interface Methods


-(void) startUploading {
  
  if ([uploadQueue count] > 0) {
    state = STATE_UPLOADQUEUE;
    NSDictionary* ul = [uploadQueue objectAtIndex:0];
    NSString* url = [ul objectForKey:@"uploadUrl"];
    NSString* urlType = [ul objectForKey:@"uploadType"];
    [self uploadTo:url withData:[ul objectForKey:@"uploadData"] ofType:urlType];
  } else {
    state = STATE_READY;
    [myDelegate uploadQueueFinished];
  }
  
}

-(void) startDownloading {
  //
  if ([downloadQueue count] > 0) {
    
    state = STATE_DOWNLOADQUEUE;
    NSDictionary* dict = [downloadQueue objectAtIndex:0];
    currentType = (int)[[dict valueForKey:@"contentType"] intValue];
    NSString* url = [dict valueForKey:@"url"];

    // handle each of your custom DLC_TYPES here

    switch (currentType) {
      case DL_WEBPAGE:
        [self downloadFrom:url];
        break;
      case DL_MYCUSTOMTYPE:
        [self downloadListFrom:url];
        break;
      case DL_MYOTHERTYPE:
        [self downloadDataFrom:url];
        break;
      default:
        break;
        
    }
  } else {
    state = STATE_READY;
    [myDelegate downloadQueueFinished];
  }
}


-(void) addToUpload:(NSString*)url withData:(NSData*)newData ofType:(NSString*)contentType {

  NSMutableDictionary* uploadDict = [[NSMutableDictionary alloc] init];
  [uploadDict setValue:url forKey:@"uploadUrl"];
  [uploadDict setValue:newData forKey:@"uploadData"];
  [uploadDict setValue:contentType forKey:@"uploadType"];

  [uploadQueue addObject:uploadDict];
  [uploadDict release];
}

-(void) uploadTo:(NSString *)url withData:(NSData *)newData ofType:(NSString*)contentType {
  [uploader setMyDelegate:self];
  [uploader setContentType:contentType];
  [uploader postRequest:url withData:newData];  
}

-(void) setCredentialsForUpload:(NSString*)newUser withPass:(NSString*)newPass {
  [self setCredentials:uploader withUser:newUser withPass:newPass];
}

-(void) addToDownload:(NSString*)url ofType:(int)contentType {
  NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
  [dict setValue:url forKey:@"url"];
  [dict setValue:[NSNumber numberWithInt:contentType] forKey:@"contentType"];
  [downloadQueue addObject:dict];
  [dict release];
}

-(void) downloadFrom:(NSString *)url {
  currentType = DL_WEBPAGE;
  [downloader setMyDelegate:self];
  [downloader getRequest:url];
}

-(void) setCredentialsForDownload:(NSString*)newUser withPass:(NSString*)newPass {
  [self setCredentials:downloader withUser:newUser withPass:newPass];
}

-(int) downloadQueueCount {
  return (downloadQueue == nil) ? 0 : [uploadQueue count];
}

-(int) uploadQueueCount {
  return (uploadQueue == nil) ? 0 : [uploadQueue count];
}



#pragma mark - Custom DLC Implementation Methods


-(void) downloadListFrom:(NSString*)url {
  currentType = DL_MYCUSTOMTYPE;
  [downloader setMyDelegate:self];
  [downloader getRequest:url];
}

-(void) downloadDataFrom:(NSString *)url {
  currentType = DL_MYOTHERTYPE;
  [downloader setMyDelegate:self];
  [downloader getRequest:url];
}



@end
