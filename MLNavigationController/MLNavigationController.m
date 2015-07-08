//
//  MLNavigationController.m
//  MultiLayerNavigation
//
//  Created by Feather Chan on 13-4-12.
//  Copyright (c) 2013年 Feather Chan. All rights reserved.
//

#define KEY_WINDOW  [[UIApplication sharedApplication] keyWindow]

#import "MLNavigationController.h"
#import <QuartzCore/QuartzCore.h>

@interface MLNavigationController ()
{
    CGPoint startTouch;
    UIImageView *lastScreenShotView;
    UIPanGestureRecognizer * _recognizer;
}

@property (nonatomic,retain) NSMutableArray *screenShotsList;
@property (nonatomic,assign) BOOL isMoving;

@end

@implementation MLNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        self.screenShotsList = [[[NSMutableArray alloc] init] autorelease];
    }
    return self;
}

- (void)dealloc
{
    self.screenShotsList = nil;
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _recognizer = [[[UIPanGestureRecognizer alloc]initWithTarget:self
                                                                                 action:@selector(paningGestureReceive:)]autorelease];
    [_recognizer delaysTouchesBegan];
    [self.view addGestureRecognizer:_recognizer];
    //
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    self.view.layer.shadowOpacity = 0.9;
    self.view.layer.shadowOffset = CGSizeMake(0, -3);
    self.view.layer.shadowRadius = 3;
}


// override the push method
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    BOOL canDragBack = [viewController canDragBack];
    [self.screenShotsList addObject:[NSDictionary dictionaryWithObjectsAndKeys:[self capture],@"capture",[NSNumber numberWithBool:canDragBack],@"canDragBack", nil]];
    _recognizer.enabled = canDragBack;//
    [super pushViewController:viewController animated:animated];
}

// override the pop method
- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    [self.screenShotsList removeLastObject];
    BOOL canDragBack = TRUE;
    NSDictionary *dic = [self.screenShotsList lastObject];
    if(dic)
    {
        canDragBack = [[dic objectForKey:@"canDragBack"] boolValue];
    }
    _recognizer.enabled = canDragBack;//
    return [super popViewControllerAnimated:animated];
}
- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if(viewController)
    {
        NSArray * viewControllers = self.viewControllers;
        int index = [viewControllers indexOfObject:viewController];
        int count = [self.screenShotsList count];
        if(index < count)
        {
            [self.screenShotsList removeObjectsInRange:NSMakeRange(index, count - 1)];
        }
    }
    BOOL canDragBack = TRUE;
    NSDictionary *dic = [self.screenShotsList lastObject];
    if(dic)
    {
        canDragBack = [[dic objectForKey:@"canDragBack"] boolValue];
    }
    _recognizer.enabled = canDragBack;//
    return [super popToViewController:viewController animated:animated];
}
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated;
{
    int count = [self.screenShotsList count];
    if(count > 1)
    {
        [self.screenShotsList removeObjectsInRange:NSMakeRange(1, count - 1)];
    }
    BOOL canDragBack = TRUE;
    NSDictionary *dic = [self.screenShotsList lastObject];
    if(dic)
    {
        canDragBack = [[dic objectForKey:@"canDragBack"] boolValue];
    }
    _recognizer.enabled = canDragBack;//
    return [super popToRootViewControllerAnimated:animated];
}
#pragma mark - Utility Methods -

// get the current view screen shot
- (UIImage *)capture
{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

- (void)moveViewWithX:(float)x
{
    
    x = x>320?320:x;
    x = x<0?0:x;
    
    CGRect frame = self.view.frame;
    frame.origin.x = x;
    self.view.frame = frame;
    
    CGRect lastScreenShotViewFrame = lastScreenShotView.frame;
    lastScreenShotViewFrame.origin.x = frame.origin.x - frame.size.width;
    lastScreenShotView.frame = lastScreenShotViewFrame;

    
}

#pragma mark - Gesture Recognizer -

- (void)paningGestureReceive:(UIPanGestureRecognizer *)recoginzer
{
    // If the viewControllers has only one vc or disable the interaction, then return.
    if (self.viewControllers.count <= 1 || !self.canDragBack) return;
    
    // we get the touch position by the window's coordinate
    CGPoint touchPoint = [recoginzer locationInView:KEY_WINDOW];
    
    // begin paning, show the backgroundView(last screenshot),if not exist, create it.
    if (recoginzer.state == UIGestureRecognizerStateBegan) {
        
        _isMoving = YES;
        startTouch = touchPoint;
        
        if (lastScreenShotView)
            [lastScreenShotView removeFromSuperview];
        
        UIImage *lastScreenShot = [[self.screenShotsList lastObject] objectForKey:@"capture"];
        lastScreenShotView = [[[UIImageView alloc]initWithImage:lastScreenShot] autorelease];
     
        [self.view.superview insertSubview:lastScreenShotView atIndex:0];
        
        //End paning, always check that if it should move right or move left automatically
    }else if (recoginzer.state == UIGestureRecognizerStateEnded)
    {
        
        if (touchPoint.x - startTouch.x > 50)
        {
            [UIView animateWithDuration:0.3 animations:^{
                [self moveViewWithX:320];
            } completion:^(BOOL finished) {
                
                [self popViewControllerAnimated:NO];
                CGRect frame = self.view.frame;
                frame.origin.x = 0;
                self.view.frame = frame;
                
                _isMoving = NO;
            }];
        }
        else
        {
            [UIView animateWithDuration:0.3 animations:^{
                [self moveViewWithX:0];
            } completion:^(BOOL finished) {
                _isMoving = NO;
                
            }];
            
        }
        return;
        
        // cancal panning, alway move to left side automatically
    }else if (recoginzer.state == UIGestureRecognizerStateCancelled){
        
        [UIView animateWithDuration:0.3 animations:^{
            [self moveViewWithX:0];
        } completion:^(BOOL finished) {
            _isMoving = NO;
        }];
        
        return;
    }
    
    // it keeps move with touch
    if (_isMoving) {
        [self moveViewWithX:touchPoint.x - startTouch.x];
    }
}

@end
