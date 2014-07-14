//
//  EBDMainViewController.m
//  EasyBezier
//
//  Created by benlai on 14-7-10.
//  Copyright (c) 2014年 com.jing. All rights reserved.
//

#import "EBDMainViewController.h"
#import "EBDBezierView.h"

#define K_MAX_POINT_COUNT 4

@interface EBDMainViewController () <EBDBezierViewProtocol, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UIScrollViewDelegate>
{
    CGRect _leftRect;
    CGRect _rightRect;
    
    BOOL _leftLatch;
    BOOL _rightLatch;
    
    CGRect _leftCloseRect;
    CGRect _rightCloseRect;
    
    BOOL _leftCloseLatch;
    BOOL _rightCloseLatch;
    
    CGPoint _lastLocation;
    
}

@property (weak, nonatomic) IBOutlet EBDBezierView *bezierView;

@property (weak, nonatomic) IBOutlet UIView *leftView;

@property (weak, nonatomic) IBOutlet UIView *rightView;

@property (weak, nonatomic) IBOutlet UILabel *currentPointLabelMain;

@property (nonatomic, strong) UIImagePickerController *imagePicker;

@property (weak, nonatomic) IBOutlet UIScrollView *mScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *mImageView;
@property (weak, nonatomic) IBOutlet UIButton *imageDoneBtn;


@end

@implementation EBDMainViewController

static CGFloat leftMaxWidth = 90.0;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _leftRect = CGRectMake(0.0, 40.0, 50.0, 40.0);
    CGFloat triggeredSize = 10.0;
    _leftCloseRect = CGRectMake(leftMaxWidth - triggeredSize, 0.0, triggeredSize * 2, self.view.bounds.size.width);
    
    [self.bezierView setDelegate:self];
    [self.imageDoneBtn setHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.imagePicker) {
        self.imagePicker = [[UIImagePickerController alloc] init];
        [self.imagePicker setDelegate:self];
    }
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//    NSLog(@"touchesBegan");
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    
    //left view
    _leftLatch = CGRectContainsPoint(_leftRect, location);
    
    //right view
    if (!_leftLatch) {
        _rightLatch = CGRectContainsPoint(_rightRect, location);
    }
    
    //left view close
    _leftCloseLatch = CGRectContainsPoint(_leftCloseRect, location);
    
    //right view close
    if (!_leftCloseLatch) {
        _rightCloseLatch = CGRectContainsPoint(_rightCloseRect, location);
    }
    
    
    if (_rightLatch || _leftLatch) {
        
    } else if (_leftCloseLatch || _rightCloseLatch) {
        
    } else {
        [_bezierView didTouchesBegan:touches withEvent:event];
    }
    
    _lastLocation = location;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
//    NSLog(@"touchesMoved");
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    
    
    
    //left view
    if (_leftLatch || _leftCloseLatch) {
        
        CGFloat deltaX = location.x - _lastLocation.x;
        CGRect lvFrame = _leftView.frame;
        CGFloat moveX = (lvFrame.origin.x + lvFrame.size.width - leftMaxWidth) > 0.0 ? deltaX * (leftMaxWidth / location.x / 2.0) : deltaX;
        
        CGPoint lvCenter = _leftView.center;
        lvCenter.x += moveX;
        [_leftView setCenter:lvCenter];
        
    } else if (_rightLatch) {
        
    } else if (_rightCloseLatch) {
        
    } else {
        
        [_bezierView didTouchesMoved:touches withEvent:event];
    }
    
    _lastLocation = location;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//    NSLog(@"touchesEnded");
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    
    //left view
    if (_leftLatch) {
        CGRect lvFrame = _leftView.frame;
        lvFrame.origin.x = - (lvFrame.size.width - leftMaxWidth);
        
        [UIView animateWithDuration:0.2 animations:^{
            [_leftView setFrame:lvFrame];
        }];
        
        
    } else if (_rightLatch) {
        
    } else if (_leftCloseLatch) {
        CGRect lvFrame = _leftView.frame;
        
        if (lvFrame.origin.x + lvFrame.size.width - leftMaxWidth / 2.0 > 0.0) {
            lvFrame.origin.x = - (lvFrame.size.width - leftMaxWidth);
        } else {
            
            lvFrame.origin.x = - lvFrame.size.width;
        }
        
        [UIView animateWithDuration:0.2 animations:^{
            [_leftView setFrame:lvFrame];
        }];
        
    } else {
        [_bezierView didTouchesEnded:touches withEvent:event];
    }
}

#pragma mark - left action

- (IBAction)beginPointPressed:(UIButton *)sender {
}

- (IBAction)endPointPressed:(UIButton *)sender {
}

- (IBAction)control1PointPressed:(UIButton *)sender {
}

- (IBAction)control2PointPressed:(UIButton *)sender {
}

#pragma mark - camera

- (IBAction)cameraBtnPressed:(id)sender {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Choose image from" delegate:self cancelButtonTitle:@"Album" otherButtonTitles:@"Camera", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        //album
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            [self.imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            [self presentViewController:self.imagePicker animated:YES completion:NULL];
        }
        
    } else if (buttonIndex == 1) {
        //camera
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [self.imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [self.imagePicker setAllowsEditing:YES];
            [self presentViewController:self.imagePicker animated:YES completion:NULL];
        }
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = nil;
    UIImage *editedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    if (editedImage) {
        image = editedImage;
    } else {
        UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        image = originalImage;
    }
    
    CGSize imageSize = image.size;
    CGSize scrollVSize = self.mScrollView.bounds.size;
    [self.mImageView setFrame:CGRectMake(0.0, 0.0, imageSize.width, imageSize.height)];
    [self.mImageView setImage:image];
    
    [self.mScrollView setContentSize:imageSize];
    
    CGFloat min = MIN(scrollVSize.width / imageSize.width, scrollVSize.height / imageSize.height);
    CGFloat max = 1.0;
    
    [self.mScrollView setMinimumZoomScale:min];
    [self.mScrollView setMaximumZoomScale:max];
    
    [self.mScrollView setZoomScale:min];
    
    [self.imageDoneBtn setHidden:NO];
    [self.view bringSubviewToFront:self.mScrollView];
    [self.view bringSubviewToFront:self.imageDoneBtn];
    
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.mImageView;
}

- (IBAction)imageDoneBtnPressed:(id)sender {
    [self.view sendSubviewToBack:self.mScrollView];
    [self.imageDoneBtn setHidden:YES];
    
}

@end
