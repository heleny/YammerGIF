//
//  ViewController.m
//  YammerGIF
//
//  Created by Helen on 2016-11-15.
//  Copyright © 2016 Heleny. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking/AFNetworking.h>
#import "MWPhoto+Extended.h"

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray *urls;
@property (nonatomic, strong) NSMutableArray *searchSources;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) MWPhotoBrowser *browser;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *searchPhotos;
@property (nonatomic) BOOL didDisplayed;
@end

@implementation ViewController

#pragma mark - ViewController lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // Testing loading data from Giphy
    [self initArrays];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - initialization

- (void)initArrays {
    self.urls = [[NSMutableArray alloc] init];
    self.photos = [[NSMutableArray array] init];
    self.searchPhotos = [[NSMutableArray array] init];
    self.searchSources = [[NSMutableArray array] init];
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
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.searchBarStyle = UISearchBarIconResultsList;
    self.searchController.searchBar.tintColor = [UIColor whiteColor];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor darkGrayColor]]; // change the cursor's color
    self.searchController.searchBar.barTintColor = [UIColor darkGrayColor];
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = @"search gif here";
    [self.view addSubview:self.browser.view];
}

- (void)initMWPhotos {
    for (int i = 0; i < self.urls.count; i++) {
        MWPhoto *photo = [MWPhoto photoWithURL:[NSURL URLWithString:self.urls[i]]];
        photo.caption = self.urls[i];
        photo.slug = self.searchSources[i];
        [self.photos addObject:photo];
        [photo loadUnderlyingImageAndNotify];
    }
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
                for (NSDictionary *dict in data) {
                    NSString *searchSource = [self constructSearchSource:dict[@"slug"]];
                    [self.searchSources addObject:searchSource];
                    NSDictionary *imageDict = dict[@"images"];
                    NSDictionary *originalGif = imageDict[@"original"];
                    [self.urls addObject:originalGif[@"url"]];
                }
                
                [self initMWPhotos];
                NSLog(@"urls = %@", self.urls);
            }
        }
    }];
    
    [task resume];
}

- (NSString *)constructSearchSource:(NSString *)slug {
    if (!slug || slug.length == 0) {
        return nil;
    }
    
    NSString *result = [slug stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    NSLog(@"------ slug: %@", result);
    return result;
}

- (void)doneLoadingImage:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"MWPHOTO_LOADING_DID_END_NOTIFICATION"]) {
        id <MWPhoto> photo = [notification object];
        NSLog(@"Successfully done loading");
        if (photo && photo.underlyingImage && !self.browser.triggerOnce) {
            if (self.browser.gridIsON) {
                [self.browser refreshView];
            } else {
                [self.browser reloadData];
            }
        }
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
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

- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
    if (self.searchController.active) {
        if (!self.searchPhotos || self.searchPhotos.count == 0) {
            return nil;
        }
    } else if (!self.photos || self.photos.count == 0) {
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

#pragma mark - UISearchBarDelegate

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    if (!searchText || searchText.length == 0) {
        return;
    }

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"slug contains[c] %@", searchText];
    self.searchPhotos = [[self.photos filteredArrayUsingPredicate:predicate] copy];
    self.browser.thumbPhotos = self.searchPhotos;
    [self.browser refreshView];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSLog(@"search text = %@", searchText);
    if (searchText.length == 0) { // empty search text should reset the data to its original data
        [self resetSearch];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self resetSearch];
}

- (void)resetSearch {
    self.browser.thumbPhotos = self.photos;
    [self.browser refreshView];
}

#pragma mark - GridControllerShowAndHideDelegate

- (void)gridControllerDidShow {
    [self addSearchBar];
}

- (void)gridcontrollerDidHide {
    [self removeSearchBar];
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

@end
