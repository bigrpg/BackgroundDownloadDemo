//
//  ViewController.m
//  BackgroundDownloadDemo
//
//  Created by HK on 16/9/10.
//  Copyright © 2016年 hkhust. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIProgressView *downloadProgress;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloadProgress:) name:kDownloadProgressNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateDownloadProgress:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGFloat fProgress = [userInfo[@"progress"] floatValue];
    self.progressLabel.text = [NSString stringWithFormat:@"%.2f%%",fProgress * 100];
    self.downloadProgress.progress = fProgress;
}

#pragma mark Method
- (IBAction)download:(id)sender {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //[delegate beginDownloadWithUrl:@"https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-9.8.0-amd64-netinst.iso"];
    [delegate beginDownloadWithUrl:@"http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.5.3.dmg"];
    //[delegate beginDownloadWithUrl:@"http://d1.music.126.net/dmusic/NeteaseMusic_2.0.0_730_web.dmg"];
}

- (IBAction)download2:(id)sender {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //[delegate beginDownloadWithUrl:@"https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-9.8.0-amd64-netinst.iso"];
    //[delegate beginDownloadWithUrl:@"http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.5.3.dmg"];
    [delegate beginDownloadWithUrl:@"http://d1.music.126.net/dmusic/NeteaseMusic_2.0.0_730_web.dmg"];
}

- (IBAction)pauseDownlaod:(id)sender {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate pauseDownload:nil isStop:NO];
}

- (IBAction)continueDownlaod:(id)sender {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate continueDownload:nil];
}

@end
