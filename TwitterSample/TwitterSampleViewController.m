//
//  TwitterSampleViewController.m
//  TwitterSample
//
//  Created by 玉山将志 on 2012/10/29.
//  Copyright (c) 2012年 玉山将志. All rights reserved.
//

#import "TwitterSampleViewController.h"

@interface TwitterSampleViewController ()
@property(retain, nonatomic)GTMOAuthAuthentication *auth;
@property(retain, nonatomic)NSMutableData *buffer;
@end



@implementation TwitterSampleViewController


#pragma mark - Consts
static NSString* const CONSUMER_KEY = @"YOUR CONSUMER_KEY";
static NSString* const CONSUMER_SECRET = @"YOUR CONSUMER_SECRET";

// Service name to KeyChain
static NSString *const kTwitterKeychainItemName = @"OAuth Sample: Twitter";

// for Error Alert
static int const kMyAlertViewTagAuthenticationError = 10000;
static int const kMyAlertViewTagConsumerKeyAndSecretError = 10001;

static NSString *const kTwitterServiceName = @"Twitter";



#pragma mark - Action
- (IBAction)tapTweet:(id)sender {
    //    [self postToTwitter:_auth];
    [self doAnAuthenticatedAPIFetch];
}
// 認証処理開始
- (IBAction)signInOutClicked:(id)sender {
    if (![self isSignedIn]) {
        // sign in
        [self signInToTwitter];
    } else {
        // sign out
        [self signOut];
    }
    [self updateUI];
}

#pragma mark -

- (void)doAnAuthenticatedAPIFetch {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
//    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];//not working
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json"];
    NSString *content = @"status=testtesttest";
    NSData *body = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod: @"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    [request setHTTPBody: body];
    [_auth authorizeRequest:request];
    
    // Note that for a request with a body, such as a POST or PUT request, the
    // library will include the body data when signing only if the request has
    // the proper content type header:
    //
    //   [request setValue:@"application/x-www-form-urlencoded"
    //  forHTTPHeaderField:@"Content-Type"];
    
    // Synchronous fetches like this are a really bad idea in Cocoa applications
    //
    // For a very easy async alternative, we could use GTMHTTPFetcher
    NSError *error = nil;
    NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    
    if (data) {
        // API fetch succeeded
        NSString *str = [[[NSString alloc] initWithData:data
                                               encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"API response: %@", str);
    } else {
        // fetch failed
        NSLog(@"API fetch error: %@", error);
    }
}





#pragma mark - OAuth
- (void)displayErrorThatTheCodeNeedsATwitterConsumerKeyAndSecret {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                     message:@"The sample code requires a valid Twitter consumer key and consumer secret to sign in to Twitter"
                                                    delegate:self
                                           cancelButtonTitle:@"Confirm"
                                           otherButtonTitles:nil] autorelease];
    alert.tag = kMyAlertViewTagConsumerKeyAndSecretError;
    [alert show];

}

- (BOOL)isSignedIn {
    BOOL isSignedIn = [_auth canAuthorize];
    return isSignedIn;
}

