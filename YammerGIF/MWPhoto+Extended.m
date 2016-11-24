//
//  MWPhoto+Extended.m
//  YammerGIF
//
//  Created by Helen on 2016-11-24.
//  Copyright © 2016 Heleny. All rights reserved.
//

#import "MWPhoto+Extended.h"
#import <objc/runtime.h>

@implementation MWPhoto (Extended)

const void *kSlugKey = @"kSlugKey";

- (void)setSlug:(NSString *)slug {
    return objc_setAssociatedObject(self, kSlugKey, slug, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)slug {
    return objc_getAssociatedObject(self, kSlugKey);
}

@end
