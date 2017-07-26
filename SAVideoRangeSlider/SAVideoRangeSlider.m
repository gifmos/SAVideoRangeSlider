//
//  SAVideoRangeSlider.m
//
// This code is distributed under the terms and conditions of the MIT license.
//
// Copyright (c) 2013 Andrei Solovjev - http://solovjev.com/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "SAVideoRangeSlider.h"
#import "SASliderLeft.h"
#import "SASliderRight.h"

@interface SAVideoRangeSlider ()

@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *centerView;
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, strong) SASliderLeft *leftThumb;
@property (nonatomic, strong) SASliderRight *rightThumb;
@property (nonatomic) CGFloat frame_width;

@end

@implementation SAVideoRangeSlider
@synthesize leftPosition = _leftPosition, rightPosition =_rightPosition;

#define SLIDER_BORDERS_SIZE 2.0f
#define BG_VIEW_BORDERS_SIZE 3.0f

-(id)initWithFrame:(CGRect)frame asset:(AVAsset *)asset{
    self = [self initWithFrame:frame];
    if (self) {
        [self getMovieFramesFromAsset:asset];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame videoUrl:(NSURL *)videoUrl{
    
    self = [self initWithFrame:frame];
    if (self) {
        _videoUrl = videoUrl;
        [self getMovieFrame];
    }
    
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _frame_width = frame.size.width;
        
        int thumbWidth = ceil(frame.size.width*0.03);
        
        _bgView = [[UIControl alloc] initWithFrame:CGRectMake(thumbWidth-BG_VIEW_BORDERS_SIZE, 0, frame.size.width-(thumbWidth*2)+BG_VIEW_BORDERS_SIZE*2, frame.size.height)];
        _bgView.layer.borderColor = [UIColor clearColor].CGColor;
        _bgView.layer.borderWidth = BG_VIEW_BORDERS_SIZE;
        [self addSubview:_bgView];
        
        _topBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, SLIDER_BORDERS_SIZE)];
        _topBorder.backgroundColor = [UIColor whiteColor];
        [self addSubview:_topBorder];
        
        
        _bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-SLIDER_BORDERS_SIZE, frame.size.width, SLIDER_BORDERS_SIZE)];
        _bottomBorder.backgroundColor = [UIColor whiteColor];
        [self addSubview:_bottomBorder];
        
        
        _leftThumb = [[SASliderLeft alloc] initWithFrame:CGRectMake(0, 0, thumbWidth, frame.size.height)];
        _leftThumb.contentMode = UIViewContentModeLeft;
//        _leftThumb.userInteractionEnabled = YES;
        _leftThumb.clipsToBounds = YES;
        _leftThumb.backgroundColor = [UIColor clearColor];
        _leftThumb.layer.borderWidth = 0;
        [self addSubview:_leftThumb];
        
        
//        UIPanGestureRecognizer *leftPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftPan:)];
//        [_leftThumb addGestureRecognizer:leftPan];
        
        
        _rightThumb = [[SASliderRight alloc] initWithFrame:CGRectMake(0, 0, thumbWidth, frame.size.height)];
        
        _rightThumb.contentMode = UIViewContentModeRight;
//        _rightThumb.userInteractionEnabled = YES;
        _rightThumb.clipsToBounds = YES;
        _rightThumb.backgroundColor = [UIColor clearColor];
        [self addSubview:_rightThumb];
        
//        UIPanGestureRecognizer *rightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightPan:)];
//        [_rightThumb addGestureRecognizer:rightPan];
        
//        [rightPan requireGestureRecognizerToFail:leftPan];
//        [leftPan requireGestureRecognizerToFail:rightPan];

        _rightPosition = frame.size.width;
        _leftPosition = 0;
        
        
        
        
        _centerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _centerView.backgroundColor = [UIColor clearColor];
        [self addSubview:_centerView];
        
//        UIPanGestureRecognizer *centerPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCenterPan:)];
//        [self addGestureRecognizer:centerPan];
//        [centerPan requireGestureRecognizerToFail:leftPan];
//        [centerPan requireGestureRecognizerToFail:rightPan];
    }
    return self;
}

- (UIPanGestureRecognizer*)addGestureToParentView : (UIView*)view
{
    UIPanGestureRecognizer *centerPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCenterPan:)];
    [view addGestureRecognizer:centerPan];
    
    return centerPan;
}

-(void)setMaxGap:(CGFloat)maxGap{
    _leftPosition = 0;
    _rightPosition = _frame_width*maxGap/_durationSeconds;
    _maxGap = maxGap;
}

-(void)setMinGap:(CGFloat)minGap{
    _leftPosition = 0;
    _rightPosition = _frame_width*minGap/_durationSeconds;
    _minGap = minGap;
}


