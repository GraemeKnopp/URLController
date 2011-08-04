//
//  URLController.h
//
//  Created by Graeme Knopp.
//

// REASONING BEHIND TWO SUB-CONTROLLERS (UL/DL):
//
//   IF THERE IS A POSSIBILITY FOR ASYNCHRONOUS UP & DOWNLOADS
//   EASIER TO THREAD TWO CONTROLLERS INSTEAD OF ONE
//


#import <Foundation/Foundation.h>
#import "DownloadController.h"
#import "UploadController.h"


#define BASE_URL  @"https://your.webserver.com"
#define BASE_URI  @"your.webserver.com"


typedef enum
{
  STATE_UNKNOWN = -1,
  STATE_READY,
  STATE_DOWNLOADING,
  STATE_UPLOADING,
  STATE_DOWNLOADQUEUE,
  STATE_UPLOADQUEUE
  
} CONTROLLER_STATE;


@protocol URLControllerDelegate <NSObject>
- (void) downloadFinished:(NSData*)newData forContent:(int)contentType;
- (void) downloadFailed:(NSString*)error_message;
- (void) uploadFinished:(NSData*)newData;
- (void) uploadFailed:(NSString*)error_message;
- (void) uploadQueueFinished;
- (void) downloadQueueFinished;
@end


@interface URLController : NSObject <DownloadDelegate, UploadDelegate> {

  id myDelegate;
    
@private
    
  UploadController* uploader;
  DownloadController* downloader;
  
  NSMutableArray* downloadQueue;
  NSMutableArray* uploadQueue;
  
  int state;
  int currentType;
  
}

@property (nonatomic, assign) id myDelegate;


-(void) addToUpload:(NSString*)url withData:(NSData*)newData ofType:(NSString*)contentType;
-(void) addToDownload:(NSString*)url ofType:(int)contentType;

-(void) startUploading;
-(void) startDownloading;

-(void) uploadTo:(NSString *)url withData:(NSData *)newData ofType:(NSString*)contentType;
-(void) setCredentialsForUpload:(NSString*)newUser withPass:(NSString*)newPass;

-(void) downloadFrom:(NSString*)url;
-(void) setCredentialsForDownload:(NSString*)newUser withPass:(NSString*)newPass;

-(void) downloadListFrom:(NSString*)url;
-(void) downloadDataFrom:(NSString*)url;

-(int) downloadQueueCount;
-(int) uploadQueueCount;

@end
