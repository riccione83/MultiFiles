//
//  ViewController.m
//  MultiFiles
//
//  Created by Riccardo Rizzo on 12/05/15.
//  Copyright (c) 2015 Riccardo Rizzo. All rights reserved.
//

#import "ViewController.h"

@import Security;
@import SwiftyJSON;

@interface ViewController ()

@end

static NSString * const websiteName = @"https://multifiles.heroku.com/API";
static NSString * const awsWebBaseName = @"https://s3-us-west-2.amazonaws.com/multifiles/";


@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@implementation ViewController

@synthesize images;
@synthesize fileCollection;
@synthesize loginButton;

-(void)setup {
   loginView.hidden = NO;
   fileView.hidden = YES;
    fileCollection.alwaysBounceVertical=YES;
    if(self.searchBar) {
       [self.searchBar removeFromSuperview];
       self.searchBar = nil;
    }
}

-(void) loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
  //None only for delegate completition
}

- (IBAction)alreadyRegister:(id)sender {
    [self setup];
}


#pragma mark DocumentController Functions
- (UIViewController *) documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *) controller {
    return self;
}

-(void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
 //   [self clearTmpDirectory];
}

- (void)previewDocument:(NSURL*)URL {
    [self deleteUploadBar:false];
    
    if (URL) {
        // Initialize Document Interaction Controller
        self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:URL];
        
        // Configure Document Interaction Controller
        [self.documentInteractionController setDelegate:self];
        
        self.downloadedFile = URL;
        
        // Preview PDF
        [self.documentInteractionController presentPreviewAnimated:YES];
    }
}

- (void)handleDocumentOpenURL:(NSURL *)url {
    NSLog(@"Starting to upload: %@",url);
    if(USER_ID != nil && ![USER_ID  isEqual: @""])
        [self uploadFile:url];
}

#pragma mark End DocumentController

-(void)addSearchBar{
    
    if (!self.searchBar) {
        self.searchBarBoundsY = navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height - 5;
        self.searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0,self.searchBarBoundsY, [UIScreen mainScreen].bounds.size.width, 44)];
        self.searchBar.searchBarStyle       = UISearchBarStyleMinimal;
        self.searchBar.tintColor            = [UIColor lightGrayColor];
        self.searchBar.barTintColor         = [UIColor whiteColor];
        self.searchBar.delegate             = self;
        self.searchBar.placeholder          = @"Search here";
        
        [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor lightGrayColor]];
    }
    
    if (![self.searchBar isDescendantOfView:self.view]) {
        [self.view addSubview:self.searchBar];
    }
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)  interfaceOrientation duration:(NSTimeInterval)duration
{
        switch (interfaceOrientation) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationPortraitUpsideDown:
                navigationBar.frame = CGRectMake(navigationBar.frame.origin.x, 20, navigationBar.frame.size.width, navigationBar.frame.size.height);
                fileView.frame = CGRectMake(fileView.frame.origin.x, 0, fileView.frame.size.width, fileView.frame.size.height);
                self.searchBarBoundsY = navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height - 5;
                self.searchBar.frame = CGRectMake(0,self.searchBarBoundsY, [UIScreen mainScreen].bounds.size.width, 44);

                break;
                
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
                navigationBar.frame = CGRectMake(navigationBar.frame.origin.x, 0, navigationBar.frame.size.width, navigationBar.frame.size.height);
                fileView.frame = CGRectMake(fileView.frame.origin.x, -20, fileView.frame.size.width, fileView.frame.size.height);
                self.searchBarBoundsY = navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height - 5;
                self.searchBar.frame = CGRectMake(0,self.searchBarBoundsY, [UIScreen mainScreen].bounds.size.width, 44);

                break;
                
            default:
                break;
    }
}


/***************************
 * Facebook callback function
 * this return the status of Facebook login
 * Type: Facebook SDK
 *****************************/
