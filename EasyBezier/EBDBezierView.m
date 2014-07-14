//
//  EBDBezierView.m
//  EasyBezier
//
//  Created by benlai on 14-7-10.
//  Copyright (c) 2014年 com.jing. All rights reserved.
//

#import "EBDBezierView.h"

typedef struct EBDBezierPoint {
    CGPoint p;
    CGFloat s;
    CGFloat d;
    NSInteger latch;
    NSInteger exist;
}EBDBezierPoint;

@interface EBDBezierView ()
{
    CGMutablePathRef _axisPath;
    CGMutablePathRef _gridPath;
    CGMutablePathRef _bezierPath;
    
    EBDBezierPoint _bp;//beginPoint
    EBDBezierPoint _ep;//endPoint
    EBDBezierPoint _c1p;//control1
    EBDBezierPoint _c2p;//control2
    
    UIColor *_bc;
    UIColor *_ec;
    UIColor *_c1c;
    UIColor *_c2c;
    
    BOOL _bl;
    BOOL _el;
    BOOL _c1l;
    BOOL _c2l;
    
    BOOL _onlyTouchBegan;//for add bezier point
    
    CGRect _trashbinRect;
}

@property (nonatomic, strong) UIPinchGestureRecognizer *pinch;

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
    
    //origin
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    CGFloat mw = ceilf(w / 2.0);
    CGFloat mh = ceilf(h / 2.0);
    
    _origin = CGPointMake(mw, mh);
    CGFloat trashSize = 50.0;
    _trashbinRect = CGRectMake(w - trashSize, h - trashSize, trashSize, trashSize);
    
    [self configureBackgroundPath];
    [self configureGestures];
    
}

#pragma mark - bezier points

- (void)setBezierPointSize:(CGFloat)pointSize withType:(EBDBezierPointType)type
{
    if (!((int)pointSize)) {
        return;
    }
    
    switch (type) {
        case EBDBezierPointBegin:
        {
            _bp.s = pointSize;
        }
            break;
        case EBDBezierPointEnd:
        {
            _ep.s = pointSize;
        }
            break;
        case EBDBezierPointControl1:
        {
            _c1p.s = pointSize;
        }
            break;
        case EBDBezierPointControl2:
        {
            _c2p.s = pointSize;
        }
            break;
    }
}

- (void)addBezierPointAtLocation:(CGPoint)location withType:(EBDBezierPointType)type
{
    switch (type) {
        case EBDBezierPointBegin:
        {
            _bp.s = 8.0;
            _bp.p = location;
            _bp.exist = 1;
            _bc = [UIColor redColor];
        }
            break;
        case EBDBezierPointEnd:
        {
            _ep.s = 6.0;
            _ep.p = location;
            _ep.exist = 1;
            _ec = [UIColor redColor];
        }
            break;
        case EBDBezierPointControl1:
        {
            _c1p.s = 4.0;
            _c1p.p = location;
            _c1p.exist = 1;
            _c1c = [UIColor orangeColor];
        }
            break;
        case EBDBezierPointControl2:
        {
            _c2p.s = 3.0;
            _c2p.p = location;
            _c2p.exist = 1;
            _c2c = [UIColor greenColor];
        }
            break;
    }
    
    [self configureBezierPath];
}

static CGFloat MIN_DISTANCE = 10.0;

- (void)didTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    
    //as tap
    _onlyTouchBegan = YES;
    
    //for moving bezier points
    _bp.d = distanceBetweenTwoPoints(location.x, location.y, _bp.p.x, _bp.p.y);
    _ep.d = distanceBetweenTwoPoints(location.x, location.y, _ep.p.x, _ep.p.y);
    _c1p.d = distanceBetweenTwoPoints(location.x, location.y, _c1p.p.x, _c1p.p.y);
    _c2p.d = distanceBetweenTwoPoints(location.x, location.y, _c2p.p.x, _c2p.p.y);
    
    EBDBezierPoint *minP = &_bp;
    
    if ((*minP).d > _ep.d) {
        minP = &_ep;
    }
    
    if ((*minP).d > _c1p.d) {
        minP = &_c1p;
    }
    
    if ((*minP).d > _c2p.d) {
        minP = &_c2p;
    }
    
    if ((*minP).d < MIN_DISTANCE) {
        (*minP).latch = 1;
    }
}

- (void)didTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //as tap
    _onlyTouchBegan = NO;
    
    //for moving bezier points
    EBDBezierPoint *latchP = NULL;
    
    if (_bp.latch) latchP = &_bp;
    if (_ep.latch) latchP = &_ep;
    if (_c1p.latch) latchP = &_c1p;
    if (_c2p.latch) latchP = &_c2p;
    
    if (latchP) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:self];
        (*latchP).p = location;
        [self configureBezierPath];
    }
    
}