- (void)updateUI {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // update the text showing the signed-in state and the button title
    if ([self isSignedIn]) {
        // signed in
        NSString *token = [_auth token];
        NSString *email = [_auth userEmail];
        
        BOOL isVerified = [[_auth userEmailIsVerified] boolValue];
        if (!isVerified) {
            // email address is not verified
            NSLog(@"%s \n\temail:%@", __PRETTY_FUNCTION__, email);
        }
        
        NSLog(@"%s \n\ttoken:%@", __PRETTY_FUNCTION__, token);
        
        [_signInOutBtn setTitle:@"Sign Out" forState:UIControlStateNormal];
    } else {
        // signed out
        [_signInOutBtn setTitle:@"Sign In" forState:UIControlStateNormal];
    }
}
- (GTMOAuthAuthentication *)authForTwitter {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    // Note: to use this sample, you need to fill in a valid consumer key and
    // consumer secret provided by Twitter for their API
    //
    // http://twitter.com/apps/
    //
    // The controller requires a URL redirect from the server upon completion,
    // so your application should be registered with Twitter as a "web" app,
    // not a "client" app
    
    if ([CONSUMER_KEY length] == 0 || [CONSUMER_SECRET length] == 0) {
        return nil;
    }
    
    GTMOAuthAuthentication *auth;
    auth = [[[GTMOAuthAuthentication alloc] initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
                                                        consumerKey:CONSUMER_KEY
                                                         privateKey:CONSUMER_SECRET] autorelease];
    
    // setting the service name lets us inspect the auth object later to know
    // what service it is for
    [auth setServiceProvider:kTwitterServiceName];
    return auth;
}
- (void)signOut {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    // remove the stored Twitter authentication from the keychain, if any
    [GTMOAuthViewControllerTouch removeParamsFromKeychainForName:kTwitterKeychainItemName];
    
    // discard our retains authentication object
    [self setAuthentication:nil];
    
    [self updateUI];
}

- (void)signInToTwitter {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self signOut];
    
    NSURL *requestTokenURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
    NSURL *accessTokenURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    NSURL *authorizeURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/authorize"];

    
    GTMOAuthAuthentication *auth = [self authForTwitter];
    if (!auth) {
        [self displayErrorThatTheCodeNeedsATwitterConsumerKeyAndSecret];
    }
    
    // set the callback URL to which the site should redirect, and for which
    // the OAuth controller should look to determine when sign-in has
    // finished or been canceled
    //
    // This URL does not need to be for an actual web page
    [auth setCallback:@"http://www.example.com/OAuthCallback"];
    
    [auth setServiceProvider:kTwitterServiceName];

    
    GTMOAuthViewControllerTouch *viewController;
    viewController = [[[GTMOAuthViewControllerTouch alloc] initWithScope:nil
                                                                language:nil
                                                         requestTokenURL:requestTokenURL
                                                       authorizeTokenURL:authorizeURL
                                                          accessTokenURL:accessTokenURL
                                                          authentication:auth
                                                          appServiceName:kTwitterKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(authViewContoller:finishWithAuth:error:)] autorelease];
    
    //    [[self navigationController] pushViewController:viewController animated:YES];
    
    [self presentModalViewController:viewController animated:YES];
}


// 認証処理完了時
//Delegate Method
- (void)authViewContoller:(GTMOAuthViewControllerTouch *)viewContoller
           finishWithAuth:(GTMOAuthAuthentication *)auth
                    error:(NSError *)error
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // 認証失敗の時
    if (error != nil) {
        // Authentication failed (perhaps the user denied access, or closed the
        // window before granting access)
        NSLog(@"Authentication error:%@ \ncode:%d", error, error.code);
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:@"Authentication failed."
                                                        delegate:self
                                               cancelButtonTitle:@"Confirm"
                                               otherButtonTitles:nil] autorelease];
        alert.tag = kMyAlertViewTagAuthenticationError;
        [alert show];
        NSData *responseData = [[error userInfo] objectForKey:@"data"]; // kGTMHTTPFetcherStatusDataKey
        if ([responseData length] > 0) {
            // show the body of the server's authentication failure response
            NSString *str = [[[NSString alloc] initWithData:responseData
                                                   encoding:NSUTF8StringEncoding] autorelease];
            NSLog(@"%@", str);
        }
        
        [self setAuthentication:nil];
    }
    //認証成功の時
    else {
        NSLog(@"Authentication succeeded.");
        
        // Authentication succeeded
        //
        // At this point, we either use the authentication object to explicitly
        // authorize requests, like
        //
        //   [auth authorizeRequest:myNSURLMutableRequest]
        //
        // or store the authentication object into a GTMHTTPFetcher object like
        //
        //   [fetcher setAuthorizer:auth];
        
        // save the authentication object
        [self setAuthentication:auth];
        
        // Just to prove we're signed in, we'll attempt an authenticated fetch for the
        // signed-in user
//        [self doAnAuthenticatedAPIFetch];
    }
    
    [self updateUI];


    //close ViewController
    [self dismissModalViewControllerAnimated:YES];

}