-(void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    NSLog(@"%@",result);
    if ([FBSDKAccessToken currentAccessToken]) {
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil]
    
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             if (!error)
             {
                 NSLog(@"fetched user:%@", result);
                 //NSDictionary *fbJsonData = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingMutableLeaves error:&error];
                // NSDictionary *fbJsonData = [NSDictionary dictionaryWithDictionary:result];
                /*//Only for debug
                 NSArray *jsonArray = (NSArray *) result;
                 NSLog(@"%@",jsonArray);
                 NSLog(@"Name: %@", [fbJsonData valueForKey:@"first_name"]);
                 NSLog(@"Surname: %@", [fbJsonData valueForKey:@"last_name"]);
                 NSLog(@"ID: %@", [fbJsonData valueForKey:@"id"]);
                 NSLog(@"Email: %@", [fbJsonData valueForKey:@"email"]);*/
                 
                 [FBSDKAccessToken setCurrentAccessToken:nil];
                 [FBSDKProfile setCurrentProfile:nil];
                 
               /*  if(![self userLogin:[fbJsonData valueForKey:@"email"] withPassword:[fbJsonData valueForKey:@"id"]])
                 {
                     [self registerNewUser:[fbJsonData valueForKey:@"email"] withPassword:[fbJsonData valueForKey:@"id"] withPasswordRepeat:[fbJsonData valueForKey:@"id"] withEMail:[fbJsonData valueForKey:@"email"]];
                     [self userLogin:[fbJsonData valueForKey:@"email"] withPassword:[fbJsonData valueForKey:@"id"]];
                     
                 }
                */
             }
         }];
    }
}

/***************************
 * SaveUserLoginData
 * save the Facebook's login data for automatic login
 * Type: Login
 *****************************/
-(void) saveUserLoginData:(NSString*)userName withPassword:(NSString*)userPassword {
    //NSUserDefaults *defaults = [NSUserDefaults ];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.riccardorizzo.multifiles"];
    
    //suiteName: "group.yourappgroup.example")
    
    [defaults setObject:userName forKey:@"user_name"];  //With Facebook use email as login
    [defaults setObject:userPassword  forKey:@"password"];   //and ID as password
    [defaults synchronize];
}

/***************************
 * openWithExternalBtnClick
 * this open a popup menu for view, rename or delete
 * selected file
 * Type: Files
 *****************************/
- (IBAction)openWithExternalBtnClick:(id)sender {
    
    [self showFilePopupMenu];
}

/***************************
 * login
 * this check if there are some login data saved
 * and perform a login if is true
 * Type: Login
 *****************************/
-(void)login {
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.riccardorizzo.multifiles"];
    
    NSString *UserName = [defaults stringForKey:@"user_name"];
    NSString *password = [defaults stringForKey:@"password"];
    
    if(UserName != nil)
        [self userLogin:UserName withPassword:password];
}

/*****************************
 * login
 * this check if there are some login data saved
 * and perform a login if is true
 * Type: UI
 *****************************/
-(void)showFilePopupMenu {
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Select Option for file:" delegate:(id)self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:  @"View",
                            @"Rename",
                            @"Delete",
                            @"Rate",
                            nil];
    popup.tag = 1;
    [popup showFromBarButtonItem:openButton animated:YES];
}


/***************************
 * askForNewFileName
 * Show a popup message for input new File Name
 * Type: UI
 *****************************/
-(void)askForNewFileName:(NSString*)oldFile {
    NSString *fileName =[[oldFile lastPathComponent] stringByDeletingPathExtension];
    
    fileName = [fileName stringByReplacingOccurrencesOfString:@"%20" withString: @" "];
    
    NSString *message = [NSString stringWithFormat:@"Enter a new name for %@",fileName];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rename file" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alert textFieldAtIndex:0];
    textField.text = fileName;
    //textField.placeholder="";
    alert.tag = 102;
    [alert show];
}

/***************************
 * actionSheet
 * Callback when user click the popup menu
 * select the choice and perform the operation
 * Type: UI
 *****************************/
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (popup.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0:
                    [self downloadFileForCurrentUser:selectedFile];
                    break;
                case 1:
                    [self askForNewFileName:selectedFile];
                   //[self renameFile:selectedFile renameTo:@"Test"];
                    break;
                case 2:
                    [self askForDeleteFile];
                    break;
                case 3:
                    [self showRatingView];
                    break;
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

/***************************
 * askForDeleteFile
 * If there is a cell selected ask the user for delete the file
 * Type: UI
 *****************************/
-(void)askForDeleteFile {
    if(cellSelected) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete file" message:@"Are you sure to delete this file?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
        alert.tag = 1;
        [alert show];
    }
}

/***************************
 * alertView:clickedButtonAtIndex
 * If user click the confirmation alert (Tag=1)
 * Type: UI
 *****************************/
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag==1) {
        if(buttonIndex==1) {
            NSString *file = [files objectAtIndex:cellSelected.row];
            
            file = [NSString stringWithFormat:@"%@/%@",USER_ID,file ];
            
            [self deleteFile:file];
        }
        [self refreshUserData];
    }
    else if(alertView.tag==102) //Ask for rename file
    {
        if (buttonIndex == 1) {
            NSString *newFileName = [[alertView textFieldAtIndex:0] text];
            [self renameFile:selectedFile renameTo:newFileName];
        }
    }
}

