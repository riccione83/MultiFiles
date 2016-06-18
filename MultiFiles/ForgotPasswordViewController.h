//
//  ForgotPasswordViewController.h
//  MultiFiles
//
//  Created by Riccardo Rizzo on 13/06/16.
//  Copyright © 2016 Riccardo Rizzo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Multifiles-Swift.h"

@interface ForgotPasswordViewController : UIViewController {

    IBOutlet UITextField *txtEmailOrUserName;
    IBOutlet UITextField *txtNewPassword;
    IBOutlet UITextField *txtNewPasswordConfirmation;
    IBOutlet UITextField *txtSecretNumber;
    
    

    @public
        id<UpdateUploadBarDelegate> mainView;
    
    @protected
        MultifilesHelper *helper;

}

@end
