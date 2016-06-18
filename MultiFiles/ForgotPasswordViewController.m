//
//  ForgotPasswordViewController.m
//  MultiFiles
//
//  Created by Riccardo Rizzo on 13/06/16.
//  Copyright © 2016 Riccardo Rizzo. All rights reserved.
//

#import "ForgotPasswordViewController.h"
@import MBProgressHUD;

@interface ForgotPasswordViewController ()

@end

@implementation ForgotPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    helper = [[MultifilesHelper alloc] init];
    helper.delegate = mainView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)requestSecret:(id)sender {
    
    if(![txtEmailOrUserName.text isEqualToString:@""])
    {
        [helper requestSecretCode:txtEmailOrUserName.text completition:^(BOOL success) {
            if(success) {
                [self alertStatus:@"A new secret code was sent on your email. Please check and insert it below with your new password" :@"New secret" :0];
            }
        }];
    }
    

}


- (IBAction)setNewPasswordBtnClick:(id)sender {
    
    if(![txtNewPassword.text isEqualToString:txtNewPasswordConfirmation.text])
    {
        [self alertStatus:@"Password and Password Confirmation doesn't match. Plese check." :@"Password recovery" :0];
    }
    else if ([txtEmailOrUserName.text isEqualToString:@""] ||
             [txtNewPassword.text isEqualToString:@""] ||
             [txtNewPasswordConfirmation.text isEqualToString:@""] ||
             [txtSecretNumber.text isEqualToString:@""])
    {
        [self alertStatus:@"Please fill all the requested field, including the user name." :@"Password recovery" :0];
    }
    else
    {
        [helper setNewPasswordWithCode:txtEmailOrUserName.text secret:txtSecretNumber.text newPassword:txtNewPassword.text completition:^(BOOL success) {
            if(success) {
                [self dismissViewControllerAnimated:YES completion:^{
                    [self alertMessage:@"Password changed successfully." :@"Password Recovery" :YES];
                }];
            }
            else
            {
                [self alertStatus:@"Error. Bad Secret Code." :@"Password Recovery" :0];
            }
        }];
    }
    
    
}

- (IBAction)cancelBtnClick:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void) alertStatus:(NSString *)msg :(NSString *)title :(int) tag
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:msg
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
    alertView.tag = tag;
    [alertView show];
}



- (void) alertMessage:(NSString *)msg :(NSString *)title :(BOOL) success
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:mainView.getMainView animated:YES];
    
    // Set the custom view mode to show any view.
    hud.mode = MBProgressHUDModeCustomView;
    // Set an image view with a checkmark.
    if(success) {
        UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        hud.customView = [[UIImageView alloc] initWithImage:image];
    }
    // Looks a bit nicer if we make it square.
    hud.square = YES;
    
    // Optional label text.
    hud.labelText = NSLocalizedString(msg, title);
    
    [hud hide:YES afterDelay:3.f];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