/***************************
 * handleLongPress
 * Callback for Long Press on file view container
 * Select a file and show the popup message
 * Type: UI
 *****************************/
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    CGPoint p = [gestureRecognizer locationInView:fileCollection];
    NSIndexPath *indexPath = [fileCollection indexPathForRowAtPoint:p];
    if (indexPath == nil){
        NSLog(@"couldn't find index path");
    } else {
        if(cellSelected) {
            UITableViewCell *datasetCellDeselect =[fileCollection cellForRowAtIndexPath:cellSelected];
            datasetCellDeselect.layer.cornerRadius = 0;
            datasetCellDeselect.layer.shadowOpacity = 0.0;
            datasetCellDeselect.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
            datasetCellDeselect.backgroundColor = [UIColor clearColor]; // Default color
        }
        UITableViewCell *datasetCell =[fileCollection cellForRowAtIndexPath:indexPath];
        datasetCell.backgroundColor = [UIColor lightGrayColor]; // highlight selection
        datasetCell.layer.cornerRadius = 10;
        datasetCell.layer.shadowOpacity = 0.8;
        
        datasetCell.layer.shadowOffset = CGSizeMake(0.5f, 0.5f);
       
        cellSelected = indexPath;
        selectedFile = [self getSelectedFile:indexPath];
        [self showFilePopupMenu];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    if(!loggedIn)
        [self login];
}


-(void)profileUpdated:(NSNotification *) notification{
    NSLog(@"User name: %@",[FBSDKProfile currentProfile].name);
    NSLog(@"User ID: %@",[FBSDKProfile currentProfile].userID);
}

- (void)viewDidLoad {
        [super viewDidLoad];
    
        if([FBSDKAccessToken currentAccessToken]) {  //User is already logged in
            NSLog(@"Already login");
        }

        fbloginButton.readPermissions = @[@"public_profile", @"email"];
        fbloginButton.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileUpdated:) name:FBSDKProfileDidChangeNotification object:nil];
    
        [self setup];
    
        refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshUserData) forControlEvents:UIControlEventValueChanged];
        [self.fileCollection addSubview:refreshControl];
    
        UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        lpgr.minimumPressDuration = .5; //seconds
        lpgr.delegate = self;
        [fileCollection addGestureRecognizer:lpgr];
  }


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)fileXBtnClick:(id)sender {
    if(!fileView.hidden) {
         files = [NSMutableArray new];
         file_acreateat = [NSMutableArray new];
         file_size = [NSMutableArray new];
         file_path = [NSMutableArray new];
         //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
         NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.riccardorizzo.multifiles"];
         [defaults setObject:nil forKey:@"user_name"];  //With Facebook use email as login
         [defaults setObject:nil forKey:@"password"];   //and ID as password
         [defaults synchronize];
         loggedIn = NO;
         [self setup];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"%lu",(unsigned long)files.count);
    
    [refreshControl endRefreshing];
    if(!self.searchBarActive)
        return files.count;
    
    return self.dataSourceForSearchResult.count;
}

-(void)rateFile:(NSIndexPath*)index withRating:(NSInteger)rating {
    
    NSString *fileID = [FileID objectAtIndex:index.row];
    
    [FileRating replaceObjectAtIndex:index.row withObject:[NSNumber numberWithInt:(int)rating]];
    
    [self setRateForFile:fileID withRateOf:[NSString stringWithFormat:@"%ld",(long)rating]];
    UITableViewCell *cell = [fileCollection cellForRowAtIndexPath:index];
    
    
    for(int i=0;i<5;i++)
    {
        UIImageView *imgRate = (UIImageView *)[cell viewWithTag:200+(i+1)];
        imgRate.image = [UIImage imageNamed:@"not_selected_star.png"];
    }
    
    for(int i=0;i<rating;i++)
    {
        UIImageView *imgRate = (UIImageView *)[cell viewWithTag:200+(i+1)];
        imgRate.image =[UIImage imageNamed:@"selected_star"];
        CGAffineTransform currentTransform = imgRate.transform;
        CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, 0, 0);
        [imgRate setTransform:newTransform];
        
        // Animate to new scale of 100% with bounce
        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.6
              initialSpringVelocity:15
                            options:0
                         animations:^{
                             imgRate.transform = CGAffineTransformMakeScale(1, 1);
                         }
                         completion:nil];
    }
    
}

