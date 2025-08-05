//
//  ViewController.m
//  HLSDownloader
//
//  Created by caiwanhong on 2025/8/4.
//

#import "ViewController.h"
#import "ECHLSDownloadManager.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *downLoadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    downLoadBtn.frame = CGRectMake(150, 200, 150, 40);
    [downLoadBtn setTitle:@"下载m3u8并播放" forState:UIControlStateNormal];
    [downLoadBtn addTarget:self action:@selector(downloadedHLS) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:downLoadBtn];
}

- (void)downloadedHLS {
    
    NSURL *hlsURL = [NSURL URLWithString:@"XXX"];
    
    [[ECHLSDownloadManager sharedManager] enqueueDownloadWithURL:hlsURL
                                                                 title:@"hls"
                                                               success:^(NSString *localPath) {
        NSLog(@"hls下载完成：%@", localPath);
        [self playHLS:localPath];
        
    } failure:^(NSError *error) {
        NSLog(@"hls下载失败：%@", error);
    }];
}

- (void)playHLS:(NSString *)localPath {

    NSURL *localURL = [NSURL fileURLWithPath:localPath];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:localURL options:nil];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];

    self.player = [AVPlayer playerWithPlayerItem:item];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.view.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;

    [self.view.layer addSublayer:self.playerLayer];
    [self.player play];
}
@end
