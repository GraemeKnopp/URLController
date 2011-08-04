//
//  DownloadController.h
//
//  Created by Graeme Knopp.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"


@protocol DownloadDelegate <NSObject>
- (void) downloadIsFinishedWith:(NSData*)newData ;
- (void) downloadHasFailedWith:(NSString*) error_message;
@end


@interface DownloadController : NSObject {

  id myDelegate;                          // delegate to receive "done downloading" messsage

  NSString* userName;
  NSString* passWord;


@private  

  int state;  
  NSMutableData* receivedData;            // download byte buffer
}

@property (nonatomic, assign) id myDelegate;
@property (nonatomic, retain) NSString* userName;
@property (nonatomic, retain) NSString* passWord;


-(void) getRequest:(NSString*)request_url;



@end
