//
//  BackgroundDownloader.h
//  BackgroundDownloadDemo
//
//  Created by zl on 2019/4/9.
//  Copyright © 2019 hkhust. All rights reserved.
//

#ifndef BackgroundDownloader_h
#define BackgroundDownloader_h

typedef void(^CompletionHandlerType)();

class AzureBackgroundDownloadCallback
{
public:
    virtual void onOneFileDownloadFinish(unsigned long taskIdentifier,NSString* tempFilename) = 0;
    virtual void onDataReceive(unsigned long taskIdentifier,int64_t  totalBytesWritten, int64_t totalBytesExpectedToWrite) = 0;
    virtual void onTaskFailed(unsigned long taskIdentifier) = 0;
    virtual void onTaskSuccess(unsigned long taskIdentifier) = 0;
};


@interface AzureBackgroundDownloader : NSObject<NSURLSessionDownloadDelegate>

- (AzureBackgroundDownloader *) init: (NSString *) identifier  callback:(AzureBackgroundDownloadCallback *) callback;
- (void)addCompletionHandler:(CompletionHandlerType)handler forSession:(NSString *)identifier;
- (NSUInteger)beginDownloadWithUrl:(NSString *)downloadURLString;
- (void)pauseOneDownload : (NSUInteger)  taskTopause  isStop:(BOOL) isStop;
- (void)pauseAllDownload :(BOOL) isStop;
- (BOOL)continueOneDownload : (NSUInteger)  taskTocontinue  newTask:(NSUInteger&)  newTaskIdentifier;
- (void) continueAllDownload;

@end

#endif /* BackgroundDownloader_h */
