//
//  ECHLSCacheManager.h
//  HLSDownloader
//
//  Created by caiwanhong on 2025/8/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ECHLSCacheManager : NSObject

/// 生成指定 URL 字符串对应的 MD5 文件名（用于缓存命名）
/// @param urlStr 原始 URL 字符串
/// @return MD5 文件名
+ (NSString *)md5FileNameFromURLPath:(NSString *)urlStr;

/// 判断是否存在指定 URL 对应的 HLS 缓存文件
/// @param urlStr 原始 URL 字符串
/// @return 是否已缓存
+ (BOOL)hasCachedFileForURL:(NSString *)urlStr;

/// 将临时下载文件移动到 Document/adhls 目录下（用于正式缓存）
/// @param tempURL 临时文件路径
/// @param urlStr 原始 URL 字符串，用于生成目标路径
/// @return 是否移动成功
+ (BOOL)moveDownloadedFileToDocumentAdHLS:(NSURL *)tempURL forURL:(NSString *)urlStr;

/// 清除所有广告 HLS 缓存文件
+ (void)clearAllAdHLSCache;

/// 获取指定 URL 对应的本地缓存文件路径
/// @param urlStr 原始 URL 字符串
/// @return 本地缓存路径
+ (NSString *)localCachePathForURL:(NSString *)urlStr;

@end

NS_ASSUME_NONNULL_END