-(void)showRatingView {
    StarRatingView *ratingView = [[StarRatingView alloc] initWithFrame:CGRectMake(10, 10, 300, 100)];
    ratingView.center = self.view.center;
    ratingView.currIndex = cellSelected;
    [ratingView setInitalRating:[[FileRating objectAtIndex:cellSelected.row] integerValue]];
    ratingView.delegate = (id)self;
    [self.view addSubview:ratingView];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:100];
    UILabel *recipeLabel = (UILabel*)[cell viewWithTag:101];
    UILabel *recipeLabelSIze = (UILabel*)[cell viewWithTag:102];
    UILabel *recipeFileName = (UILabel*)[cell viewWithTag:103];
    
    if (!self.searchBarActive) {
        NSString* theFileName = [[files objectAtIndex:indexPath.row] lastPathComponent];
        recipeFileName.text = theFileName;
        recipeLabel.text = [NSString stringWithFormat:@"Uploaded on: %@",[file_acreateat objectAtIndex:indexPath.row]];
        recipeLabelSIze.text = [file_size objectAtIndex:indexPath.row];
    }
    else
    {
        NSString* theFileName = [[self.dataSourceForSearchResult objectAtIndex:indexPath.row] lastPathComponent];
        recipeFileName.text = theFileName;
        
        recipeLabel.text =[NSString stringWithFormat:@"Uploaded on: %@",[file_acreateat objectAtIndex:[self searchSizeFromArray:files search:theFileName]]];
        recipeLabelSIze.text = [file_size objectAtIndex:[self searchSizeFromArray:files search:theFileName]];
    }
    
    NSString *extension = [recipeFileName.text pathExtension];
    if([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"JPG"] ||
       [extension isEqualToString:@"png"]  || [extension isEqualToString:@"PNG"] ||
       [extension isEqualToString:@"tiff"] || [extension isEqualToString:@"TIFF"] ||
       [extension isEqualToString:@"bmp"]  || [extension isEqualToString:@"BMP"])
    {
        recipeImageView.image = [UIImage imageNamed:@"images.png"];
    }
    else if([extension isEqualToString:@"doc"] || [extension isEqualToString:@"DOC"] ||
            [extension isEqualToString:@"docx"]  || [extension isEqualToString:@"DOCX"] ||
            [extension isEqualToString:@"pdf"] || [extension isEqualToString:@"PDF"] ||
            [extension isEqualToString:@"txt"]  || [extension isEqualToString:@"TXT"] ||
            [extension isEqualToString:@"xls"]  || [extension isEqualToString:@"XLS"] ||
            [extension isEqualToString:@"xslx"]  || [extension isEqualToString:@"XSLX"])
    {
        recipeImageView.image = [UIImage imageNamed:@"files.png"];
    }
    else
        recipeImageView.image = [UIImage imageNamed:@"cloud.png"];
    
    UIImageView *rate1 = (UIImageView *)[cell viewWithTag:201];  //first star
    UIImageView *rate2 = (UIImageView *)[cell viewWithTag:202];  //second
    UIImageView *rate3 = (UIImageView *)[cell viewWithTag:203];  //thirth
    UIImageView *rate4 = (UIImageView *)[cell viewWithTag:204];  //fourth
    UIImageView *rate5 = (UIImageView *)[cell viewWithTag:205];  //Fifth
    
    rate1.image = [UIImage imageNamed:@"not_selected_star.png"];
    rate2.image = [UIImage imageNamed:@"not_selected_star.png"];
    rate3.image = [UIImage imageNamed:@"not_selected_star.png"];
    rate4.image = [UIImage imageNamed:@"not_selected_star.png"];
    rate5.image = [UIImage imageNamed:@"not_selected_star.png"];
    
    for(int i=0;i<[[FileRating objectAtIndex:indexPath.row] integerValue];i++)
    {
        UIImageView *imgRate = (UIImageView *)[cell viewWithTag:200+(i+1)];
        imgRate.image =[UIImage imageNamed:@"selected_star"];
        CGAffineTransform currentTransform = imgRate.transform;
        CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, 0, 0);
        [imgRate setTransform:newTransform];
        
        // Animate to new scale of 100% with bounce
        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.6
              initialSpringVelocity:15
                            options:0
                         animations:^{
                             imgRate.transform = CGAffineTransformMakeScale(1, 1);
                         }
                         completion:nil];
    }
    
    cell.layer.cornerRadius = 0;
    cell.layer.shadowOpacity = 0.0;
    cell.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    cell.backgroundColor = [UIColor clearColor]; // Default color
    
    recipeImageView.layer.cornerRadius = 10;
    recipeImageView.layer.shadowOpacity = 0.8;
    recipeImageView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    
    return cell;
}

