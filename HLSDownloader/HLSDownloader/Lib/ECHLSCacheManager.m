//
//  ECHLSCacheManager.m
//  HLSDownloader
//
//  Created by caiwanhong on 2025/8/5.
//

#import "ECHLSCacheManager.h"
#import <CommonCrypto/CommonDigest.h>

@implementation ECHLSCacheManager

+ (BOOL)moveDownloadedFileToDocumentAdHLS:(NSURL *)tempURL forURL:(NSString *)urlStr {
    
    NSLog(@"HLSDownload：移动文件到Document tempURL=%@ urlStr=%@", tempURL, urlStr);
    
    if (!tempURL || !urlStr) return NO;
    
    NSString *fileName = [[self md5FromString:[NSURL URLWithString:urlStr].path] stringByAppendingPathExtension:@"movpkg"];
    NSString *targetPath = [[self documentAdHLSDirectory] stringByAppendingPathComponent:fileName];
    
    NSError *error = nil;
    
    // 判断文件是否存在且大小大于0
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:tempURL.path error:&error];
    if (error) {
        NSLog(@"HLSDownload：获取文件属性失败 %@", error);
        return NO;
    }

    NSNumber *fileSize = attributes[NSFileSize];
    if ([fileSize unsignedLongLongValue] == 0) {
        NSLog(@"HLSDownload：文件大小为0，下载失败或文件为空 %@", urlStr);
        return NO;
    }
    
    // 如果目标位置已存在，先删除，避免 move 出错
    if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:targetPath error:nil];
    }
    
    // 移动文件到目标路径
    [[NSFileManager defaultManager] moveItemAtURL:tempURL toURL:[NSURL fileURLWithPath:targetPath] error:&error];
    
    return (error == nil);
}

+ (BOOL)hasCachedFileForURL:(NSString *)urlStr {
    
    NSLog(@"HLSDownload：hasCache urlStr=%@",urlStr);
    
    if (!urlStr) return NO;
    
    NSString *path = [NSURL URLWithString:urlStr].path;
    
    NSString *fileName = [[self md5FromString:path] stringByAppendingPathExtension:@"movpkg"];
    NSString *filePath = [[self documentAdHLSDirectory] stringByAppendingPathComponent:fileName];
    
    NSLog(@"HLSDownload：fileName = %@  path = %@",fileName,path);
    
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

+ (void)clearAllAdHLSCache {
    
    NSLog(@"HLSDownload：clearAllAdHLSCache");
    
    NSString *adhlsDir = [self documentAdHLSDirectory];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:adhlsDir error:nil];
    for (NSString *file in files) {
        NSString *filePath = [adhlsDir stringByAppendingPathComponent:file];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}

+ (NSString *)localCachePathForURL:(NSString *)urlStr {
    if (urlStr.length == 0) return nil;

    NSString *fileName = [self md5FileNameFromURLPath:urlStr];
    NSString *fullPath = [[self documentAdHLSDirectory] stringByAppendingPathComponent:fileName];

    return fullPath;
}

+ (NSString *)md5FileNameFromURLPath:(NSString *)urlStr {
    
    NSLog(@"HLSDownload：获取本地文件名称 urlStr=%@",urlStr);
    
    if (!urlStr) return nil;
    
    NSString *urlPath = [NSURL URLWithString:urlStr].path;
    NSString *md5Name = [[self md5FromString:urlPath] stringByAppendingPathExtension:@"movpkg"];
    return md5Name;
}

+ (NSString *)documentAdHLSDirectory {
    // 返回缓存目录路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *cacheDirectory = [documentsDirectory stringByAppendingPathComponent:@"AdHLSCache"];
    
    // 如果目录不存在，创建该目录
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return cacheDirectory;
}

+ (NSString *)md5FromString:(NSString *)string {
    if (!string) return nil;
    
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

@end
