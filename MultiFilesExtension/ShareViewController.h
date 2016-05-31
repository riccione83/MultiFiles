//
//  ShareViewController.h
//  MultiFilesExtension
//
//  Created by Riccardo Rizzo on 01/06/15.
//  Copyright (c) 2015 Riccardo Rizzo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import "MultifilesExtension-Swift.h"

@interface ShareViewController : UIViewController <NSURLConnectionDelegate, NSURLConnectionDataDelegate, UpdateUploadBarDelegate> {

    NSString* USER_ID;
    UIProgressView *progressBar;
    BOOL UploadInProgress;
    UILabel *labelProgress;
    NSURL *fileLoaded;
    NSMutableArray *itemsToDownload;
    NSURLConnection *uploadConnection;
    
    MultifilesHelper *helper;
}

@end
