//
//  ViewController.m
//  MultiFiles
//
//  Created by Riccardo Rizzo on 12/05/15.
//  Copyright (c) 2015 Riccardo Rizzo. All rights reserved.
//

#import "ViewController.h"



@interface ViewController ()

@end

@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@implementation ViewController

@synthesize images;
@synthesize fileCollection;
@synthesize loginButton;

static NSString * const websiteName = @"https://multifiles.heroku.com/API";
static NSString * const awsWebBaseName = @"https://s3-us-west-2.amazonaws.com/multifiles/";


-(void)setup {
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshUserData) forControlEvents:UIControlEventValueChanged];
    [self.fileCollection addSubview:refreshControl];
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = .5; //seconds
    lpgr.delegate = self;
    [fileCollection addGestureRecognizer:lpgr];
    
    loginView.hidden = NO;
    fileView.hidden = YES;
    fileCollection.alwaysBounceVertical=YES;
    if(self.searchBar) {
        [self.searchBar removeFromSuperview];
        self.searchBar = nil;
    }
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
    [self deleteUploadBarWithRefreshData:false];
    
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
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.riccardorizzo.multifiles"];
    
    NSString *UserName = [defaults stringForKey:@"user_name"];
    NSString *password = [defaults stringForKey:@"password"];
    
    [helper loginWithUserName:UserName password:password completition:^(NSString * UserID, BOOL success) {
        if(success) {
            NSLog(@"Login SUCCESS. USER ID: %ld",(long)success);
            USER_ID = [NSString stringWithFormat:@"%@",UserID];
            [self uploadFile:url];
        }
        else {
            [self alertStatus:UserID :@"Sign in Failed!" :0];
        }
    }];
    
}

#pragma mark Keyboard methods

-(void) textFieldDidEndEditing:(UITextField *)textField {
    activeField =  NULL;
}

-(void) textFieldDidBeginEditing:(UITextField *)textField {
    activeField = textField;
}

-(void)registerForKeyboardNotifications
{
    //Adding notifies on keyboard appearing
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}


-(void)keyboardWasShown:(NSNotification*)aNotification
{
    NSLog(@"Keyboard is active.");
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        
        CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
        
        //----------------HERE WE SETUP FOR IPHONE 4/4s/iPod----------------------
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if(iOSDeviceScreenSize.height == 480 || UIInterfaceOrientationIsLandscape(interfaceOrientation)){
            NSDictionary* info = [aNotification userInfo];
            CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
            CGRect aRect = self.view.frame;
            aRect.size.height -= kbSize.height;
            CGRect f = self.view.frame;
            f.origin.y = -kbSize.height/2;
            self.view.frame = f;
            viewWasScrolled = true;
        }
    }
}

-(void) keyboardWillBeHidden:(NSNotification*)aNotification
{
    if(viewWasScrolled) {
        CGRect f = self.view.frame;
        f.origin.y = 0.0f;
        self.view.frame = f;
    }
    viewWasScrolled = false;
}

-(void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if(activeField != NULL)
        [activeField resignFirstResponder];
}

-(void)deregisterFromKeyboardNotifications
{
    //Removing notifies on keyboard appearing
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


#pragma mark End DocumentController

-(void)addSearchBar{
    
    if (!self.searchBar) {
        self.searchBarBoundsY = navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height - 20;
        self.searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0,self.searchBarBoundsY, [UIScreen mainScreen].bounds.size.width, 46)];
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
    
    if(UserName != nil) {
        [txtUserName setText:UserName];
        [txtUserPassword setText:password];
        [self userLogin:UserName withPassword:password];
    }
    else {
        [txtUserName setText:@""];
        [txtUserPassword setText:@""];
    }
}

/*****************************
 * login
 * this check if there are some login data saved
 * and perform a login if is true
 * Type: UI
 *****************************/
