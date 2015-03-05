//
//  NYTTestiOS7TransitionContext.m
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/26/15.
//  Copyright (c) 2015 NYTimes. All rights reserved.
//

#import "NYTTestiOS7TransitionContext.h"

@implementation NYTTestiOS7TransitionContext

+ (BOOL)instancesRespondToSelector:(SEL)aSelector {
    if (aSelector == @selector(viewForKey:)) {
        return NO;
    }
    
    return [super instancesRespondToSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if (aSelector == @selector(viewForKey:)) {
        return NO;
    }
    
    return [super respondsToSelector:aSelector];
}

- (UIView *)containerView {
    return nil;
}

- (BOOL)isAnimated {
    return NO;
}

- (BOOL)isInteractive {
    return NO;
}

- (BOOL)transitionWasCancelled {
    return NO;
}

- (UIModalPresentationStyle)presentationStyle {
    return UIModalPresentationCustom;
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete{}
- (void)finishInteractiveTransition{}
- (void)cancelInteractiveTransition{}
- (void)completeTransition:(BOOL)didComplete{}

- (UIViewController *)viewControllerForKey:(NSString *)key {
    return nil;
}

- (UIView *)viewForKey:(NSString *)key {
    return nil;
}

- (CGAffineTransform)targetTransform {
    return CGAffineTransformIdentity;
}

- (CGRect)initialFrameForViewController:(UIViewController *)vc {
    return CGRectZero;
}

- (CGRect)finalFrameForViewController:(UIViewController *)vc {
    return CGRectZero;
}

@end
