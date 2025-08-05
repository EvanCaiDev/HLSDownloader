//
//  ECHLSDownloadManager.m
//  HLSDownloader
//
//  Created by caiwanhong on 2025/8/5.
//

#import "ECHLSDownloadManager.h"
#import <AVFoundation/AVFoundation.h>
#import "ECHLSCacheManager.h"
#import "ECHLSDownloadTask.h"

@interface ECHLSDownloadManager() <AVAssetDownloadDelegate>

@property (nonatomic, strong) AVAssetDownloadURLSession *downloadSession;
@property (nonatomic, strong) NSMutableArray<ECHLSDownloadTask *> *taskQueue;
@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURL *> *taskLocationMap;
@end

@implementation ECHLSDownloadManager

+ (instancetype)sharedManager {
    static ECHLSDownloadManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ECHLSDownloadManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _taskQueue = [NSMutableArray array];
        _isDownloading = NO;
        [self setupDownloadSession];
    }
    return self;
}

- (void)setupDownloadSession {
    // 动态 identifier 防止系统 session 重复冲突
    NSString *identifier = [NSString stringWithFormat:@"hls.background.session.%@", NSUUID.UUID.UUIDString];
    NSURLSessionConfiguration *backgroundConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];

    self.downloadSession = [AVAssetDownloadURLSession sessionWithConfiguration:backgroundConfig
                                                           assetDownloadDelegate:self
                                                                  delegateQueue:[NSOperationQueue mainQueue]];
}

- (void)enqueueDownloadWithURL:(NSURL *)url
                         title:(NSString *)title
                       success:(void(^)(NSString *localPath))success
                       failure:(void(^)(NSError *error))failure {

    for (ECHLSDownloadTask *existing in self.taskQueue) {
        if ([existing.url.absoluteString isEqualToString:url.absoluteString]) {
            NSLog(@"HLSDownload：已存在任务 %@", url);
            return;
        }
    }

    ECHLSDownloadTask *task = [[ECHLSDownloadTask alloc] init];
    task.url = url;
    task.successCallback = success;
    task.failureCallback = failure;

    [self.taskQueue addObject:task];
    [self startNextDownloadIfNeeded];
}

- (void)startNextDownloadIfNeeded {
    if (self.isDownloading || self.taskQueue.count == 0) return;

    self.isDownloading = YES;
    ECHLSDownloadTask *task = self.taskQueue.firstObject;
    AVURLAsset *asset = [AVURLAsset assetWithURL:task.url];

    AVAssetDownloadTask *downloadTask = [self.downloadSession assetDownloadTaskWithURLAsset:asset
                                                                                assetTitle:task.url.lastPathComponent
                                                                         assetArtworkData:nil
                                                                                  options:nil];
    if (downloadTask) {
        [downloadTask resume];
        NSLog(@"HLSDownload：开始下载 %@", task.url.absoluteString);
    } else {
        NSLog(@"HLSDownload：任务创建失败 %@", task.url);
        [self.taskQueue removeObjectAtIndex:0];
        self.isDownloading = NO;
        [self startNextDownloadIfNeeded];
    }
}

#pragma mark - Private
- (ECHLSDownloadTask *)taskForAssetDownloadTask:(AVAssetDownloadTask *)assetTask {
    NSURL *url = assetTask.URLAsset.URL;
    for (ECHLSDownloadTask *task in self.taskQueue) {
        if ([task.url isEqual:url]) {
            return task;
        }
    }
    return nil;
}

#pragma mark - AVAssetDownloadDelegate
// 当下载完成时调用此代理方法，`location` 是下载文件的存储位置
- (void)URLSession:(NSURLSession *)session assetDownloadTask:(AVAssetDownloadTask *)assetDownloadTask didFinishDownloadingToURL:(NSURL *)location {
    ECHLSDownloadTask *task = [self taskForAssetDownloadTask:assetDownloadTask];
    if (task) {
        task.location = location;
        NSLog(@"HLSDownload：记录 location = %@", location.path);
    } else {
        NSLog(@"HLSDownload：未能匹配到任务，无法记录 location");
    }
}

// 下载失败或完成
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)sessionTask didCompleteWithError:(NSError *)error {

    AVAssetDownloadTask *assetDownloadTask = (AVAssetDownloadTask *)sessionTask;
    ECHLSDownloadTask *task = [self taskForAssetDownloadTask:assetDownloadTask];

    if (!task) {
        NSLog(@"HLSDownload：任务完成但未找到匹配项");
        return;
    }

    NSString *urlStr = task.url.absoluteString;

    if (error) {
        NSLog(@"HLSDownload：任务失败 ❌ %@", error);
        
        // 删除临时文件（如果下载失败）
        if (task.location) {
            NSError *deleteError = nil;
            [[NSFileManager defaultManager] removeItemAtURL:task.location error:&deleteError];
            if (deleteError) {
                NSLog(@"HLSDownload：删除失败文件失败 %@", deleteError);
            } else {
                NSLog(@"HLSDownload：删除失败文件成功 %@", task.location.path);
            }
        }
        
        if (task.failureCallback) {
            task.failureCallback(error);
        }
        [self.taskQueue removeObject:task];
        self.isDownloading = NO;
        [self startNextDownloadIfNeeded];
        return;
    }

    // 下载成功，移动缓存文件
    NSURL *location = task.location;
    if (!location || ![location isKindOfClass:[NSURL class]]) {
        NSLog(@"HLSDownload：未获取到有效文件位置 url = %@", task.url);
        if (task.failureCallback) {
            NSError *locationError = [NSError errorWithDomain:@"com.adsdk.hls"
                                                         code:-1002
                                                     userInfo:@{NSLocalizedDescriptionKey: @"文件路径无效"}];
            task.failureCallback(locationError);
        }
        [self.taskQueue removeObject:task];
        self.isDownloading = NO;
        [self startNextDownloadIfNeeded];
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL moved = [ECHLSCacheManager moveDownloadedFileToDocumentAdHLS:location forURL:urlStr];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (moved) {
                if (task.successCallback) {
                    NSString *localPath = [ECHLSCacheManager localCachePathForURL:urlStr];
                    task.successCallback(localPath);
                    NSLog(@"HLSDownload：下载完成 ✅ %@", urlStr);
                }
            } else {
                NSLog(@"HLSDownload：缓存文件移动失败 %@", urlStr);
                if (task.failureCallback) {
                    NSError *moveError = [NSError errorWithDomain:@"com.adsdk.hls"
                                                             code:-1001
                                                         userInfo:@{NSLocalizedDescriptionKey: @"文件移动失败"}];
                    task.failureCallback(moveError);
                }
            }

            [self.taskQueue removeObject:task];
            self.isDownloading = NO;
            [self startNextDownloadIfNeeded];
        });
    });
}

@end
