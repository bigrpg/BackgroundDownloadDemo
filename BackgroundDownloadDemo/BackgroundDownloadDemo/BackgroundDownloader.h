//
//  BackgroundDownloader.h
//  BackgroundDownloadDemo
//
//  Created by zl on 2019/4/9.
//  Copyright © 2019 hkhust. All rights reserved.
//

#ifndef BackgroundDownloader_h
#define BackgroundDownloader_h


class BgDownloadCallback
{
public:
    virtual void onOneFileDownloadFinish(const char* tempFilename) = 0;
    virtual void onDataReceive(int64_t  totalBytesWritten, int64_t totalBytesExpectedToWrite) = 0;
    virtual void onTaskFailed(unsigned long taskIdentifier) = 0;
    virtual void onTaskSuccess(unsigned long taskIdentifier) = 0;
};


@interface BgSessionDownloadDelegate : NSObject<NSURLSessionDownloadDelegate>

- (BgSessionDownloadDelegate *) init: (NSString *) identifier  callback:(BgDownloadCallback *) callback;
@end

#endif /* BackgroundDownloader_h */
