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

@implementation ShareViewController

static NSString * const websiteName = @"http://www.riccardorizzo.eu/dev";

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

-(void) connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
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
    NSString* theFileName = [filePath lastPathComponent];
    
    NSError *error = nil;
    
    if(filePath!=nil)
    {
        NSData *imageData = [NSData dataWithContentsOfFile:(NSString*)filePath options:NSDataReadingMappedAlways error:&error];
        
        if (imageData == nil)
        {
            NSLog(@"Failed to read file, error %@", error);
        }
        else
        {
            [self createUploadBar];
        
            NSString *urlString =[NSString stringWithFormat:@"%@/upload.php",websiteName];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            
            [request setURL:[NSURL URLWithString:urlString]];
            [request setHTTPMethod:@"POST"];
            
            NSString *boundary = @"---------------------------14737809831466499882746641449";
            
            NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
            [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
            
            NSMutableData *body = [NSMutableData data];
            
            /* [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
             [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"JSON\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
             [body appendData:[filenames dataUsingEncoding:NSUTF8StringEncoding]];
             */
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            NSString *fileDataName = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n",theFileName];
            [body appendData:[fileDataName dataUsingEncoding:NSUTF8StringEncoding]];
            
            [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[NSData dataWithData:imageData]];
            
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            // setting the body of the post to the reqeust
            [request setHTTPBody:body];
            
            uploadConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            
            if(uploadConnection) {
                NSOperationQueue *queueL = [[NSOperationQueue alloc] init];
                // NSData *returnData;
                queueL.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
                [NSURLConnection sendAsynchronousRequest:request queue:queueL completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
                {
                    NSLog(@"finish");
                }];
                
            }
        }
    }
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
            
            NSString *post =[[NSString alloc] initWithFormat:@"user_name=%@&user_password=%@&JSON=1",userName,userPassword];
            NSLog(@"PostData: %@",post);
            
            NSString *web_base = [NSString stringWithFormat:@"%@%@",websiteName,@"/login.php"];
            
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
