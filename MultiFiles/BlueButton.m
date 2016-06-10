//
//  BlueButton.m
//  MultiFiles
//
//  Created by Riccardo Rizzo on 10/06/16.
//  Copyright © 2016 Riccardo Rizzo. All rights reserved.
//

#import "BlueButton.h"

@implementation BlueButton


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* kButtonStrokeColor = [UIColor colorWithRed: 0.643 green: 0.86 blue: 0.943 alpha: 1];
    CGFloat kButtonStrokeColorRGBA[4];
    [kButtonStrokeColor getRed: &kButtonStrokeColorRGBA[0] green: &kButtonStrokeColorRGBA[1] blue: &kButtonStrokeColorRGBA[2] alpha: &kButtonStrokeColorRGBA[3]];
    
    UIColor* kButtonBkColor = [UIColor colorWithRed: (kButtonStrokeColorRGBA[0] * 0.3 + 0.7) green: (kButtonStrokeColorRGBA[1] * 0.3 + 0.7) blue: (kButtonStrokeColorRGBA[2] * 0.3 + 0.7) alpha: (kButtonStrokeColorRGBA[3] * 0.3 + 0.7)];
    UIColor* shadowColor = [UIColor colorWithRed: 0.796 green: 0.796 blue: 0.796 alpha: 1];
    
    //// Shadow Declarations
    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowColor: [shadowColor colorWithAlphaComponent: CGColorGetAlpha(shadowColor.CGColor) * 0.76]];
    [shadow setShadowOffset: CGSizeMake(3.1, 3.1)];
    [shadow setShadowBlurRadius: 5];
    
    //// Frames
    CGRect frame = rect;
    
    
    //// Group
    {
        //// Rectangle Drawing
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame) + 0.73, CGRectGetMinY(frame) + 0.71, CGRectGetWidth(frame) - 1.47, floor((CGRectGetHeight(frame) - 0.71) * 0.94606 + 0.45) + 0.05) cornerRadius: 10];
        [kButtonBkColor setFill];
        [rectanglePath fill];
        
        ////// Rectangle Inner Shadow
        CGContextSaveGState(context);
        UIRectClip(rectanglePath.bounds);
        CGContextSetShadowWithColor(context, CGSizeZero, 0, NULL);
        
        CGContextSetAlpha(context, CGColorGetAlpha([shadow.shadowColor CGColor]));
        CGContextBeginTransparencyLayer(context, NULL);
        {
            UIColor* opaqueShadow = [shadow.shadowColor colorWithAlphaComponent: 1];
            CGContextSetShadowWithColor(context, shadow.shadowOffset, shadow.shadowBlurRadius, [opaqueShadow CGColor]);
            CGContextSetBlendMode(context, kCGBlendModeSourceOut);
            CGContextBeginTransparencyLayer(context, NULL);
            
            [opaqueShadow setFill];
            [rectanglePath fill];
            
            CGContextEndTransparencyLayer(context);
        }
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
        
        [kButtonStrokeColor setStroke];
        rectanglePath.lineWidth = 6;
        [rectanglePath stroke];
    }

}


@end