- (void)didTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    
    //as tap
    if (_onlyTouchBegan) {
        _onlyTouchBegan = NO;
        
        if (!_bp.exist) {
            [self addBezierPointAtLocation:location withType:EBDBezierPointBegin];
            return;
        }
        
        if (!_ep.exist) {
            [self addBezierPointAtLocation:location withType:EBDBezierPointEnd];
            return;
        }
        
        if (!_c1p.exist) {
            [self addBezierPointAtLocation:location withType:EBDBezierPointControl1];
            return;
        }
        
        if (!_c2p.exist) {
            [self addBezierPointAtLocation:location withType:EBDBezierPointControl2];
            return;
        }
    }
    
    //trash
    EBDBezierPoint *latchP = NULL;
    
    if (_bp.latch) latchP = &_bp;
    if (_ep.latch) latchP = &_ep;
    if (_c1p.latch) latchP = &_c1p;
    if (_c2p.latch) latchP = &_c2p;
    
    if (latchP) {
        if (CGRectContainsPoint(_trashbinRect, (*latchP).p)) {
            (*latchP).exist = 0;
            [self configureBezierPath];
        }
    }
    
    //clear state
    _bp.latch = 0;
    _ep.latch = 0;
    _c1p.latch = 0;
    _c2p.latch = 0;
    
    _bp.d = 0.0;
    _ep.d = 0.0;
    _c1p.d = 0.0;
    _c2p.d = 0.0;
}

#pragma mark - utilities

CGFloat distanceBetweenTwoPoints(CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2)
{
    CGFloat d1 = x1 - x2;
    CGFloat d2 = y1 - y2;
    return sqrtf(d1 * d1 + d2 * d2);
}

#pragma mark - path

- (void)configureBezierPath
{
    if (_bezierPath) {
        CGPathRelease(_bezierPath);
        _bezierPath = NULL;
    }
    
    
    
    if (_bp.exist && _ep.exist) {
        
        _bezierPath = CGPathCreateMutable();
        
        if (_c1p.exist && _c2p.exist) {
            
            //cubic bezier
            CGPathMoveToPoint(_bezierPath, NULL, _bp.p.x, _bp.p.y);
            CGPathAddCurveToPoint(_bezierPath, NULL, _c1p.p.x, _c1p.p.y, _c2p.p.x, _c2p.p.y, _ep.p.x, _ep.p.y);
            
        } else if (_c1p.exist) {
            
            //quadratic bezier
            CGPathMoveToPoint(_bezierPath, NULL, _bp.p.x, _bp.p.y);
            CGPathAddQuadCurveToPoint(_bezierPath, NULL, _c1p.p.x, _c1p.p.y, _ep.p.x, _ep.p.y);
        } else if (_c2p.exist) {
            
            //quadratic bezier
            CGPathMoveToPoint(_bezierPath, NULL, _bp.p.x, _bp.p.y);
            CGPathAddQuadCurveToPoint(_bezierPath, NULL, _c2p.p.x, _c2p.p.y, _ep.p.x, _ep.p.y);
            
        } else {
            CGPathMoveToPoint(_bezierPath, NULL, _bp.p.x, _bp.p.y);
            CGPathAddLineToPoint(_bezierPath, NULL, _ep.p.x, _ep.p.y);
        }
    }
    
    [self setNeedsDisplay];
}

- (void)configureGestures
{
    self.pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self addGestureRecognizer:self.pinch];
}



- (void)configureBackgroundPath
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

#pragma mark - zoom

- (void)pinch:(UIPinchGestureRecognizer *)gesture
{
    NSLog(@"pinch");
}

#pragma mark - draw

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //axis
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextAddPath(context, _axisPath);
    CGContextStrokePath(context);
    
    //grid
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextAddPath(context, _gridPath);
    CGContextStrokePath(context);
    
    //bezier path
    if (_bezierPath) {
        CGContextRestoreGState(context);
        CGContextSaveGState(context);
        CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
        CGFloat lengths[] = {6, 5};
        CGContextSetLineDash(context, 0, lengths, 2);
        CGContextSetLineWidth(context, 2.0);
        CGContextAddPath(context, _bezierPath);
        CGContextStrokePath(context);
    }
    
    //bezier points
    if (_bp.exist) {
        CGContextRestoreGState(context);
        CGContextSaveGState(context);
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, _bp.p.x, _bp.p.y);
        CGContextAddArc(context, _bp.p.x, _bp.p.y, _bp.s, 0.0, M_PI * 2, 0);
        CGContextSetFillColorWithColor(context, _bc.CGColor);
        CGContextFillPath(context);
    }
    
    if (_ep.exist) {
        CGContextRestoreGState(context);
        CGContextSaveGState(context);
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, _ep.p.x, _ep.p.y);
        CGContextAddArc(context, _ep.p.x, _ep.p.y, _ep.s, 0.0, M_PI * 2, 0);
        CGContextSetFillColorWithColor(context, _ec.CGColor);
        CGContextFillPath(context);
    }
    
    if (_c1p.exist) {
        CGContextRestoreGState(context);
        CGContextSaveGState(context);
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, _c1p.p.x, _c1p.p.y);
        CGContextAddArc(context, _c1p.p.x, _c1p.p.y, _c1p.s, 0.0, M_PI * 2, 0);
        CGContextSetFillColorWithColor(context, _c1c.CGColor);
        CGContextFillPath(context);
    }
    
    if (_c2p.exist) {
        CGContextRestoreGState(context);
        CGContextSaveGState(context);
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, _c2p.p.x, _c2p.p.y);
        CGContextAddArc(context, _c2p.p.x, _c2p.p.y, _c2p.s, 0.0, M_PI * 2, 0);
        CGContextSetFillColorWithColor(context, _c2c.CGColor);
        CGContextFillPath(context);
    }
    
}

@end
