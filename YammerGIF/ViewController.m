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
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *searchPhotos;
@property (nonatomic) BOOL didDisplayed;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // Testing loading data from Giphy
    self.images = [NSMutableArray array];
    self.photos = [NSMutableArray array];
    self.searchPhotos = [NSMutableArray array];
    [self fetchTrendingGIFs];
    [self initMWPhotoBrowser];
    [self initUISearchController];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doneLoadingImage:) name:@"MWPHOTO_LOADING_DID_END_NOTIFICATION" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    [self.browser showNextPhotoAnimated:YES];
    [self.browser showPreviousPhotoAnimated:YES];
    self.browser.gridControllerShowAndHideDelegate = self;
}

- (void)initUISearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchBar.delegate = self;
    self.searchController.searchResultsUpdater = self;
    [self.searchController.searchBar sizeToFit];
    self.searchController.dimsBackgroundDuringPresentation = YES;
    self.definesPresentationContext = YES;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.tintColor = [UIColor whiteColor];
    self.searchController.searchBar.barTintColor = [UIColor brownColor];
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = @"search gif here";
    [self.view addSubview:self.browser.view];
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
    if (self.searchController.active) {
        return self.searchPhotos.count;
    }

    return self.photos.count;
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (photoBrowser.triggerOnce) {
        index = photoBrowser.currentIndex;
    }
    
    NSUInteger count = self.searchController.active ? self.searchPhotos.count : self.photos.count;
    if (index < count) {
        NSLog(@"photoAtIndex index=%lu", index);
        if (self.searchController.active) {
            return self.searchPhotos[index];
        }
        return self.photos[index];
    }
    
    return nil;
}


- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    NSUInteger count = self.searchController.active ? self.searchPhotos.count : self.photos.count;
    
    if (index < count) {
        NSLog(@"thumbPhotoAtIndex index=%lu", index);
        self.didDisplayed = NO;
        if (self.searchController.active) {
            return self.searchPhotos[index];
        }
        return self.photos[index];
    }
    
    return nil;
}

- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
    if (photoBrowser.triggerOnce) {
        index = photoBrowser.currentIndex;
    }
    
    MWPhoto *photo = self.photos[index];
    if (self.searchController.active) {
        photo = self.searchPhotos[index];
    }
    
    return photo.caption;
}

- (void)addSearchBar {
    CGRect frame = self.browser.view.frame;
    self.browser.view.frame = CGRectMake(frame.origin.x, frame.origin.y + self.searchController.searchBar.frame.size.height, frame.size.width, frame.size.height);
    [self.view addSubview:self.searchController.searchBar];
}

- (void)removeSearchBar {
    [self.searchController.searchBar removeFromSuperview];
    self.browser.view.frame = [[UIScreen mainScreen] bounds];
}

- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
    if (self.photos.count == 0) {
        return nil;
    }

    if (photoBrowser.triggerOnce) {
        index = photoBrowser.currentIndex;
    }
    MWPhoto *photo = self.photos[index];
    if (self.searchController.active) {
        photo = self.searchPhotos[index];
    }
    MWCaptionView *view = [[MWCaptionView alloc] initWithPhoto:photo];
    return view;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"did display photo at index %lu", index);
    if (photoBrowser.gridIsON) {
        self.didDisplayed = YES;
    }
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

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSLog(@"update search results for search controller");
//    NSString *searchText = searchController.searchBar.text;
//    NSPredicate *predicate;
//    NSInteger scope = searchController.searchBar.selectedScopeButtonIndex;
//    if (scope == 0) {
//        predicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", searchText];
//    } else {
//        predicate = [NSPredicate predicateWithFormat:@"description contains[c] %@", searchText];
//    }
//    
//    self.searchPhotos = [[self.photos filteredArrayUsingPredicate:predicate] copy];
//    [self.browser reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSLog(@"search text = %@", searchText);
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    NSLog(@"selected scope button index did change");
    [self updateSearchResultsForSearchController:self.searchController];
}

#pragma mark - GridControllerShowAndHideDelegate
- (void)gridControllerDidShow {
    [self addSearchBar];
}

- (void)gridcontrollerDidHide {
    [self removeSearchBar];
}

@end
