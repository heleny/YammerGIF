//
//  ViewController.m
//  YammerGIF
//
//  Created by Helen on 2016-11-15.
//  Copyright © 2016 Heleny. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking/AFNetworking.h>

@interface ViewController ()
@property (nonatomic, copy) NSArray *urls;
@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) MWPhotoBrowser *browser;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // Testing loading data from Giphy
    self.images = [NSMutableArray array];
    self.photos = [NSMutableArray array];
    [self fetchTrendingGIFs];
    [self initMWPhotoBrowser];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doneLoadingImage:) name:@"MWPHOTO_LOADING_DID_END_NOTIFICATION" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)saveToFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    NSString *dbFile = [documentPath stringByAppendingPathComponent:@"yammer_gif.xml"];
}

- (void)fetchTrendingGIFs {
    NSString *urlString = @"http://api.giphy.com/v1/gifs/trending?api_key=dc6zaTOxFJmzC";
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURLSessionDataTask *task = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR: %@", error);
        } else {
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *responseDictionary = responseObject;
                NSArray *data = responseDictionary[@"data"];
                NSLog(@"data size = %ld", data.count);
                NSMutableArray *urls = [NSMutableArray array];
                for (NSDictionary *dict in data) {
                    NSDictionary *imageDict = dict[@"images"];
                    NSDictionary *originalGif = imageDict[@"original"];
                    [urls addObject:originalGif[@"url"]];
                }
                self.urls = urls;
                [self initMWPhotos];
                NSLog(@"urls = %@", urls);
            }
        }
    }];
    
    [task resume];
}

- (void)initMWPhotoBrowser {
    self.title = @"Photo Browser";
    self.browser.title = @"My Photo Browser";
    self.browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    self.browser.displayActionButton = NO;
    self.browser.displayNavArrows = YES;
    self.browser.displaySelectionButtons = NO;
    self.browser.zoomPhotosToFill = YES;
    self.browser.alwaysShowControls = NO;
    self.browser.enableGrid = YES;
    self.browser.startOnGrid = NO;
    self.browser.enableSwipeToDismiss = NO;
    self.browser.navigationController.navigationBarHidden = YES;
    [self.view addSubview:self.browser.view];
    [self.navigationController pushViewController:self.browser animated:YES];
    
    [self.browser showNextPhotoAnimated:YES];
    [self.browser showPreviousPhotoAnimated:YES];
//    [self.browser reloadData];
}

- (void)initMWPhotos {
    for (NSString *url in self.urls) {
        MWPhoto *photo = [MWPhoto photoWithURL:[NSURL URLWithString:url]];
        photo.caption = url;
        [self.photos addObject:photo];
        [photo loadUnderlyingImageAndNotify];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - MWPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (!self.browser.triggerOnce && index < self.photos.count) {
        NSLog(@"photoAtIndex index=%lu", index);
        return [self.photos objectAtIndex:index];
    }
    
    return nil;
}


- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < self.photos.count) {
        NSLog(@"thumbPhotoAtIndex index=%lu", index);
        return [self.photos objectAtIndex:index];
    }
    
    return nil;
}

- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
    MWPhoto *photo = [self.photos objectAtIndex:index];
    return photo.caption;
}

- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
    if (self.photos.count == 0) {
        return nil;
    }

    MWPhoto * photo = [self.photos objectAtIndex:index];
    MWCaptionView *view = [[MWCaptionView alloc] initWithPhoto:photo];
    return view;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"did display photo at index %lu", index);
}


- (void)doneLoadingImage:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"MWPHOTO_LOADING_DID_END_NOTIFICATION"]) {
        id <MWPhoto> photo = [notification object];
        NSLog(@"Successfully done loading");
        if (photo && photo.underlyingImage && !self.browser.triggerOnce) {
            [self.images addObject:photo.underlyingImage];
            [self.browser reloadData];
        }
    }
}


@end
