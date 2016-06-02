//
//  NYTScalingImageView.m
//  NYTPhotoViewer
//
//  Created by Harrison, Andrew on 7/23/13.
//  Copyright (c) 2015 The New York Times Company. All rights reserved.
//

#import "NYTScalingImageView.h"

#import "tgmath.h"

#import "JNPieLoader.h"
#import "SDWebImageManager.h"

#ifdef ANIMATED_GIF_SUPPORT
#import <FLAnimatedImage/FLAnimatedImage.h>
#endif

@interface NYTScalingImageView ()

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

#ifdef ANIMATED_GIF_SUPPORT
@property (nonatomic) FLAnimatedImageView *imageView;
#else
@property (nonatomic) UIImageView *imageView;
#endif

@property (nonatomic) NSArray *imageURLs;

@end

@implementation NYTScalingImageView

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithImage:[UIImage new] frame:frame];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self commonInitWithImage:nil imageData:nil imageURLs:nil];
    }

    return self;
}

- (void)didAddSubview:(UIView *)subview {
    [super didAddSubview:subview];
    [self centerScrollViewContents];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updateZoomScale];
    [self centerScrollViewContents];
}

#pragma mark - NYTScalingImageView

- (instancetype)initWithImage:(UIImage *)image frame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self commonInitWithImage:image imageData:nil imageURLs:nil];
    }
    
    return self;
}

- (instancetype)initWithImageData:(NSData *)imageData frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInitWithImage:nil imageData:imageData imageURLs:nil];
    }
    
    return self;
}

- (instancetype)initWithImageURLs:(NSArray *)urls frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInitWithImage:nil imageData:nil imageURLs:urls];
    }
    
    return self;
}

- (void)commonInitWithImage:(UIImage *)image imageData:(NSData *)imageData imageURLs:(NSArray *)urls {
    [self setupInternalImageViewWithImage:image imageData:imageData imageURL:urls];
    [self setupImageScrollView];
    [self updateZoomScale];
}

#pragma mark - Setup

- (void)setupInternalImageViewWithImage:(UIImage *)image imageData:(NSData *)imageData imageURL:(NSArray *)urls {
    UIImage *imageToUse = image ?: [UIImage imageWithData:imageData];

#ifdef ANIMATED_GIF_SUPPORT
    self.imageView = [[FLAnimatedImageView alloc] initWithImage:imageToUse];
#else
    self.imageView = [[UIImageView alloc] initWithImage:imageToUse];
#endif
        
    [self updateImage:imageToUse imageData:imageData imageURLs:urls];
    
    [self addSubview:self.imageView];
}

- (void)updateImage:(UIImage *)image {
    [self updateImage:image imageData:nil imageURLs:nil];
}

- (void)updateImageData:(NSData *)imageData {
    [self updateImage:nil imageData:imageData imageURLs:nil];
}

- (void)updateImageURLs:(NSArray *)imageURLs {
    [self updateImage:nil imageData:nil imageURLs:imageURLs];
}

- (void)updateImage:(UIImage *)image imageData:(NSData *)imageData imageURLs:(NSArray *)urls {
#ifdef DEBUG
#ifndef ANIMATED_GIF_SUPPORT
    if (imageData != nil) {
        NSLog(@"[NYTPhotoViewer] Warning! You're providing imageData for a photo, but NYTPhotoViewer was compiled without animated GIF support. You should use native UIImages for non-animated photos. See the NYTPhoto protocol documentation for discussion.");
    }
#endif // ANIMATED_GIF_SUPPORT
#endif // DEBUG

    UIImage *imageToUse = image ?: [UIImage imageWithData:imageData];

    // Remove any transform currently applied by the scroll view zooming.
    self.imageView.transform = CGAffineTransformIdentity;
    self.imageView.image = imageToUse;
    
#ifdef ANIMATED_GIF_SUPPORT
    // It's necessarry to first assign the UIImage so calulations for layout go right (see above)
    self.imageView.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData];
#endif
    
    void (^update)(UIImage *) = ^(UIImage* image) {
        self.imageView.transform = CGAffineTransformIdentity;
        self.imageView.image = image;
        self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
        
        self.contentSize = image.size;
        
        [self updateZoomScale];
        [self centerScrollViewContents];
    };
    
    update(imageToUse);
    
    self.imageURLs = urls;
    
    [self downloadImageWithURL:self.imageURLs indexOfCurrentURL:0 increment:YES completion:^(UIImage *image) {
        update(image);
    }];
}

