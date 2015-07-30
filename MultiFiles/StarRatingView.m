//
//  StarRatingView.m
//  MultiFiles
//
//  Created by Riccardo Rizzo on 16/06/15.
//  Copyright (c) 2015 Riccardo Rizzo. All rights reserved.
//

#import "StarRatingView.h"

@implementation StarRatingView
@synthesize currIndex;

-(void)rateButtonClick {
    [self.delegate rateFile:currIndex withRating:CurrentRating];
    [self removeFromSuperview];
}

-(void)setInitalRating:(NSInteger)rating {
    CurrentRating = (int)rating;
    [self refreshStars:YES];
}

- (void)refreshStars:(BOOL)inMovement {
    for(int i = 0; i < starRating.count; ++i) {
        UIImageView *imageView = [starRating objectAtIndex:i];
        if (CurrentRating >= i+1) {
            imageView.image = [UIImage imageNamed:@"selected_star.png"];
            
            if(!inMovement) {
            CGAffineTransform currentTransform = imageView.transform;
            CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, 0, 0);
            [imageView setTransform:newTransform];
            
            // Animate to new scale of 100% with bounce
            [UIView animateWithDuration:0.3
                                  delay:0
                 usingSpringWithDamping:0.6
                  initialSpringVelocity:15
                                options:0
                             animations:^{
                                 imageView.transform = CGAffineTransformMakeScale(1, 1);
                             }
                             completion:nil];
            }
            
            
        } else if (CurrentRating > i) {
            imageView.image = [UIImage imageNamed:@"half_selected_star.png"];
        } else {
            imageView.image = [UIImage imageNamed:@"not_selected_star.png"];;
        }
    }
}

- (void)handleTouchAtLocation:(CGPoint)touchLocation options:(BOOL)isInMovement {
    for(int i = 4; i >= 0; i--) {
        UIImageView *imageView = [starRating objectAtIndex:i];
        if (touchLocation.x > imageView.frame.origin.x) {
            CurrentRating = i+1;
            NSLog(@"%d",CurrentRating);
            break;
        }
        else if(i==0) {
            if (touchLocation.x <= imageView.frame.origin.x) {
                CurrentRating = 0;
                NSLog(@"%d",CurrentRating);
            }
        }
    }
    [self refreshStars: isInMovement];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    [self handleTouchAtLocation:touchLocation options:YES];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    [self handleTouchAtLocation:touchLocation options:YES];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    [self handleTouchAtLocation:touchLocation options:NO];
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if(self) {
        [self setBackgroundColor:[UIColor blueColor]];
        [self setUserInteractionEnabled:YES];
        self.layer.cornerRadius = 10;
        self.layer.shadowOpacity = 0.8;
        self.layer.shadowOffset = CGSizeMake(0.5f, 0.5f);
        CurrentRating = 0;
        starRating = [NSMutableArray new];
        UIButton *rateButton = [[UIButton alloc] init];
        [rateButton addTarget:self action:@selector(rateButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [rateButton setTitle:@"Rate" forState:UIControlStateNormal];
        for(int i = 0; i < 5; ++i) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selected_star.png"]];
            CGRect imageFrame = CGRectMake(20 + i*(5+imageView.frame.size.width), imageView.frame.size.height/2, imageView.frame.size.width, imageView.frame.size.height);
            imageView.frame = imageFrame;
            imageView.tag = i+300;
            [starRating addObject:imageView];
            [self addSubview:imageView];
            if(i==2)
            {
                rateButton.frame  =CGRectMake(0, imageView.frame.size.height*1.5, self.frame.size.width, 40);
                [rateButton.titleLabel setTextAlignment: NSTextAlignmentCenter];
                [self addSubview:rateButton];
            }
        }
        [self refreshStars:YES];
    }
    return self;
}

-(id)init {
    self = [super initWithFrame:CGRectMake(10, 10, 270, 70)];

    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
