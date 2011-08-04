//
//  UploadController.m
//
//  Created by Graeme Knopp.
//

#import "UploadController.h"
#import "URLController.h"


@implementation UploadController


@synthesize myDelegate;
@synthesize contentType;
@synthesize userName;
@synthesize passWord;
@synthesize queue;


#pragma mark - Constructor & Destructor


- (id) init {
  
  if (self == nil)  {}

  [super init];
  
  state = STATE_READY;

  contentType = [NSString stringWithFormat:@""];    
  userName = [NSString stringWithFormat:@"Anonymous"];
  passWord = [NSString stringWithFormat:@"newb.user@someserver.com"];
  
  receivedData = [[NSMutableData alloc] init];  
  queue = [[NSOperationQueue alloc] init];
  
  myDelegate = self;
  
  return self;    
}

- (void)dealloc
{
  [queue release];
  [receivedData release];
  [super dealloc];
}



#pragma mark - Miscellaneous Methods


-(void) flushReceivedData {
  
  // flush data if it exists
  NSLog(@"UPLOAD > FLUSH");
    
  if ([receivedData length] > 0) {
    NSLog(@"UPLOAD > FLUSH > %d bytes",(int)[receivedData length]);    
    [receivedData autorelease];    
  }
  
  if (receivedData == nil)
    receivedData = [[NSMutableData alloc] init];    
  
}

-(void) attemptUpload:(NSString*)url withData:(NSData*)newData {
  
  NSLog(@"UPLOAD > URL > %@", url);
  state = STATE_UNKNOWN;
  
  // we have content type, data, and a url, all systems go !
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];  
  [request setHTTPMethod:@"POST"];
  [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
  [request setHTTPBody:newData];
  
  NSURLConnection* theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  if (!theConnection) {
    [myDelegate uploadHasFailedWith:@"Unable to initiate a connection."];
  }
}



#pragma mark - Connection Methods


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

  // verify connection
  NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
  //NSAssert(![httpResponse isKindOfClass:[NSHTTPURLResponse class]], @"NOT A CORRECT URL RESPONSE");  
  //assert([httpResponse isKindOfClass:[NSHTTPURLResponse class]]);
  
  NSLog(@"UPLOAD > STATUS > %d", (int)httpResponse.statusCode);  
  
  if ((httpResponse.statusCode / 100) == 2) { 
    // I believe at this point the server is able to handle our data
    NSLog (@"UPLOAD > POST > Complete!");
    state = STATE_READY;
  }   else {
      NSLog(@"%@", httpResponse.allHeaderFields);
  }
  // connection is ready to receive data
//  [receivedData setLength:0];  
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
  // to deal with self-signed certificates
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  
  NSURLCredential *credential;
  
  NSLog(@"UPLOAD > CHALLENGED");
  
  if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
    
    // asked for a signed certificate    
    NSLog(@"UPLOAD > CHALLENGED > BY > %@", challenge.protectionSpace.host);
    
    // we only trust our own domain
    if ([challenge.protectionSpace.host isEqualToString:BASE_URI]) {
      NSLog(@"UPLOAD > TRUSTED");
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

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesOut totalBytesWritten:(NSInteger)totalBytesOut totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {

  // if content is too large for the byte buffer multiple sends are executed
  // verify that data was sent out completely.
  
  state = STATE_UPLOADING;
  NSLog(@"UPLOAD > CONNECTION > POSTED > %d bytes.", (int)bytesOut);
  
  if (totalBytesExpectedToWrite == totalBytesOut) {
    // we should be done
  }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

  // prepare return error message
  NSString* errorString = [NSString stringWithFormat:@"Connection Failed\n\n"];
  errorString = [errorString stringByAppendingFormat:@"%@ - ",[error localizedDescription]]; 
  errorString = [errorString stringByAppendingFormat:@"%@",[[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];    
  [myDelegate uploadHasFailedWith:errorString];

  // clean up state
  [self flushReceivedData];
  [connection release];
  state = STATE_READY;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
  // delegate needs to [retain] this data
  [myDelegate uploadHasFinished:[receivedData autorelease]];

  [self flushReceivedData];
  [connection release];  
  state = STATE_READY;
}



#pragma mark - Interface Methods


-(void) postRequest:(NSString*)url withData:(NSData*)newData {
  
  // validate request first
  
  if ([contentType isEqualToString:@""]) {
    [myDelegate uploadHasFailedWith:@"Uploading requires a content type."];
    return;
  }

  if ([newData length] == 0) {
    [myDelegate uploadHasFailedWith:@"Upload does not contain data."];
      return;
  }

  [self attemptUpload:url withData:newData];
}


@end