// UIAlertViewが閉じられた時
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSLog(@"%s", __PRETTY_FUNCTION__);

    // 認証失敗通知AlertViewが閉じられた場合
    if (alertView.tag == kMyAlertViewTagAuthenticationError) {
        // 特に処理なし
    }
    else if(alertView.tag == kMyAlertViewTagConsumerKeyAndSecretError) {
        
    }
}


- (void)setAuthentication:(GTMOAuthAuthentication *)auth {
    [_auth autorelease];
    _auth = [auth retain];
}


#pragma mark - Notification
- (void)signInFetchStateChanged:(NSNotification *)note {
    // this just lets the user know something is happening during the
    // sign-in sequence's "invisible" fetches to obtain tokens
    //
    // the type of token obtained is available as
    //   [[note userInfo] objectForKey:kGTMOAuthFetchTypeKey]
    //
    if ([[note name] isEqual:kGTMOAuthFetchStarted]) {
    } else {
    }
}

- (void)signInNetworkLost:(NSNotification *)note {
    // the network dropped for 30 seconds
    //
    // we could alert the user and wait for notification that the network has
    // has returned, or just cancel the sign-in sheet, as shown here
    GTMOAuthSignIn *signIn = [note object];
    GTMOAuthViewControllerTouch *controller = [signIn delegate];
    [controller cancelSigningIn];
}

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [super viewDidLoad];
    
    
    // Get the saved authentication, if any, from the keychain.
    //
    // The window controller supports methods for saving and restoring
    // authentication under arbitrary keychain item names; see the
    // "keychainForName" methods in the interface.  The keychain item
    // names are up to the application, and may reflect multiple accounts for
    // one or more services.
    GTMOAuthAuthentication *auth = [self authForTwitter];
    if (auth) {
        // 既にOAuth認証済みであればKeyChainから認証情報を読み込む
        // Auth info read from KeyChain
        BOOL didAuth = [GTMOAuthViewControllerTouch authorizeFromKeychainForName:kTwitterKeychainItemName
                                                                  authentication:auth];
        if (didAuth) {
            //authed already
            NSLog(@"%s 未認証", __PRETTY_FUNCTION__);
            // 未認証の場合は認証処理を実施
            
        }
        else {
            NSLog(@"%s 認証済", __PRETTY_FUNCTION__);
            // 認証済みの場合はタイムライン更新
        }
    }
    
    // save the authentication object, which holds the auth tokens
    [self setAuthentication:auth];
    
    // this is optional:
    //
    // we'll watch for the "hidden" fetches that occur to obtain tokens
    // during authentication, and start and stop our indeterminate progress
    // indicator during the fetches
    //
    // usually, these fetches are very brief
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(signInFetchStateChanged:)
               name:kGTMOAuthFetchStarted
             object:nil];
    [nc addObserver:self
           selector:@selector(signInFetchStateChanged:)
               name:kGTMOAuthFetchStopped
             object:nil];
    [nc addObserver:self
           selector:@selector(signInNetworkLost:)
               name:kGTMOAuthNetworkLost
             object:nil];
    
    [self updateUI];
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [super didReceiveMemoryWarning];
    
    if([self.view window] == nil) {
        self.view = nil;
        self.signInOutBtn = nil;
    }}

- (void)viewDidUnload {
    [self setSignInOutBtn:nil];
    [super viewDidUnload];
}
-(void)dealloc {
    [_auth release];
    [_signInOutBtn release];
    [super dealloc];
}



@end
