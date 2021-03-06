//
//  BackgroundDownloader.m
//
//  Created by zl on 2019/4/9.
//  Copyright © 2019 hkhust. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "BackgroundDownloader.h"

typedef void(^CompletionHandlerType)();

@interface AzureBackgroundDownloader()
{
    AzureBackgroundDownloadCallback * callback;
}

@property (strong, nonatomic) NSMutableDictionary *completionHandlerDictionary;
@property (strong, nonatomic) NSURLSession *backgroundSession;
@property (strong, nonatomic) NSMutableSet * tasks;
@property (strong, nonatomic) NSMutableDictionary * tasksInfo;
@property (strong, nonatomic) NSString * identifier;

@end


@implementation AzureBackgroundDownloader

- (AzureBackgroundDownloader *) init : (NSString *) identifier  callback:(AzureBackgroundDownloadCallback *) callback_
{
    self.identifier = identifier;
    self.completionHandlerDictionary = @{}.mutableCopy;
    self.backgroundSession = [self backgroundURLSession:self.identifier];
    self.tasks = [[NSMutableSet alloc] init];
    self.tasksInfo = [[NSMutableDictionary alloc] init];
    callback = callback_;
    
    return self;
}

- (NSURLSession *)backgroundURLSession : (NSString *) identifier {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration* sessionConfig = nil;
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 80000)
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
#else
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
#endif
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return session;
}

- (void)addCompletionHandler:(CompletionHandlerType)handler forSession:(NSString *)identifier {
    if ([self.completionHandlerDictionary objectForKey:identifier]) {
        NSLog(@"Error: Got multiple handlers for a single session identifier.  This should not happen.\n");
    }
    
    [self.completionHandlerDictionary setObject:handler forKey:identifier];
}

- (void)callCompletionHandlerForSession:(NSString *)identifier {
    CompletionHandlerType handler = [self.completionHandlerDictionary objectForKey:identifier];
    
    if (handler) {
        [self.completionHandlerDictionary removeObjectForKey: identifier];
        NSLog(@"Calling completion handler for session %@", identifier);
        
        handler();
    }
}

#pragma mark - Public Mehtod
- (NSUInteger)beginDownloadWithUrl:(NSString *)downloadURLString {
    NSURL *downloadURL = [NSURL URLWithString:downloadURLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
    NSURLSessionDownloadTask  * task = [self.backgroundSession downloadTaskWithRequest:request];
    [self.tasks addObject:task];
    [task resume];
    return task.taskIdentifier;
}

//Pause one task
- (void)pauseOneDownload : (NSUInteger)  taskTopause  isStop:(BOOL) isStop {
    __weak __typeof(self) wSelf = self;
    
    NSEnumerator * en = [self.tasks objectEnumerator];
    NSURLSessionDownloadTask * task;
    while (task = [en nextObject])
    {
        if(taskTopause && taskTopause != task.taskIdentifier)
            continue;
        [task cancelByProducingResumeData:^(NSData * resumeData) {
            __strong __typeof(wSelf) sSelf = wSelf;
            if(isStop == NO)
            {
                if(resumeData)
                    [sSelf.tasksInfo setObject:resumeData forKey:task];
            }
        }];
        
        [self.tasks removeObject:task];
        break;
        
    }
}

//Pause all task
- (void)pauseAllDownload : (BOOL) isStop {
    __weak __typeof(self) wSelf = self;
    
    NSEnumerator * en = [self.tasks objectEnumerator];
    NSURLSessionDownloadTask * task;
    while (task = [en nextObject])
    {
        [task cancelByProducingResumeData:^(NSData * resumeData) {
            __strong __typeof(wSelf) sSelf = wSelf;
            if(isStop == NO)
            {
                if(resumeData)
                    [sSelf.tasksInfo setObject:resumeData forKey:task];
            }
        }];
    }
    
    [self.tasks removeAllObjects];
    
}

//Continue one task
- (BOOL)continueOneDownload : (NSUInteger)  taskTocontinue  newTask:(NSUInteger&)  newTaskIdentifier {
    
    for(NSURLSessionDownloadTask  * task in self.tasksInfo)
    {
        if(taskTocontinue && taskTocontinue != task.taskIdentifier)
            continue;
        NSData * data = self.tasksInfo[task];
        if (data) {
            NSURLSessionDownloadTask  * newTask;
            newTask = [self.backgroundSession downloadTaskWithResumeData:data];
            [newTask resume];
            [self.tasks addObject:newTask];

            [self.tasksInfo removeObjectForKey:task];
            newTaskIdentifier = newTask.taskIdentifier;
            return YES;
            
        }
    }
    return NO;
}

//Continue all task
- (void)continueAllDownload {
    
    for(NSURLSessionDownloadTask  * task in self.tasksInfo)
    {
        NSData * data = self.tasksInfo[task];
        if (data) {
            NSURLSessionDownloadTask  * newTask;
            newTask = [self.backgroundSession downloadTaskWithResumeData:data];
            [newTask resume];
            [self.tasks addObject:newTask];
        }
    }
    [self.tasksInfo removeAllObjects];
}

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSLog(@"downloadTask:%lu didFinishDownloadingToURL:%@", (unsigned long)downloadTask.taskIdentifier, location);
    NSString *locationString = [location path];
    if(callback)
        callback->onOneFileDownloadFinish(downloadTask.taskIdentifier, locationString );
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    NSLog(@"fileOffset:%lld expectedTotalBytes:%lld",fileOffset,expectedTotalBytes);
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    if(callback)
        callback->onDataReceive(downloadTask.taskIdentifier, totalBytesWritten,totalBytesExpectedToWrite);
    
}


#pragma mark - NSURLSessionDelegate
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"Background URL session %@ finished events.\n", session);
    
    if (session.configuration.identifier) {
        // 调用在 -application:handleEventsForBackgroundURLSession: 中保存的 handler
        [self callCompletionHandlerForSession:session.configuration.identifier];
    }
}


#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    
    if (error) {
        // check if resume data are available
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
            //self.resumeData = resumeData;
            if(resumeData)
                [self.tasksInfo setObject:resumeData forKey:task];
        }
        else
        {
            [self.tasks removeObject:task];
            [self.tasksInfo removeObjectForKey:task];
            if(callback)
                callback->onTaskFailed(task.taskIdentifier);
        }
    } else {
        //[self sendLocalNotification];
        //[self postDownlaodProgressNotification:@"1"];
        [self.tasks removeObject:task];
        [self.tasksInfo removeObjectForKey:task];
        if(callback)
            callback->onTaskSuccess(task.taskIdentifier);
    }
}

@end