-(NSString*) getSelectedFile:(NSIndexPath*) indexPath {
    NSString *url_ = @"";
    
    if(!self.searchBarActive)
        url_ = [files objectAtIndex:indexPath.row];
    else
        url_ = [self.dataSourceForSearchResult objectAtIndex:indexPath.row];
    
    NSString *fileUrl = [NSString stringWithFormat:@"%@%@/%@",awsWebBaseName,USER_ID,url_];
    
    url_ = [fileUrl
            stringByReplacingOccurrencesOfString: @" "
            withString: @"%20"];
    NSLog(@"%@",url_);
    return url_;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(cellSelected) {
        //UITableViewCell *datasetCellDeselect =[fileCollection cellForItemAtIndexPath:cellSelected];
        UITableViewCell *datasetCellDeselect = [fileCollection cellForRowAtIndexPath:cellSelected];
        datasetCellDeselect.layer.cornerRadius = 0;
        datasetCellDeselect.layer.shadowOpacity = 0.0;
        datasetCellDeselect.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        datasetCellDeselect.backgroundColor = [UIColor clearColor]; // Default color
    }
    
    UITableViewCell *datasetCell = [fileCollection cellForRowAtIndexPath:indexPath];
  //  datasetCell.backgroundColor = [UIColor blueColor]; // highlight selection
    datasetCell.layer.cornerRadius = 10;
    datasetCell.layer.shadowOpacity = 0.8;
    datasetCell.layer.shadowOffset = CGSizeMake(0.5f, 0.5f);
  
    cellSelected = indexPath;
    selectedFile = [self getSelectedFile:indexPath];
}

-(void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    //UICollectionViewCell *datasetCell =[collectionView cellForItemAtIndexPath:indexPath];
    UITableViewCell *datasetCell = [fileCollection cellForRowAtIndexPath:indexPath];
    datasetCell.backgroundColor = [UIColor clearColor]; // Default color
    datasetCell.layer.cornerRadius = 0;
    datasetCell.layer.shadowOpacity = 0.0;
    datasetCell.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
}

/*-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    

}*/

- (IBAction)closeFileView:(id)sender {
  //  if(!fileWebViewer.hidden) fileWebViewer.hidden = YES;
   // else if(!fileCollection.hidden) fileCollection.hidden = YES;
   // loginButton.enabled = YES;
}


-(NSInteger)searchSizeFromArray:(NSMutableArray*)array search:(NSString*)text_to_search {
    for(int i=0;i<array.count;i++)
    {
        if([[[array objectAtIndex:i] lastPathComponent] isEqualToString:text_to_search])
            return i;
    }
    return 0;
}

-(void)setRateForFile:(NSString*)fileID withRateOf:(NSString*)rate {
    MultifilesHelper *helper = [[MultifilesHelper alloc] init];
    helper.delegate = self;
    
    if(USER_ID != nil) {
    
    [helper setRateForFile:fileID rating:rate completition:^(BOOL success) {
        /*if(success) {
            
        }*/
    }];
    }
}

-(void)deleteFile:(NSString*)filePath {

    MultifilesHelper *helper = [[MultifilesHelper alloc] init];
    helper.delegate = self;
    [helper deleteFile:filePath completition:^(BOOL success) {
        if(success)
           [self refreshUserData];
    }];
}

-(void)refreshUserData {
    
    MultifilesHelper *helper = [[MultifilesHelper alloc] init];
    helper.delegate = self;
    
        if(USER_ID != nil && !self.searchBarActive)
        {
            images = [NSMutableArray new];
            files = [NSMutableArray new];
            file_acreateat = [NSMutableArray new];
            file_size = [NSMutableArray new];
            FileID = [NSMutableArray new];
            FileRating = [NSMutableArray new];
            
            [helper getFileListForUser:^(BOOL success, id _Nullable jsonDataRcv) {
                
                if(success) {
        
                for (NSDictionary *dict in jsonDataRcv) {
                    [files addObject:[dict valueForKey:@"CurrFileName"]];
                    [file_acreateat addObject:[dict valueForKey:@"CreatedAt"]];
                    [file_size addObject:[dict valueForKey:@"FileSize"]];
                    [FileRating addObject:[dict valueForKey:@"Rating"]];
                    [FileID addObject:[dict valueForKey:@"FileID"]];
                }
                
                if(files) {
                    fileCollection.hidden = NO;
                    [refreshControl endRefreshing];
                    [fileCollection reloadData];
                }
                }
                
            }];
        }
}


- (IBAction)getFileForUser:(id)sender {
    [self refreshUserData];
}


- (UIImage *)GetImageFromURL:(NSURL*) URL
{
    UIImage *image = nil;
    if (URL) {
        NSData *imageData = [NSData dataWithContentsOfURL:URL];
        image = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
    }
    
    return image;
}

-(void)clearTmpDirectory
{
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }
}

