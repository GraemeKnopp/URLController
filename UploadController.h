//
//  UploadController.h
//
//  Created by Graeme Knopp.
//

#import <Foundation/Foundation.h>



@protocol UploadDelegate <NSObject>

- (void) uploadHasFailedWith:(NSString*)errorMessage;
- (void) uploadHasFinished:(NSData*)response;

@end


@interface UploadController : NSObject {

  id myDelegate;
  
  NSOperationQueue* queue;
  
  NSString* contentType;       // 'application/json', 'text/html', 'text/javascript'
  NSString* userName;
  NSString* passWord;

@private
  
  int state;                   // CONTROLLER_STATE: UNKNOWN,BUSY,DL,UL  
  NSMutableData* receivedData; // any data received back from post request

}

@property (nonatomic, assign) id myDelegate;

@property (nonatomic, retain) NSString* contentType;
@property (nonatomic, retain) NSString* userName;
@property (nonatomic, retain) NSString* passWord;

@property (nonatomic, retain) NSOperationQueue* queue;


-(void) postRequest:(NSString*)url withData:(NSData*)newData;

@end
