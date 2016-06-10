//
//  ViewController.h
//  MultiFiles
//
//  Created by Riccardo Rizzo on 12/05/15.
//  Copyright (c) 2015 Riccardo Rizzo. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "StarRatingView.h"
#import "Multifiles-Swift.h"
#import "ShareFileViewController.h"
#import "CloudFile.h"

@import Security;
@import SwiftyJSON;
@import SWTableViewCell;


@interface ViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate,UISearchBarDelegate,UIDocumentInteractionControllerDelegate,UIActionSheetDelegate,UIGestureRecognizerDelegate, UpdateUploadBarDelegate,SWTableViewCellDelegate, UITextFieldDelegate> {

    IBOutlet UITextField *txtUserName;
    IBOutlet UITextField *txtUserPassword;
    
    //---- New registration
    IBOutlet UITextField *txtNewUserName;
    IBOutlet UITextField *txtNewEmail;
    IBOutlet UITextField *txtNewPassword1;
    IBOutlet UITextField *txtNewPassword2;
   // IBOutlet UIWebView *fileWebViewer;
    
    MultifilesHelper *helper;

    
    //---- Program variables
    NSString *USER_ID;
    NSString *UsedSpace;
    dispatch_queue_t queue;
    UIRefreshControl *refreshControl;
    NSString *selectedFile;
    double DownloadFileSize;
    NSData *temp_data;
    UIProgressView *progressBar;
    BOOL loggedIn;
    BOOL viewWasScrolled;
    UILabel *labelProgress;
    
    UIActivityIndicatorView *activityIndicator;
    NSIndexPath *cellSelected;
    
    NSMutableArray *cloudFiles;
    UITextField *activeField;
    
    NSArray *IndexTitles;
    NSArray *fileSectionTitles;
    NSDictionary *filesDictionary;
    
    NSURLConnection *uploadConnection;
    NSURLConnection *downloadConnection;
    BOOL isDownload;
    BOOL stopDownload;
    
    IBOutlet UIView *loginView;
    IBOutlet UIView *registerView;
    IBOutlet UIView *fileView;
    IBOutlet UINavigationBar *navigationBar;
    IBOutlet UIBarButtonItem *openButton;
    IBOutlet UINavigationItem *navTitle;
}

@property (strong, nonatomic) IBOutlet UITableView *fileCollection;

@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) NSMutableArray* images;
@property (nonatomic) float searchBarBoundsY;
@property (nonatomic) BOOL searchBarActive;
@property (nonatomic,strong) NSMutableArray        *dataSourceForSearchResult;
@property (nonatomic,strong) UIDocumentInteractionController *documentInteractionController;
@property (nonatomic)   NSURL *downloadedFile;
@property (nonatomic) NSInteger totalBytes;
@property (nonatomic) NSInteger receivedByte;
@property (nonatomic,strong) UISearchBar  *searchBar;


-(void)refreshUserData;
-(void)handleDocumentOpenURL:(NSURL *)url;
-(void)login;
-(void)rateFile:(NSIndexPath*)index withRating:(NSInteger)rating;

@end