-(void) downloadFileForCurrentUser:(NSString *)fileName {
    
        NSString *documentsDirectory =NSTemporaryDirectory(); //[paths objectAtIndex:0];
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[fileName lastPathComponent]];
    
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:dataPath];
    
    
        if(fileExists) {
            [self previewDocument:[NSURL fileURLWithPath:dataPath]];
        }
        else
        {
            NSString *url_ = fileName;
            NSRange rOriginal = [url_ rangeOfString: @"."];
            if (NSNotFound != rOriginal.location)
            {
                  url_ = [url_
                    stringByReplacingOccurrencesOfString: @" "
                    withString: @"%20"];
                
                NSLog(@"Downloading Started: %@",url_);
                self.totalBytes = 0;
                self.receivedByte = 0;
                isDownload = YES;
                [self createUploadBar];
                NSURL *url = [NSURL URLWithString:url_];
                NSURLRequest *request = [NSURLRequest requestWithURL:url];
                downloadConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
                if(downloadConnection ) {
                    NSOperationQueue *queueL = [[NSOperationQueue alloc] init];
                
                    [NSURLConnection sendAsynchronousRequest:request queue:queueL completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
                     {

                         NSData *urlData = [NSData  dataWithData:data];
                         [urlData writeToFile:dataPath atomically:YES];
                         [self previewDocument:[NSURL fileURLWithPath:dataPath]];
                     }];
                }
            }
        }
    
}



/******************
 PHP Server want:
 user_name
 user_email
 user_password_new
 user_password_repeat
 JSON = 1 => For mobile request
 ******************/

-(void) registerNewUser:(NSString*)userName withPassword:(NSString*)password1 withPasswordRepeat:(NSString*)passwordRepeat withEMail:(NSString*)userEmail {
    
    MultifilesHelper *helper = [[MultifilesHelper alloc] init];
    helper.delegate = self;
    
    [helper registerNewUser:userName userPassword:password1 userPasswordRepeat:passwordRepeat userEmail:userEmail completition:^(NSString * _Nonnull message, BOOL success) {
        
        if(success) {
            [self alertStatus:message :@"Multifiles" :0];
        }
        else {
            [self alertStatus:message :@"Warning" :0];
        }
        
    }];
    
    
/*    @try {
        
        if([userName isEqualToString:@""] || [password1 isEqualToString:@""] || userName==nil || password1==nil ) {
            
            [self alertStatus:@"Please enter Email and Password" :@"Sign in Failed!" :0];
            return NO;
            
        } else {
            NSString *post =[[NSString alloc] initWithFormat:@"user_name=%@&user_password_new=%@&user_password_repeat=%@&user_email=%@&JSON=1",userName,password1,passwordRepeat,userEmail];
            NSLog(@"PostData: %@",post);
            
            NSString *web_base = [NSString stringWithFormat:@"%@%@%@",websiteName,@"/register.php?",post];
            
            NSURL *url=[NSURL URLWithString:web_base];
            
            NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
            
            NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:postData];
            
            //[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
            
            NSError *error = [[NSError alloc] init];
            NSHTTPURLResponse *response = nil;
            
            [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
            NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            NSLog(@"Response code: %ld", (long)[response statusCode]);
            
            if ([response statusCode] >= 200 && [response statusCode] < 300)
            {
                NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
                NSLog(@"Response ==> %@", responseData);
                
                NSError *error = nil;
                NSDictionary *jsonData = [NSJSONSerialization
                                          JSONObjectWithData:urlData
                                          options:NSJSONReadingMutableContainers
                                          error:&error];
                
                NSString *success_msg = (NSString *) jsonData[@"message"];
                NSLog(@"Success: %@",success_msg);
                //[self alertStatus:error_msg :@"Sign in Failed!" :0];
                
                if(success_msg != nil)
                {
                    NSLog(@"Login SUCCESS");
                    [self alertStatus:success_msg :@"User created" :0];
                    return YES;
                    
                } else {
                    NSString *error_msg = (NSString *) jsonData[@"error"];
                    [self alertStatus:error_msg :@"Sign in Failed!" :0];
                    return NO;
                }
                
            } else {
                //if (error) NSLog(@"Error: %@", error);
                [self alertStatus:@"Connection Failed" :@"Sign in Failed!" :0];
                return NO;
            }
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        [self alertStatus:@"Sign in Failed." :@"Error!" :0];
        return NO;
    }
    */
}