-(void)setRangeHidden:(BOOL)rangeHidden{
    _centerView.hidden = rangeHidden;
    _leftThumb.hidden = rangeHidden;
    _rightThumb.hidden = rangeHidden;
    _topBorder.hidden = rangeHidden;
    _bottomBorder.hidden = rangeHidden;
}


#pragma mark - Gestures

- (void)handleLeftPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gesture translationInView:self];
        
        _leftPosition += translation.x;
        if (_leftPosition < 0) {
            _leftPosition = 0;
        }
        
        if (
            (_rightPosition-_leftPosition <= _leftThumb.frame.size.width+_rightThumb.frame.size.width) ||
            ((self.minGap > 0) && (self.rightPosition-self.leftPosition < self.minGap))
            ){
            _leftPosition -= translation.x;
        }
        
        if ((self.maxGap > 0) && (self.rightPosition-self.leftPosition > self.maxGap)) {
            _rightPosition += translation.x;
        }
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self setNeedsLayout];
        
        if ([_delegate respondsToSelector:@selector(videoRange:didChangeLeftPosition:)]){
            [_delegate videoRange:self didChangeLeftPosition:self.leftPosition];
        }
        
    }
}


- (void)handleRightPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        
        
        CGPoint translation = [gesture translationInView:self];
        _rightPosition += translation.x;
        if (_rightPosition < 0) {
            _rightPosition = 0;
        }
        
        if (_rightPosition > _frame_width){
            _rightPosition = _frame_width;
        }
        
        if (_rightPosition-_leftPosition <= 0){
            _rightPosition -= translation.x;
        }
        
        if ((_rightPosition-_leftPosition <= _leftThumb.frame.size.width+_rightThumb.frame.size.width) ||
            ((self.minGap > 0) && (self.rightPosition-self.leftPosition < self.minGap))){
            _rightPosition -= translation.x;
        }

        if ((self.maxGap > 0) && (self.rightPosition-self.leftPosition > self.maxGap)) {
            _leftPosition += translation.x;
        }
        
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self setNeedsLayout];
        
        if ([_delegate respondsToSelector:@selector(videoRange:didChangeRightPosition:)]){
            [_delegate videoRange:self didChangeRightPosition:self.rightPosition];
        }
        
    }
}


- (void)handleCenterPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint position = [gesture locationInView:self];
//        NSLog(@"%f %f", fabs(_centerView.center.x - position.x), _centerView.bounds.size.width / 2.0);
//        BOOL inCenter = fabs(_centerView.center.x - position.x) < _centerView.bounds.size.width / 3.0;//MIN(20, _centerView.bounds.size.width / 1.5);
//        if (!inCenter) {
//            if (position.x < _centerView.center.x) {
//                //            NSLog(@"a");
//                [self handleLeftPan:gesture];
//                return;
//            }
//            if (position.x > _centerView.center.x) {
//                //            NSLog(@"b");
//                [self handleRightPan:gesture];
//                return;
//            }
//        }
//        NSLog(@"c");
        
        if (position.x < _centerView.center.x) {//if (position.x < _leftPosition) {
            [self handleLeftPan:gesture];
            return;
        }
        if (position.x > _centerView.center.x) {//if (position.x > _rightPosition) {
            [self handleRightPan:gesture];
            return;
        }
//        CGPoint translation = [gesture translationInView:self];
//        
//        _leftPosition += translation.x;
//        _rightPosition += translation.x;
//        
//        if (_rightPosition > _frame_width || _leftPosition < 0){
//            _leftPosition -= translation.x;
//            _rightPosition -= translation.x;
//        }
//        
//        
//        [gesture setTranslation:CGPointZero inView:self];
//        
//        [self setNeedsLayout];
//        
//        if ([_delegate respondsToSelector:@selector(videoRange:didChangeLeftPosition:rightPosition:)]){
//            [_delegate videoRange:self didChangeLeftPosition:self.leftPosition rightPosition:self.rightPosition];
//        }
    }
}


- (void)layoutSubviews
{
    CGFloat inset = _leftThumb.frame.size.width / 2;
    
    _leftThumb.center = CGPointMake(_leftPosition+inset, _leftThumb.frame.size.height/2);
    
    _rightThumb.center = CGPointMake(_rightPosition-inset, _rightThumb.frame.size.height/2);
    
    _topBorder.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, 0, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width/2, SLIDER_BORDERS_SIZE);
    
    _bottomBorder.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, _bgView.frame.size.height-SLIDER_BORDERS_SIZE, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width/2, SLIDER_BORDERS_SIZE);
    
    
    _centerView.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, _centerView.frame.origin.y, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width, _centerView.frame.size.height);
}




#pragma mark - Video