- (void)downloadImageWithURL:(NSArray *)urls indexOfCurrentURL:(NSInteger)index increment:(BOOL)increment completion:(void(^)(UIImage *))completion  {
    __block NSInteger aIndex = index;
    
    
    JNPieLoader *loader = [JNPieLoader.alloc initWithFrame:CGRectMake(0, 0, 30.f, 30.f)];
    [self addSubview:loader];
    if (index == 0) {
        loader.center = self.imageView.center;
    } else {
        CGRect frame = loader.frame;
        frame.origin.x = 10.f;
        frame.origin.y = (self.imageView.frame.size.height - loader.frame.size.height) - 10.f;
        loader.frame = frame;
        loader.alpha = 0.4f;
    }
    loader.hidden = YES;
    
    UIImageView *imageView = [UIImageView.alloc initWithFrame:loader.frame];
    imageView.image = [UIImage imageNamed:@"FeedBlankStatusButton.png"];
    imageView.alpha = 0.4f;
    [self addSubview:imageView];
    
    [SDWebImageManager.sharedManager downloadImageWithURL:urls[aIndex] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        if ((float)receivedSize/(float)expectedSize > 0) {
            imageView.hidden = YES;
            loader.hidden = NO;
        }
        [loader updateCurrentValue:(float)receivedSize/(float)expectedSize];
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        [loader removeFromSuperview];
        [imageView removeFromSuperview];
        if (image) {
            if (completion) {
                completion(image);
                aIndex =  aIndex + (increment ? 1 : 0);
                if (aIndex < urls.count)
                    [self downloadImageWithURL:urls indexOfCurrentURL:aIndex increment:YES completion:completion];
            }
        } else {
            [self downloadImageWithURL:urls  indexOfCurrentURL:index increment:NO completion:completion];
        }
    }];
}

- (void)setupImageScrollView {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.bouncesZoom = YES;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
}

- (void)updateZoomScale {
#ifdef ANIMATED_GIF_SUPPORT
    if (self.imageView.animatedImage || self.imageView.image) {
#else
    if (self.imageView.image) {
#endif
        CGRect scrollViewFrame = self.bounds;
        
        CGFloat scaleWidth = scrollViewFrame.size.width / self.imageView.image.size.width;
        CGFloat scaleHeight = scrollViewFrame.size.height / self.imageView.image.size.height;
        CGFloat minScale = MIN(scaleWidth, scaleHeight);
        
        self.minimumZoomScale = minScale;
        self.maximumZoomScale = MAX(minScale, self.maximumZoomScale);
        
        self.zoomScale = self.minimumZoomScale;
        
        // scrollView.panGestureRecognizer.enabled is on by default and enabled by
        // viewWillLayoutSubviews in the container controller so disable it here
        // to prevent an interference with the container controller's pan gesture.
        //
        // This is enabled in scrollViewWillBeginZooming so panning while zoomed-in
        // is unaffected.
        self.panGestureRecognizer.enabled = NO;
    }
}

#pragma mark - Centering

- (void)centerScrollViewContents {
    CGFloat horizontalInset = 0;
    CGFloat verticalInset = 0;
    
    if (self.contentSize.width < CGRectGetWidth(self.bounds)) {
        horizontalInset = (CGRectGetWidth(self.bounds) - self.contentSize.width) * 0.5;
    }
    
    if (self.contentSize.height < CGRectGetHeight(self.bounds)) {
        verticalInset = (CGRectGetHeight(self.bounds) - self.contentSize.height) * 0.5;
    }
    
    if (self.window.screen.scale < 2.0) {
        horizontalInset = __tg_floor(horizontalInset);
        verticalInset = __tg_floor(verticalInset);
    }
    
    // Use `contentInset` to center the contents in the scroll view. Reasoning explained here: http://petersteinberger.com/blog/2013/how-to-center-uiscrollview/
    self.contentInset = UIEdgeInsetsMake(verticalInset, horizontalInset, verticalInset, horizontalInset);
}

@end