- (IBAction)register_new_user:(id)sender {
    
    [self registerNewUser:txtNewUserName.text withPassword:txtNewPassword1.text withPasswordRepeat:txtNewPassword2.text withEMail:txtNewEmail.text];

}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    NSDictionary *dict = httpResponse.allHeaderFields;
    NSString *lengthString = [dict valueForKey:@"Content-Length"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSNumber *length = [formatter numberFromString:lengthString];
    self.totalBytes = length.unsignedIntegerValue;
    
  //  self.imageData = [[NSMutableData alloc] initWithCapacity:self.totalBytes];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    self.receivedByte += data.length;
    NSLog(@"%ld/%ld bytes written",(long)self.receivedByte,(long)self.totalBytes);
    
    double val =( (double)self.receivedByte/(double)self.totalBytes );
    progressBar.progress = val;
    NSLog(@"%f percento",(progressBar.progress*100));
    labelProgress.text = [NSString stringWithFormat:@"Downloading %.2f%% ...",(progressBar.progress*100)];
    if(self.totalBytes == self.receivedByte)
        [self deleteUploadBar:false];
    
    // Actual progress is self.receivedBytes / self.totalBytes
}

/*-(void) connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    NSLog(@"%ld/%ld bytes written",(long)totalBytesWritten,(long)totalBytesExpectedToWrite);
    
    double val =( (double)totalBytesWritten/(double)totalBytesExpectedToWrite );
    progressBar.progress = val;
    NSLog(@"%f percento",(progressBar.progress*100));
    labelProgress.text = [NSString stringWithFormat:@"Uploading %.2f%% ...",(progressBar.progress*100)];
    if(totalBytesExpectedToWrite == totalBytesWritten)
        [self deleteUploadBar:true];
}*/

-(void) updateProgressBar:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
  
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"%ld/%ld bytes written",(long)totalBytesWritten,(long)totalBytesExpectedToWrite);
        double val =( (double)totalBytesWritten/(double)totalBytesExpectedToWrite );
        progressBar.progress = val;
        NSLog(@"%f percento",(progressBar.progress*100));
        labelProgress.text = [NSString stringWithFormat:@"Uploading %.2f%% ...",(progressBar.progress*100)];
        if(totalBytesExpectedToWrite == totalBytesWritten)
            [self deleteUploadBar:true];
    });
}


-(void)deleteUploadBar:(BOOL)refreshData
{
    [[self.view viewWithTag:12] removeFromSuperview];
    [[self.view viewWithTag:11] removeFromSuperview];
    [[self.view viewWithTag:10] removeFromSuperview];
    if(refreshData)
        [self refreshUserData];
}

