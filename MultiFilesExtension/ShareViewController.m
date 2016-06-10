//
//  ShareViewController.m
//  MultiFilesExtension
//
//  Created by Riccardo Rizzo on 01/06/15.
//  Copyright (c) 2015 Riccardo Rizzo. All rights reserved.
//

#import "ShareViewController.h"


@interface ShareViewController ()

@end

@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@implementation ShareViewController

//Only for deletege compatibility
-(void)refreshUserData {
    
}

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

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

-(UIView *)getMainView {
    return self.view;
}

-(void)deleteUploadBar:(BOOL)refreshData
{
    [[self.view viewWithTag:11] removeFromSuperview];
    [[self.view viewWithTag:10] removeFromSuperview];
    
    if(itemsToDownload.count == 0)
    {
         [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    }
    else
    {
        NSURL *newUrl =[itemsToDownload objectAtIndex:0];
        [itemsToDownload removeObjectAtIndex:0];
        [self uploadFile:newUrl];
    }
  
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
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:baseView];
    [self.view addSubview:progressView];
    [self.view addSubview:cancelButton];
}

-(void)cancelPressed {
    NSLog(@"Cancel!");
    [uploadConnection cancel];
    [itemsToDownload removeAllObjects];
    [self deleteUploadBar:true];
}

-(void) uploadFile:(NSURL *)filePath; {

    [helper upload:filePath];
}

-(void)getPassedFiles {
    for (NSItemProvider* itemProvider in ((NSExtensionItem*)self.extensionContext.inputItems[0]).attachments )
    {
        if([itemProvider hasItemConformingToTypeIdentifier:@"public.image"])
        {
            [itemProvider loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:
             ^(id<NSSecureCoding> item, NSError *error)
             {
                 if([(NSObject*)item isKindOfClass:[NSURL class]])
                 {
                     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                         if(!UploadInProgress)
                         {
                             UploadInProgress = YES;
                             [self uploadFile:(NSURL*)item];
                         }
                         else
                             [itemsToDownload addObject:(NSURL*)item];
                     }];
                 }
             }];
        }
        if([itemProvider hasItemConformingToTypeIdentifier:@"com.adobe.pdf"])
        {
            [itemProvider loadItemForTypeIdentifier:@"com.adobe.pdf" options:nil completionHandler:
             ^(id<NSSecureCoding> item, NSError *error)
             {
                 if([(NSObject*)item isKindOfClass:[NSURL class]])
                 {
                     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                         if(!UploadInProgress)
                         {
                             UploadInProgress = YES;
                             [self uploadFile:(NSURL*)item];
                         }
                         else
                             [itemsToDownload addObject:(NSURL*)item];
                     }];
                 }
             }];
        }
    }
}

-(void) userLogin:(NSString*)userName withPassword:(NSString*)userPassword {
    
        [helper showLoadingHUD];
    
        [helper login:userName password:userPassword completition:^(NSString * UserID, BOOL success) {
            if(success) {
                NSLog(@"Login SUCCESS. USER ID: %ld",(long)success);
                USER_ID = [NSString stringWithFormat:@"%@",UserID];
                [self getPassedFiles];
            }
        }];
}

-(void)login {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.riccardorizzo.multifiles"];
    
    NSString *UserName = [defaults stringForKey:@"user_name"];
    NSString *password = [defaults stringForKey:@"password"];
    
    if(UserName!= nil && password!= nil)
    {
        [self userLogin:UserName withPassword:password];
    }
    else
    {
        [self deleteUploadBar:false];
    }
}


//-(void)viewDidAppear:(BOOL)animated {
-(void)viewDidLoad {
    [super viewDidLoad];
    helper = [[MultifilesHelper alloc] init];
    helper.delegate = self;
    UploadInProgress = NO;
    itemsToDownload = [NSMutableArray new];
    [self login];
}

@end