-(void)showFilePopupMenu {
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Select Option for file:" delegate:(id)self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                            @"View",     //0
                            @"Rate",   //1 -> 3
                            @"Rename",   //2 -> 1
                            @"Delete",     //3 -> 2
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
                case 0:         //View
                    [self downloadFileForCurrentUser:selectedFile];
                    break;
                case 2:         //Rename
                    [self askForNewFileName:selectedFile];
                    //[self renameFile:selectedFile renameTo:@"Test"];
                    break;
                case 3:         //Delete
                    [self askForDeleteFile];
                    break;
                case 1:
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
    if(selectedIndex > -1) {  //CellSelected
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
    
    if(alertView.tag==1) {      //Ask for deleting file
        if(buttonIndex==1) {        //Yes!
            
            CloudFile *cFile;
            
            if(!self.searchBarActive)
                cFile = [cloudFiles objectAtIndex:selectedIndex];
            else
                cFile = [self.dataSourceForSearchResult objectAtIndex:index];
            
            NSString *file = cFile->fileName; //[files objectAtIndex:cellSelected.row];
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
    
    helper = [[MultifilesHelper alloc] init];
    helper.delegate = self;
    
    if(!loggedIn)
        [self login];
}


-(void)profileUpdated:(NSNotification *) notification{
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    txtUserName.delegate = self;
    txtUserPassword.delegate = self;
    [self registerForKeyboardNotifications];
    [loginView setUserInteractionEnabled:true];
    [self setup];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/* Logout
 */
- (IBAction)fileXBtnClick:(id)sender {
    if(!fileView.hidden) {
        cloudFiles = [NSMutableArray new];
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.riccardorizzo.multifiles"];
        [defaults setObject:nil forKey:@"user_name"];  //With Facebook use email as login
        [defaults setObject:nil forKey:@"password"];   //and ID as password
        [defaults synchronize];
        [txtUserName setText:@""];
        [txtUserPassword setText:@""];
        loggedIn = NO;
        [self setup];
        [self registerForKeyboardNotifications];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(cloudFiles != NULL)
        NSLog(@"%lu",(unsigned long)cloudFiles.count);
    
    [refreshControl endRefreshing];
    if(!self.searchBarActive)
        return cloudFiles.count; //files.count;
    
    return self.dataSourceForSearchResult.count;
}

-(void)rateFile:(NSInteger)index withRating:(NSInteger)rating {
    
    CloudFile *file;
    
    if(!self.searchBarActive)
        file = [cloudFiles objectAtIndex:index];
    else
        file = [self.dataSourceForSearchResult objectAtIndex:index];
    
    NSString *fileID = file->fileID;   //[FileID objectAtIndex:index.row];
    [self setRateForFile:fileID withRateOf:[NSString stringWithFormat:@"%ld",(long)rating]];
}

-(void)showRatingView {
    
    StarRatingView *ratingView = [[StarRatingView alloc] initWithFrame:CGRectMake(10, 10, 300, 100)];
    ratingView.center = self.view.center;
    ratingView.currIndex = selectedIndex;
    
    CloudFile *file;
    
    if(!self.searchBarActive)
        file = [cloudFiles objectAtIndex:selectedIndex];
    else
        file = [self.dataSourceForSearchResult objectAtIndex:selectedIndex];
    
    [ratingView setInitalRating: file->fileRating.integerValue];   //[[FileRating objectAtIndex:cellSelected.row] integerValue]];
    ratingView.delegate = (id)self;
    [self.view addSubview:ratingView];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"Cell";
    
    SWTableViewCell *cell = (SWTableViewCell*)([tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath]);
    
    cell.rightUtilityButtons = [self rightButtons];
    cell.leftUtilityButtons = [self leftButtons];
    cell.delegate = self;
    
    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:100];
    UILabel     *recipeLabel = (UILabel*)[cell viewWithTag:101];
    UILabel     *recipeLabelSIze = (UILabel*)[cell viewWithTag:102];
    UILabel     *recipeFileName = (UILabel*)[cell viewWithTag:103];
    
    if(cloudFiles.count >= indexPath.row) {
        CloudFile *file = [cloudFiles objectAtIndex:indexPath.row];
        
        if (!self.searchBarActive)
        {
            NSString* theFileName = [file->fileName lastPathComponent]; //[[files objectAtIndex:indexPath.row] lastPathComponent];
            recipeFileName.text = theFileName;
            recipeLabel.text = [NSString stringWithFormat:@"Uploaded on: %@",file->createdAt];    //[file_acreateat objectAtIndex:indexPath.row]];
            recipeLabelSIze.text = file->fileSize; //[file_size objectAtIndex:indexPath.row];
        }
        else
        {
            CloudFile *filteredFile = [self.dataSourceForSearchResult objectAtIndex:indexPath.row];
            NSString* theFileName = [filteredFile->fileName lastPathComponent];
            recipeFileName.text = theFileName;
            
            CloudFile *cFile = [cloudFiles objectAtIndex:[self searchIndexFromArray:cloudFiles search:theFileName]];   //files
            
            recipeLabel.text = [NSString stringWithFormat:@"Uploaded on: %@", cFile->createdAt];
            //[file_acreateat objectAtIndex:[self searchSizeFromArray:files search:theFileName]]];
            
            recipeLabelSIze.text = cFile->fileSize;
            file = cFile;
            //[file_size objectAtIndex:[self searchSizeFromArray:files search:theFileName]];
        }
        
        NSString *extension = [recipeFileName.text pathExtension];
        if([extension.lowercaseString isEqualToString:@"jpg"] || [extension.lowercaseString isEqualToString:@"png"] || [extension.lowercaseString isEqualToString:@"tiff"] || [extension.lowercaseString isEqualToString:@"bmp"])
        {
            recipeImageView.image = [UIImage imageNamed:@"images.png"];
        }
        else if([extension.lowercaseString isEqualToString:@"doc"] || [extension.lowercaseString isEqualToString:@"docx"] || [extension.lowercaseString isEqualToString:@"pdf"] || [extension.lowercaseString isEqualToString:@"txt"] || [extension.lowercaseString isEqualToString:@"xls"] || [extension.lowercaseString isEqualToString:@"xslx"])
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
        
        
        //for(int i=0;i<[[FileRating objectAtIndex:indexPath.row] integerValue];i++)
        for(int i=0;i<file->fileRating.integerValue;i++)
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
        
    }
    return cell;
}

-(NSString*) getSelectedFile:(NSIndexPath*) indexPath {
    
    NSString *url_ = @"";
    NSString *fileUrl;
    CloudFile *file;
    if(!self.searchBarActive)
    {
        file = [cloudFiles objectAtIndex:indexPath.row];
    }
    else {
        file = [self.dataSourceForSearchResult objectAtIndex:indexPath.row];
    }
    url_ = file->fileName;
    fileUrl = [NSString stringWithFormat:@"%@%@/%@",awsWebBaseName,USER_ID,url_];
    
    
    url_ = [fileUrl
            stringByReplacingOccurrencesOfString: @" "
            withString: @"%20"];
    NSLog(@"%@",url_);
    return url_;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(cellSelected) {
        UITableViewCell *datasetCellDeselect = [fileCollection cellForRowAtIndexPath:cellSelected];
        datasetCellDeselect.layer.cornerRadius = 0;
        datasetCellDeselect.layer.shadowOpacity = 0.0;
        datasetCellDeselect.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        datasetCellDeselect.backgroundColor = [UIColor clearColor]; // Default color
    }
    
    UITableViewCell *datasetCell = [fileCollection cellForRowAtIndexPath:indexPath];
    datasetCell.layer.cornerRadius = 10;
    datasetCell.layer.shadowOpacity = 0.8;
    datasetCell.layer.shadowOffset = CGSizeMake(0.5f, 0.5f);
    
    cellSelected = indexPath;
    selectedFile = [self getSelectedFile:indexPath];
    
    [self.view endEditing:YES];
}


#pragma mark SWTableView Delegate and addon button
-(void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    
    if(cell) {
        NSIndexPath *indexPath = [self.fileCollection indexPathForCell:cell];
        selectedFile = [self getSelectedFile:indexPath];
        selectedIndex = indexPath.row;
        switch (index) {
            case 0:         //View
                [self downloadFileForCurrentUser:selectedFile];
                break;
            case 1:         //Rename
                [self askForNewFileName:selectedFile];
                break;
            case 2:         //Delete
                [self askForDeleteFile];
                break;
            default:
                break;
        }
        [self.fileCollection reloadData];
    }
}

-(void)shareFile:(NSInteger) filePosition{
    
    CloudFile *file;
    
    if(!self.searchBarActive)
        file = [cloudFiles objectAtIndex:filePosition];
    else
        file = [self.dataSourceForSearchResult objectAtIndex:filePosition];
    
    ShareFileViewController *shareView = [[self storyboard] instantiateViewControllerWithIdentifier:@"sharingFileView"];
    shareView->fileIDToShare = file->fileID;
    shareView->fileNameToShare = file->fileName;
    shareView->mainView = self;
    [self presentViewController:shareView animated:true completion:^{
        [self.fileCollection reloadData];
    }];
}

- (IBAction)forgotPasswordButtonClick:(id)sender {
    
    ForgotPasswordViewController *recovery =  [[self storyboard] instantiateViewControllerWithIdentifier:@"ForgotPasswordView"];
    recovery->mainView = self;
    [self presentViewController:recovery animated:true completion:^{
        
    }];
}


-(void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    
    if(cell) {
            NSIndexPath *indexPath = [self.fileCollection indexPathForCell:cell];
            selectedFile = [self getSelectedFile:indexPath];
            selectedIndex = indexPath.row;
    
        switch (index) {
            case 0:         //Share
                [self shareFile:indexPath.row];
                break;
            case 1:
                [self showRatingView];
                break;
            default:
                break;
        }
    }
}


-(NSArray *)leftButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.43 green:0.62 blue:0.92 alpha:1.0]
                                                title:@"Share"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.00 green:0.85 blue:0.40 alpha:1.0]
                                                title:@"Rate"];
    return rightUtilityButtons;
    
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.43 green:0.62 blue:0.92 alpha:1.0]
                                                title:@"View"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.42 green:0.66 blue:0.31 alpha:1.0]
                                                title:@"Rename"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Delete"];
    
    return rightUtilityButtons;
}

