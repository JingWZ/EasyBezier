//
//  EBDBezierView.h
//  EasyBezier
//
//  Created by benlai on 14-7-10.
//  Copyright (c) 2014年 com.jing. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EBDBezierPointType) {
    EBDBezierPointBegin,
    EBDBezierPointEnd,
    EBDBezierPointControl1,
    EBDBezierPointControl2,
};

@protocol EBDBezierViewProtocol;

@interface EBDBezierView : UIView

@property (nonatomic, weak) id<EBDBezierViewProtocol> delegate;

@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGFloat axisScale;
@property (nonatomic, assign) NSInteger axisMarkInterval;

- (void)setBezierPointSize:(CGFloat)pointSize withType:(EBDBezierPointType)type;
- (void)addBezierPointAtLocation:(CGPoint)location withType:(EBDBezierPointType)type;

- (void)didTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)didTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)didTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;

@end



@protocol EBDBezierViewProtocol <NSObject>



@end