//
//  StarRatingView.h
//  MultiFiles
//
//  Created by Riccardo Rizzo on 16/06/15.
//  Copyright (c) 2015 Riccardo Rizzo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MyDataDelegate

-(void)rateFile:(NSInteger)index withRating:(NSInteger)rating;

@end

@interface StarRatingView : UIView {
    int CurrentRating;
    NSMutableArray *starRating;
}

@property (nonatomic) id<MyDataDelegate> delegate;
@property (nonatomic) NSInteger currIndex;


-(void)setInitalRating:(NSInteger)rating;

@end
