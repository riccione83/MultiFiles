//
//  ShareViewController.h
//  MultiFiles
//
//  Created by Riccardo Rizzo on 07/06/16.
//  Copyright © 2016 Riccardo Rizzo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Multifiles-Swift.h"
#import "ViewController.h"

@interface ShareFileViewController : UIViewController {
    
    @public
        NSString *fileIDToShare;
        NSString *fileNameToShare;
        id<UpdateUploadBarDelegate> mainView;
    
    @protected
        IBOutlet UITextField *txtEmail;
        MultifilesHelper *helper;
}

@end
