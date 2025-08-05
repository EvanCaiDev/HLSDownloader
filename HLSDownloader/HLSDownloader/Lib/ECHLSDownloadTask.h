//
//  ECHLSDownloadTask.h
//  HLSDownloader
//
//  Created by caiwanhong on 2025/8/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// HLS 下载任务模型（用于封装下载请求与回调）
@interface ECHLSDownloadTask : NSObject

/// HLS 资源地址
@property (nonatomic, strong) NSURL *url;

/// 下载完成后本地默认缓存文件路径（由 AVAssetDownloadDelegate 回调中获取）
@property (nonatomic, strong) NSURL *location;

/// 下载成功回调，返回本地缓存路径
@property (nonatomic, copy) void (^successCallback)(NSString *localPath);

/// 下载失败回调，返回错误信息
@property (nonatomic, copy) void (^failureCallback)(NSError *error);

@end

NS_ASSUME_NONNULL_END
