//
//  ShareViewController.m
//  MultiFiles
//
//  Created by Riccardo Rizzo on 07/06/16.
//  Copyright © 2016 Riccardo Rizzo. All rights reserved.
//

#import "ShareFileViewController.h"
@import MBProgressHUD;

@interface ShareFileViewController ()

@end

@implementation ShareFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


-(void)viewDidAppear:(BOOL)animated {
    if(fileIDToShare == nil) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (IBAction)cancelBtnClick:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) alertStatus:(NSString *)msg :(NSString *)title :(int) tag :(BOOL) success
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


- (IBAction)shareBtnClick:(id)sender {
    if(fileIDToShare == nil || [txtEmail.text isEqualToString:@""]) {
        [self dismissViewControllerAnimated:true completion:nil];
    }
    else {
        helper = [[MultifilesHelper alloc] init];
        
        [helper shareFile:fileIDToShare toEmail:txtEmail.text completition:^(BOOL success) {
            if(success) {
                [self alertStatus:@"Link sent successfully." :@"Multifiles" :0 :success];
            }
            else {
                [self alertStatus:@"Unknow error on sharing the file" :@"Multifiles" :0 :success];
            }
        }];
    }
    
    
    [self dismissViewControllerAnimated:true completion:nil];
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