-(void)getMovieFramesFromAsset:(AVAsset*)asset{
    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    
    self.imageGenerator.maximumSize = CGSizeMake(_bgView.frame.size.width*[UIScreen mainScreen].scale, _bgView.frame.size.height*[UIScreen mainScreen].scale);
    self.imageGenerator.appliesPreferredTrackTransform = YES;
    
    int picWidth = 20;
    
    // First image
    NSError *error;
    CMTime actualTime;
    CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:&actualTime error:&error];
    if (halfWayImage != NULL) {
        UIImage *videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
        CGRect rect=tmp.frame;
        rect.size.width=picWidth;
        tmp.frame=rect;
        [_bgView addSubview:tmp];
        picWidth = tmp.frame.size.width;
        CGImageRelease(halfWayImage);
    }
    
    
    _durationSeconds = CMTimeGetSeconds([asset duration]);
    
    int picsCnt = ceil(_bgView.frame.size.width / picWidth);
    
    NSMutableArray *allTimes = [[NSMutableArray alloc] init];
    
    int time4Pic = 0;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
        // Bug iOS7 - generateCGImagesAsynchronouslyForTimes
        int prefreWidth=0;
        for (int i=1, ii=1; i<picsCnt; i++){
            time4Pic = i*picWidth;
            
            CMTime timeFrame = CMTimeMakeWithSeconds(_durationSeconds*time4Pic/_bgView.frame.size.width, 600);
            
            [allTimes addObject:[NSValue valueWithCMTime:timeFrame]];
            
            
            CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:timeFrame actualTime:&actualTime error:&error];
            
            UIImage *videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
            
            
            UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
            
            
            
            CGRect currentFrame = tmp.frame;
            currentFrame.origin.x = ii*picWidth;
            
            currentFrame.size.width=picWidth;
            prefreWidth+=currentFrame.size.width;
            
            if( i == picsCnt-1){
                currentFrame.size.width-=6;
            }
            tmp.frame = currentFrame;
            int all = (ii+1)*tmp.frame.size.width;
            
            if (all > _bgView.frame.size.width){
                int delta = all - _bgView.frame.size.width;
                currentFrame.size.width -= delta;
            }
            
            ii++;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_bgView addSubview:tmp];
            });
            
            
            
            
            CGImageRelease(halfWayImage);
            
        }
        
        
        return;
    }
    
    for (int i=1; i<picsCnt; i++){
        time4Pic = i*picWidth;
        
        CMTime timeFrame = CMTimeMakeWithSeconds(_durationSeconds*time4Pic/_bgView.frame.size.width, 600);
        
        [allTimes addObject:[NSValue valueWithCMTime:timeFrame]];
    }
    
    NSArray *times = allTimes;
    
    __block int i = 1;
    
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times
                                              completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime,
                                                                  AVAssetImageGeneratorResult result, NSError *error) {
                                                  
                                                  if (result == AVAssetImageGeneratorSucceeded) {
                                                      
                                                      
                                                      UIImage *videoScreen = [[UIImage alloc] initWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
                                                      
                                                      UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
                                                      tmp.contentMode = UIViewContentModeCenter;
                                                      
                                                      int all = (i+1)*tmp.frame.size.width;
                                                      
                                                      
                                                      CGRect currentFrame = tmp.frame;
                                                      currentFrame.origin.x = i*currentFrame.size.width;
                                                      if (all > _bgView.frame.size.width){
                                                          int delta = all - _bgView.frame.size.width;
                                                          currentFrame.size.width -= delta;
                                                      }
                                                      tmp.frame = currentFrame;
                                                      i++;
                                                      
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [_bgView addSubview:tmp];
                                                      });
                                                      
                                                  }
                                                  
                                                  if (result == AVAssetImageGeneratorFailed) {
                                                      NSLog(@"Failed with error: %@", [error localizedDescription]);
                                                  }
                                                  if (result == AVAssetImageGeneratorCancelled) {
                                                      NSLog(@"Canceled");
                                                  }
                                              }];
}

-(void)getMovieFrame{
    AVAsset *myAsset = [[AVURLAsset alloc] initWithURL:_videoUrl options:nil];
    [self getMovieFramesFromAsset:myAsset];
}




#pragma mark - Properties

- (CGFloat)leftPosition
{
    return _leftPosition * _durationSeconds / _frame_width;
}


- (CGFloat)rightPosition
{
    return _rightPosition * _durationSeconds / _frame_width;
}

- (void)setLeftPosition:(CGFloat)leftPosition{
    _leftPosition = leftPosition * _frame_width / _durationSeconds;
    [self layoutSubviews];
}

-(void)setRightPosition:(CGFloat)rightPosition{
    _rightPosition = rightPosition * _frame_width / _durationSeconds;
    [self layoutSubviews];
}

@end
