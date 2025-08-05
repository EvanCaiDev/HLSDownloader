//
//  ECHLSDownloadManager.h
//  HLSDownloader
//
//  Created by caiwanhong on 2025/8/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// HLS 下载管理器，用于管理 HLS 视频资源的缓存下载
@interface ECHLSDownloadManager : NSObject

/// 获取 HLS 下载管理器单例对象。
/// @return 下载管理器的单例实例。
+ (instancetype)sharedManager;

/// 将一个 HLS 下载任务加入下载队列，下载将自动串行进行。
/// @param url HLS 资源的 URL。
/// @param title 资源标题（用于内部标识，实际可忽略）。
/// @param success 下载成功回调，返回本地缓存路径。
/// @param failure 下载失败回调，返回错误信息。
- (void)enqueueDownloadWithURL:(NSURL *)url
                         title:(NSString *)title
                       success:(void(^)(NSString *localPath))success
                       failure:(void(^)(NSError *error))failure;
@end

NS_ASSUME_NONNULL_END
