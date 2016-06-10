//
//  AppDelegate.m
//  MultiFiles
//
//  Created by Riccardo Rizzo on 12/05/15.
//  Copyright (c) 2015 Riccardo Rizzo. All rights reserved.
//

#import "AppDelegate.h"
//@import Onboard;
#import "OnboardingViewController.h"
#import "OnboardingContentViewController.h"

@interface AppDelegate ()

@end

static NSString * const kUserHasOnboardedKey = @"user_has_onboarded";

@implementation AppDelegate

@synthesize window,mainViewController;


-(void)initMainViewController {
    
    UIStoryboard *storyboard;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        storyboard = [UIStoryboard storyboardWithName:@"MainiPad" bundle:nil];
    else
        storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    mainViewController = [storyboard instantiateInitialViewController];
    self.window.rootViewController = mainViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    // determine if the user has onboarded yet or not
    BOOL userHasOnboarded = [[NSUserDefaults standardUserDefaults] boolForKey:kUserHasOnboardedKey];

    if (userHasOnboarded) {
        [self initMainViewController];
    }
    else {
        self.window.rootViewController = [self generateStandardOnboardingVC];
        //self.window.rootViewController = [self generateMovieOnboardingVC];
    }
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)handleOnboardingCompletion {
    // set that we have completed onboarding so we only do it once... for demo
    // purposes we don't want to have to set this every time so I'll just leave
    // this here...
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserHasOnboardedKey];
    
    // transition to the main application
    [self initMainViewController];
}

 - (OnboardingViewController *)generateStandardOnboardingVC {
     
    OnboardingContentViewController *firstPage = [OnboardingContentViewController contentWithTitle:@"Welcome to Multifiles" body:@"The place where save your files." image:[UIImage imageNamed:@"little_cloud"] buttonText:@"Upload your files" action:^{
     
    }];
    
    OnboardingContentViewController *secondPage = [OnboardingContentViewController contentWithTitle:@"The Cloud in your Pocket." body:@"Upload your files from your preferred APP." image:[UIImage imageNamed:@"layers"] buttonText:@"Share your files" action:^{
      
    }];
    secondPage.movesToNextViewController = YES;
    secondPage.viewDidAppearBlock = ^{

    };
    
    OnboardingContentViewController *thirdPage = [OnboardingContentViewController contentWithTitle:@"Get it from everywhere" body:@"And download them from a connected device via WEB." image:[UIImage imageNamed:@"space3"] buttonText:@"Get Started. It's Free" action:^{
        [self handleOnboardingCompletion];
    }];
    
    OnboardingViewController *onboardingVC = [OnboardingViewController onboardWithBackgroundImage:[UIImage imageNamed:@"bg.jpg"] contents:@[firstPage, secondPage, thirdPage]];
     
    onboardingVC.shouldFadeTransitions = YES;
    onboardingVC.fadePageControlOnLastPage = YES;
    onboardingVC.fadeSkipButtonOnLastPage = YES;
    onboardingVC.shouldMaskBackground = NO;
    onboardingVC.shouldBlurBackground = YES; // defaults to NO
    
    // If you want to allow skipping the onboarding process, enable skipping and set a block to be executed
    // when the user hits the skip button.
    onboardingVC.allowSkipping = YES;
    onboardingVC.skipHandler = ^{
        [self handleOnboardingCompletion];
    };
    
    return onboardingVC;
}

- (OnboardingViewController *)generateMovieOnboardingVC {
    OnboardingContentViewController *firstPage = [[OnboardingContentViewController alloc] initWithTitle:@"Everything Under The Sun" body:@"The temperature of the photosphere is over 10,000°F." image:nil buttonText:nil action:nil];
    firstPage.topPadding = -15;
    firstPage.underTitlePadding = 160;
    firstPage.titleLabel.textColor = [UIColor colorWithRed:239/255.0 green:88/255.0 blue:35/255.0 alpha:1.0];
    firstPage.titleLabel.font = [UIFont fontWithName:@"SFOuterLimitsUpright" size:38.0];
    firstPage.bodyTextLabel.textColor = [UIColor colorWithRed:239/255.0 green:88/255.0 blue:35/255.0 alpha:1.0];
    firstPage.bodyTextLabel.font = [UIFont fontWithName:@"NasalizationRg-Regular" size:18.0];
    
    OnboardingContentViewController *secondPage = [[OnboardingContentViewController alloc] initWithTitle:@"Every Second" body:@"600 million tons of protons are converted into helium atoms." image:nil buttonText:nil action:nil];
    secondPage.titleLabel.font = [UIFont fontWithName:@"SFOuterLimitsUpright" size:38.0];
    secondPage.underTitlePadding = 170;
    secondPage.topPadding = 0;
    secondPage.titleLabel.textColor = [UIColor colorWithRed:251/255.0 green:176/255.0 blue:59/255.0 alpha:1.0];
    secondPage.bodyTextLabel.textColor = [UIColor colorWithRed:251/255.0 green:176/255.0 blue:59/255.0 alpha:1.0];
    secondPage.bodyTextLabel.font = [UIFont fontWithName:@"NasalizationRg-Regular" size:18.0];
    
    OnboardingContentViewController *thirdPage = [[OnboardingContentViewController alloc] initWithTitle:@"We're All Star Stuff" body:@"Our very bodies consist of the same chemical elements found in the most distant nebulae, and our activities are guided by the same universal rules." image:nil buttonText:@"Explore the universe" action:^{
        [self handleOnboardingCompletion];
    }];
    thirdPage.topPadding = 10;
    thirdPage.underTitlePadding = 160;
    thirdPage.bottomPadding = -10;
    thirdPage.titleLabel.font = [UIFont fontWithName:@"SFOuterLimitsUpright" size:38.0];
    thirdPage.titleLabel.textColor = [UIColor colorWithRed:58/255.0 green:105/255.0 blue:136/255.0 alpha:1.0];
    thirdPage.bodyTextLabel.textColor = [UIColor colorWithRed:58/255.0 green:105/255.0 blue:136/255.0 alpha:1.0];
    thirdPage.bodyTextLabel.font = [UIFont fontWithName:@"NasalizationRg-Regular" size:15.0];
    [thirdPage.actionButtonBtn setTitleColor:[UIColor colorWithRed:239/255.0 green:88/255.0 blue:35/255.0 alpha:1.0] forState:UIControlStateNormal];
    thirdPage.actionButtonBtn.titleLabel.font = [UIFont fontWithName:@"SpaceAge" size:17.0];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *moviePath = [bundle pathForResource:@"sun" ofType:@"mp4"];
    NSURL *movieURL = [NSURL fileURLWithPath:moviePath];
    
    OnboardingViewController *onboardingVC = [[OnboardingViewController alloc] initWithBackgroundVideoURL:movieURL contents:@[firstPage, secondPage, thirdPage]];
    onboardingVC.shouldFadeTransitions = YES;
    onboardingVC.shouldMaskBackground = NO;
    onboardingVC.pageControlCtrl.currentPageIndicatorTintColor = [UIColor colorWithRed:239/255.0 green:88/255.0 blue:35/255.0 alpha:1.0];
    onboardingVC.pageControlCtrl.pageIndicatorTintColor = [UIColor whiteColor];
    return onboardingVC;
}


- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if (url != nil && [url isFileURL]) {
        // Tell our OfflineReaderViewController to process the URL
        [self.mainViewController handleDocumentOpenURL:url];
        return YES;
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