-(void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *datasetCell = [fileCollection cellForRowAtIndexPath:indexPath];
    datasetCell.backgroundColor = [UIColor clearColor]; // Default color
    datasetCell.layer.cornerRadius = 0;
    datasetCell.layer.shadowOpacity = 0.0;
    datasetCell.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
}

#pragma mark other

- (IBAction)closeFileView:(id)sender {
    //  if(!fileWebViewer.hidden) fileWebViewer.hidden = YES;
    // else if(!fileCollection.hidden) fileCollection.hidden = YES;
    // loginButton.enabled = YES;
}


-(NSInteger)searchIndexFromArray:(NSMutableArray*)array search:(NSString*)text_to_search {
    
    for(int i=0;i<array.count;i++)
    {
        CloudFile *cFile = [array objectAtIndex:i];
        if([[cFile->fileName lastPathComponent] isEqualToString:text_to_search])
            return i;
    }
    return 0;
}

-(void)setRateForFile:(NSString*)fileID withRateOf:(NSString*)rate {
    
    if(USER_ID != nil) {
        
        [helper setRateForFileWithFilePath:fileID rating:rate userID:USER_ID completition:^(BOOL success) {
            //  [helper setRateForFile:fileID rating:rate userID:USER_ID completition:^(BOOL success) {
            if(success) {
                [self refreshUserData];
            }
        }];
    }
}

