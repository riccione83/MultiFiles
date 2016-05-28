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

static NSString * const websiteName = @"http://multifiles.heroku.com/API";

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


-(void) connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWrittentotalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
 /*   NSLog(@"%ld/%ld bytes written",(long)totalBytesWritten,(long)totalBytesExpectedToWrite);
    double val =( (double)totalBytesWritten/(double)totalBytesExpectedToWrite );
    progressBar.progress = val;
    NSLog(@"%f percento",(progressBar.progress*100));
    labelProgress.text = [NSString stringWithFormat:@"Uploading %.2f%% ...",(progressBar.progress*100)];
    if(totalBytesExpectedToWrite == totalBytesWritten)
        [self deleteUploadBar:true];
  */
}

-(void) updateProgressBar:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    NSLog(@"%ld/%ld bytes written",(long)totalBytesWritten,(long)totalBytesExpectedToWrite);
    double val =( (double)totalBytesWritten/(double)totalBytesExpectedToWrite );
    progressBar.progress = val;
    NSLog(@"%f percento",(progressBar.progress*100));
    labelProgress.text = [NSString stringWithFormat:@"Uploading %.2f%% ...",(progressBar.progress*100)];
    if(totalBytesExpectedToWrite == totalBytesWritten)
        [self deleteUploadBar:true];
}


-(void)deleteUploadBar:(BOOL)refreshData
{
    [[self.view viewWithTag:11] removeFromSuperview];
    [[self.view viewWithTag:10] removeFromSuperview];
    
    if(itemsToDownload.count == 0)
    {
         [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    //    exit(0);
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

    MultifilesHelper *helper = [[MultifilesHelper alloc] init];
    helper.delegate = self;
    [helper upload:filePath];
}


-(BOOL) userLogin:(NSString*)userName withPassword:(NSString*)userPassword {
    NSInteger success = 0;
    @try {
        
        if([userName isEqualToString:@""] || [userPassword isEqualToString:@""] ) {
            
         //   [self alertStatus:@"Please enter Email and Password" :@"Sign in Failed!" :0];
            return NO;
            
        } else {
            
           // activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
           // [activityIndicator setCenter:CGPointMake(self.view.frame.size.width/2.0, self.view.frame.size.height/2.0)]; // I do this because I'm in landscape mode
            
          //  [self.view addSubview:activityIndicator]; // spinner is not visible until started
          //  [activityIndicator startAnimating];
            
            NSString *post =[[NSString alloc] initWithFormat:@"?user_name=%@&user_password=%@&JSON=1",userName,userPassword];
            NSLog(@"PostData: %@",post);
            
            NSString *web_base = [NSString stringWithFormat:@"%@%@%@",websiteName,@"/login.php",post];
            
            NSURL *url=[NSURL URLWithString:web_base];
            
            //NSURL *url=[NSURL URLWithString:@"http://localhost:8888/login.php"];
            
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
            
            [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"http://multifiles.heroku.com/"];
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
                
                success = [jsonData[@"success"] integerValue];
                NSLog(@"Success: %ld",(long)success);
                
                if(success > 0)
                {
                    NSLog(@"Login SUCCESS. USER ID: %ld",(long)success);
                    USER_ID = [NSString stringWithFormat:@"%ld",(long)success];
                    return YES;
                } else {
                    
                    NSString *error_msg = (NSString *) jsonData[@"error"];
                    NSLog(@"%@",error_msg);
              //      [self alertStatus:error_msg :@"Sign in Failed!" :0];
                }
                
            } else {
                //if (error) NSLog(@"Error: %@", error);
              //  [self alertStatus:@"Connection Failed" :@"Sign in Failed!" :0];
            }
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
  //      [self alertStatus:@"Sign in Failed." :@"Error!" :0];
    }
    return NO;
}


-(BOOL)login {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.riccardorizzo.multifiles"];
    
    NSString *UserName = [defaults stringForKey:@"user_name"];
    NSString *password = [defaults stringForKey:@"password"];
    
    if(UserName!= nil && password!= nil)
    {
        [self userLogin:UserName withPassword:password];
        return YES;
    }
    return NO;
}


//-(void)viewDidAppear:(BOOL)animated {
-(void)viewDidLoad {
    [super viewDidLoad];
    UploadInProgress = NO;
    itemsToDownload = [NSMutableArray new];
    [self login];
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

@end