-(void)createUploadBar
{
    UIView *baseView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height)];
    [baseView setBackgroundColor:[UIColor blackColor]];
    [baseView setAlpha:0.5];
    baseView.tag = 11;
    
    UIView *progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height)];
    [progressView setAlpha:1];
    progressView.tag = 10;
    progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(20, (progressView.frame.size.height/2)-50,progressView.frame.size.width-40,10)];
    labelProgress = [[UILabel alloc] initWithFrame:CGRectMake(0, (progressView.frame.size.height/2)-30, progressView.frame.size.width,40)];
    [progressView addSubview:progressBar];
    [progressBar setProgress:0.0];
    [labelProgress setBackgroundColor:[UIColor greenColor]];
    labelProgress.text=@"Wait...";
    NSLog(@"%f",progressView.frame.size.width);
    [labelProgress setTextAlignment:NSTextAlignmentCenter];
    [progressView addSubview:labelProgress];

    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, (progressView.frame.size.height/2)+30, progressView.frame.size.width,40)];
    
     if(!isDownload)
         [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    else
         [cancelButton setTitle:@"Hide" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.tag = 12;
    
    [self.view addSubview:baseView];
    [self.view addSubview:progressView];
    [self.view addSubview:cancelButton];
}

-(void)cancelPressed {
    NSLog(@"Operation Cancelled!");
    if(!isDownload)
        [uploadConnection cancel];
    else {
        stopDownload = YES;
    }
    [self deleteUploadBar:true];
}

-(UIView *)getMainView {
    return self.view;
}

-(void) uploadFile:(NSURL *)filePath {
    
    MultifilesHelper *helper = [[MultifilesHelper alloc] init];
    helper.delegate = self;
    [helper upload: filePath];
}

-(void) renameFile:(NSString*)oldFile renameTo:(NSString*)newFile {
    
    MultifilesHelper *helper = [[MultifilesHelper alloc] init];
    helper.delegate = self;
    [helper renameFile:oldFile newFileName:newFile completition:^(BOOL success) {
        
        if(success) {
            NSLog(@"Rename success");
            [self refreshUserData];
        }
    }];
}

-(void) userLogin:(NSString*)userName withPassword:(NSString*)userPassword {
    
    MultifilesHelper *helper = [[MultifilesHelper alloc] init];
    helper.delegate = self;
    [helper showLoadingHUD];
        
    if([userName isEqualToString:@""] || [userPassword isEqualToString:@""] ) {
            [self alertStatus:@"Please enter Email and Password" :@"Sign in Failed!" :0];
            
    } else {
            
        MultifilesHelper *helper = [[MultifilesHelper alloc] init];
        helper.delegate = self;
        
        [helper login:userName password:userPassword completition:^(NSString * UserID, BOOL success) {
            if(success) {
                    NSLog(@"Login SUCCESS. USER ID: %ld",(long)success);
                    USER_ID = [NSString stringWithFormat:@"%@",UserID];
                    fileView.hidden = NO;
                    loginView.hidden = YES;
                    loggedIn = YES;
                    [self clearTmpDirectory];
                    [self addSearchBar];
                    [self saveUserLoginData:userName withPassword:userPassword];
                    [self refreshUserData];
                    [self getUsedSpace:USER_ID];
            }
            else {
                [self alertStatus:UserID :@"Sign in Failed!" :0];
            }
        }];

        }
    }

-(void) getUsedSpace:(NSString*)userID {
    MultifilesHelper *helper = [[MultifilesHelper alloc] init];
    helper.delegate = self;
    [helper getUserSpace:USER_ID completition:^(NSString * _Nonnull spaceUsed, BOOL success) {
        
        if(success) {
            UsedSpace = [NSString stringWithFormat:@"%@",spaceUsed];
            [navTitle setTitle:[NSString stringWithFormat:@"MultiView - Used:%@",UsedSpace]];
        }
        
    }];
}

- (IBAction)login:(id)sender {
    
    [self userLogin:txtUserName.text withPassword:txtUserPassword.text];
    
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

#pragma mark Connection Delegate

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        //        if ([trustedHosts containsObject:challenge.protectionSpace.host])
        
        OSStatus                err;
        NSURLProtectionSpace *  protectionSpace;
        SecTrustRef             trust;
        SecTrustResultType      trustResult;
        BOOL                    trusted;
        
        protectionSpace = [challenge protectionSpace];
        assert(protectionSpace != nil);
        
        trust = [protectionSpace serverTrust];
        assert(trust != NULL);
        err = SecTrustEvaluate(trust, &trustResult);
        trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified));
        
        // If that fails, apply our certificates as anchors and see if that helps.
        //
        // It's perfectly acceptable to apply all of our certificates to the SecTrust
        // object, and let the SecTrust object sort out the mess.  Of course, this assumes
        // that the user trusts all certificates equally in all situations, which is implicit
        // in our user interface; you could provide a more sophisticated user interface
        // to allow the user to trust certain certificates for certain sites and so on).
        
        if ( ! trusted ) {
          //  err = SecTrustSetAnchorCertificates(trust, (CFArrayRef) [Credentials sharedCredentials].certificates);
          //  if (err == noErr) {
          //      err = SecTrustEvaluate(trust, &trustResult);
           // }
            trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified));
        }
        if(trusted)
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

#pragma mark - search
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope{
    NSPredicate *resultPredicate    = [NSPredicate predicateWithFormat:@"self contains[c] %@", searchText];
    self.dataSourceForSearchResult  =[NSMutableArray arrayWithArray:[files filteredArrayUsingPredicate:resultPredicate]];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    // user did type something, check our datasource for text that looks the same
    if (searchText.length>0) {
        // search and reload data source
        self.searchBarActive = YES;
        [self filterContentForSearchText:searchText
                                   scope:[[searchBar scopeButtonTitles]
                                          objectAtIndex:[searchBar
                                          selectedScopeButtonIndex]]];
        [fileCollection reloadData];
    }else{
        // if text lenght == 0
        // we will consider the searchbar is not active
        self.searchBarActive = NO;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self cancelSearching];
    [fileCollection reloadData];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    self.searchBarActive = YES;
    [self.view endEditing:YES];
}
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    // we used here to set self.searchBarActive = YES
    // but we'll not do that any more... it made problems
    // it's better to set self.searchBarActive = YES when user typed something
    [searchBar setShowsCancelButton:YES animated:YES];
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    // this method is being called when search btn in the keyboard tapped
    // we set searchBarActive = NO
    // but no need to reloadCollectionView
    self.searchBarActive = NO;
    [self.searchBar setShowsCancelButton:NO animated:YES];
}
-(void)cancelSearching{
    self.searchBarActive = NO;
    [self.searchBar resignFirstResponder];
    self.searchBar.text  = @"";
}

@end
