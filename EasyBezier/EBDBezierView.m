//
//  EBDBezierView.m
//  EasyBezier
//
//  Created by benlai on 14-7-10.
//  Copyright (c) 2014年 com.jing. All rights reserved.
//

#import "EBDBezierView.h"

@interface EBDBezierView ()
{
    CGMutablePathRef _axisPath;
    CGMutablePathRef _gridPath;
}

@end

@implementation EBDBezierView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _axisScale = 1.0;
    _axisMarkInterval = 20.0;
    
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    CGFloat mw = ceilf(w / 2.0);
    CGFloat mh = ceilf(h / 2.0);
    _origin = CGPointMake(mw, mh);
    
    [self configurePath];
    
}

- (void)configurePath
{
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    CGFloat mw = ceilf(w / 2.0);
    CGFloat mh = ceilf(h / 2.0);
    CGFloat x = ceilf(w * _axisScale);
    CGFloat y = ceilf(h * _axisScale);
    CGFloat hx = ceilf(mw * _axisScale);
    CGFloat hy = ceilf(mh * _axisScale);
    CGFloat offset = 0.0;
    CGFloat tOff = offset;
    CGFloat bOff = offset;
    CGFloat lOff = offset;
    CGFloat rOff = offset;
    
    //axis
    if (_axisPath) {
        CGPathRelease(_axisPath);
        _axisPath = NULL;
    }
    
    _axisPath = CGPathCreateMutable();
    CGPathMoveToPoint(_axisPath, NULL, 0.0, _origin.y);
    CGPathAddLineToPoint(_axisPath, NULL, w, _origin.y);
    CGPathMoveToPoint(_axisPath, NULL, _origin.x, 0.0);
    CGPathAddLineToPoint(_axisPath, NULL, _origin.x, h);
    
    CGFloat al = 10.0;
    CGPathMoveToPoint(_axisPath, NULL, w - al, _origin.y - al / 2.0);
    CGPathAddLineToPoint(_axisPath, NULL, w, _origin.y);
    CGPathAddLineToPoint(_axisPath, NULL, w - al, _origin.y + al / 2.0);
    
    CGPathMoveToPoint(_axisPath, NULL, _origin.x - al / 2.0, 0.0 + al);
    CGPathAddLineToPoint(_axisPath, NULL, _origin.x, 0.0);
    CGPathAddLineToPoint(_axisPath, NULL, _origin.x + al / 2.0, 0.0 + al);
    
    
    //grid
    if (_gridPath) {
        CGPathRelease(_gridPath);
        _gridPath = NULL;
    }

    _gridPath = CGPathCreateMutable();

    BOOL done = NO;
    CGFloat sx = _origin.x;
    CGFloat inc = _axisMarkInterval;
    CGFloat agr = sx + inc;
    
    
    while (!done) {
        //x+ & x-
        CGPathMoveToPoint(_gridPath, NULL, agr, tOff);
        CGPathAddLineToPoint(_gridPath, NULL, agr, h - bOff);
        
        agr += inc;
        
        if (agr > x - rOff) {
            inc = -_axisMarkInterval;
            agr = sx + inc;
        } else if (agr < lOff) {
            done = YES;
        }
    }
    
    done = NO;
    CGFloat sy = _origin.y;
    inc = _axisMarkInterval;
    agr = sy + inc;
    
    while (!done) {
        //y+ & y-
        CGPathMoveToPoint(_gridPath, NULL, lOff, agr);
        CGPathAddLineToPoint(_gridPath, NULL, w - rOff, agr);
        
        agr += inc;
        
        if (agr > y - bOff) {
            inc = -_axisMarkInterval;
            agr = sy + inc;
        } else if (agr < tOff) {
            done = YES;
        }
    }
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //axis
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextAddPath(context, _axisPath);
    CGContextStrokePath(context);
    
    //grid
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextAddPath(context, _gridPath);
    CGContextStrokePath(context);
}

@end
