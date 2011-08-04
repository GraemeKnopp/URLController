//
//  DownloadController.m
//
//  Created by Graeme Knopp
//

#import "DownloadController.h"
#import "URLController.h"

@implementation DownloadController

@synthesize myDelegate;

@synthesize userName;
@synthesize passWord;


#pragma mark - Constructor & Destructor


- (id) init {
  
  self = [super init];  
  if (self == nil) {}

  
  state = STATE_READY;

  userName = [NSString stringWithFormat:@"Anonymous"];
  passWord = [NSString stringWithFormat:@"newb.user@someserver.com"];
  
  receivedData = [[NSMutableData alloc] init];  
  myDelegate = self;
  

	return self;
}

- (void) dealloc {
  
  [receivedData release];

  [super dealloc];
  
}



#pragma mark - Miscellaneous Methods


-(void) flushReceivedData {
  
  // flush data if it exists
  
  if ([receivedData length] > 0) {
    NSLog(@"DOWNLOAD > FLUSH > %d bytes",(int)[receivedData length]);    
    [receivedData setLength:0];    
  }
  
  if (receivedData == nil)
    receivedData = [[NSMutableData alloc] init];    
  
}

- (void) attemptDownload:(NSString*)theUrl  {
  
  NSLog(@"DOWNLOAD > URL > %@", theUrl);
  state = STATE_UNKNOWN;
  
  // Create the request object
  NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:theUrl]
                                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                                        timeoutInterval:60.0];
  
  // create the connection with the request and start loading the data
  NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
  if (!theConnection) {
    [myDelegate downloadHasFailedWith:@"Unable to initate a connection."];
  }
  
}




#pragma mark - Connection Methods


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  
  // This method is called when the server has determined that it has enough information to create the NSURLResponse.
  // It can be called multiple times, for example in the case of a redirect, so each time we reset the data.
  
  NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
  //NSAssert(![httpResponse isKindOfClass:[NSHTTPURLResponse class]], @"NOT A CORRECT URL RESPONSE");  
  //assert([httpResponse isKindOfClass:[NSHTTPURLResponse class]]);
  
  NSLog(@"DOWNLOAD > STATUS > %d", (int)httpResponse.statusCode);  
  state = STATE_DOWNLOADING;  

  // connection is ready to receive data
  [receivedData setLength:0];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
  // to deal with self-signed certificates
  return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  
  NSURLCredential *credential;
  
  NSLog(@"DOWNLOAD > CHALLENGED");
  
  if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
    
    // asked for a signed certificate    
    NSLog(@"DOWNLOAD > CHALLENGED > BY > %@", challenge.protectionSpace.host);
    
    // we only trust our own domain
    if ([challenge.protectionSpace.host isEqualToString:BASE_URI]) {
      NSLog(@"DOWNLOAD > TRUSTED");
      credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
      [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];      
    } else {
      [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
    
  } else {
    
    credential = [NSURLCredential credentialWithUser:userName password:passWord persistence:NSURLCredentialPersistenceForSession];	
    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
  }
  
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {

  // Append the new data to receivedData.  
  [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

  state = STATE_READY;
  
  // prepare return message
  NSString* errorString = [NSString stringWithFormat:@"Connection Failed\n\n"];
  errorString = [errorString stringByAppendingFormat:@"%@ - ",[error localizedDescription]]; 
  errorString = [errorString stringByAppendingFormat:@"%@",[[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];  
  [myDelegate downloadHasFailedWith:errorString];
  
  // clean up state
  [self flushReceivedData];
  [connection release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

  NSLog(@"DOWNLOAD > CONNECTION > RECEIVED > %d bytes.", (int)[receivedData length]);

  state = STATE_READY;
  
  [myDelegate downloadIsFinishedWith:receivedData];   
  [self flushReceivedData];
  [connection release];
}



#pragma mark - Interface Methods


-(void) getRequest:(NSString*)url {

  // check if I am busy
  if (state != STATE_READY) 
  {
    NSString* msg = [NSString stringWithFormat:@"Download controller is busy.%d.", state];
    [myDelegate downloadHasFailedWith:msg];
    return;         
  }
  
  [self attemptDownload:url];               // try to push a request through
}

@end