-(void)deleteFile:(NSString*)filePath {
    
    [helper deleteFileWithFilePath:filePath completition:^(BOOL success) {
        //[helper deleteFile:filePath completition:^(BOOL success) {
        if(success)
            [self refreshUserData];
    }];
}

-(void)refreshUserData {
    
    if(USER_ID != nil && !self.searchBarActive)
    {
        images = [NSMutableArray new];
        
        cloudFiles = [NSMutableArray new];
        
        [helper getFileListForUserWithCompletition:^(BOOL success, id _Nullable jsonDataRcv) {
            if(success) {
                for (NSDictionary *dict in jsonDataRcv) {
                    
                    CloudFile *file = [[CloudFile alloc] init];
                    file->fileName = [[dict valueForKey:@"CurrFileName"] copy];
                    file->createdAt = [[dict valueForKey:@"CreatedAt"] copy];
                    file->fileSize = [[dict valueForKey:@"FileSize"] copy];
                    file->fileRating = [[dict valueForKey:@"Rating"] copy];
                    file->fileID = [[dict valueForKey:@"FileID"] copy];
                    
                    [cloudFiles addObject:file];
                    
                }
                
                if(cloudFiles.count>0) {    //files
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
    
    [helper registerNewUserWithUserName:userName userPassword:password1 userPasswordRepeat:passwordRepeat userEmail:userEmail completition:^(NSString * _Nonnull message, BOOL success) {
        //[helper registerNewUser:userName userPassword:password1 userPasswordRepeat:passwordRepeat userEmail:userEmail completition:^(NSString * _Nonnull message, BOOL success) {
        
        if(success) {
            [self alreadyRegister:nil];
            [self alertStatus:message :@"Multifiles" :0];
            [self saveUserLoginData:userName withPassword:password1];
            [self performSegueWithIdentifier:@"returnToMainViewSegue" sender:self];
        }
        else {
            [self alertStatus:message :@"Warning" :0];
        }
        
    }];
    
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
        [self deleteUploadBarWithRefreshData:false];
    
    // Actual progress is self.receivedBytes / self.totalBytes
}

- (void) updateProgressBarWithPercentage:(double)percentage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        double val = percentage;
        progressBar.progress = val;
        NSLog(@"%f percento",(progressBar.progress*100));
        labelProgress.text = [NSString stringWithFormat:@"Uploading %.2f%% ...",(progressBar.progress*100)];
        if(percentage >= 1.0)
            [self deleteUploadBarWithRefreshData:true];
    });
}


-(void)deleteUploadBarWithRefreshData:(BOOL)refreshData
{
    [[self.view viewWithTag:12] removeFromSuperview];
    [[self.view viewWithTag:11] removeFromSuperview];
    [[self.view viewWithTag:10] removeFromSuperview];
    if(refreshData)
        [self refreshUserData];
}

-(void)createUploadBar
{
    UIView *baseView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
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
    [self deleteUploadBarWithRefreshData:true];
}

-(UIView *)getMainView {
    return self.view;
}

-(void) uploadFile:(NSURL *)filePath {
    
    [helper uploadWithFilePath:filePath];
    //  [helper upload: filePath];
}

-(void) renameFile:(NSString*)oldFile renameTo:(NSString*)newFile {
    
    [helper renameFileWithFileName:oldFile newFileName:newFile completition:^(BOOL success) {
        
        //[helper renameFile:oldFile newFileName:newFile completition:^(BOOL success) {
        
        if(success) {
            NSLog(@"Rename success");
            [self refreshUserData];
        }
    }];
    
}

-(void) userLogin:(NSString*)userName withPassword:(NSString*)userPassword {
    
    if([userName isEqualToString:@""] || [userPassword isEqualToString:@""] ) {
        [self alertStatus:@"Please enter Email and Password" :@"Sign in Failed!" :0];
        
    } else {
        [helper showLoadingHUD];
        
        [helper loginWithUserName:userName password:userPassword completition:^(NSString * UserID, BOOL success) {
            //        [helper login:userName password:userPassword completition:^(NSString * UserID, BOOL success) {
            if(success) {
                [self deregisterFromKeyboardNotifications];
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
    
    [helper getUserSpaceWithUserID:USER_ID completition:^(NSString * _Nonnull spaceUsed, BOOL success) {
        
        //[helper getUserSpace:USER_ID completition:^(NSString * _Nonnull spaceUsed, BOOL success) {
        
        if(success) {
            UsedSpace = [NSString stringWithFormat:@"%@",spaceUsed];
            [navTitle setTitle:[NSString stringWithFormat:@"MultiFiles - Used:%@",UsedSpace]];
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
    //NSPredicate *resultPredicate    = [NSPredicate predicateWithFormat:@"self contains[c] %@", searchText];
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(fileName contains[c] %@)", searchText];
    
    //[files filteredArrayUsingPredicate:resultPredicate]
    
    self.dataSourceForSearchResult  =[NSMutableArray arrayWithArray:[cloudFiles filteredArrayUsingPredicate:resultPredicate]];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    // user did type something, check our datasource for text that looks the same
    if (searchText.length>0) {
        // search and reload data source
        self.searchBarActive = YES;
        [self filterContentForSearchText:searchText
              scope:[[searchBar scopeButtonTitles]
              objectAtIndex:[searchBar selectedScopeButtonIndex]]];
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
