//
//  OAuthLoginViewController.m
//  myDropboxFolder
//
//  Created by Oleg Pochtovy on 31.07.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

#import "OAuthLoginViewController.h"
#import "Dropbox.h"

@interface OAuthLoginViewController ()
@property (nonatomic, weak) IBOutlet UITextView *loginView;
@property (nonatomic, weak) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) UIAlertView *tokenAlert;

@end

@implementation OAuthLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)signIn:(id)sender
{
    // show alert view saying we are getting token
    _tokenAlert = [[UIAlertView alloc] initWithTitle:@"Getting token"
                                             message:@"Logging into Dropbox"
                                            delegate:nil
                                   cancelButtonTitle:@"Cancel"
                                   otherButtonTitles:nil];
    [_tokenAlert show];
    
    // move on to step 2 of oauth token acquisation
    [self getOAuthRequestToken];
}

#pragma mark - OAUTH, step 1
- (void)getOAuthRequestToken
{
    // OAUTH Step 1. Get request token.
    [Dropbox requestTokenWithCompletionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response; // we made a HTTP request, so the response will be a HTTP response. So here we cast the NSURLResponse to an NSHTTPURLRequest response so we can access to the statusCode property. If we receive an HTTP status code of 200 then all is well.
            if (httpResp.statusCode == 200) {
                NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                /*
                 oauth_token The request token that was just authorized. The request token secret isn't sent back.
                 If the user chooses not to authorize the application, they will get redirected to the oauth_callback URL with the additional URL query parameter not_approved=true.
                 */
                NSDictionary *oauthDict = [Dropbox dictionaryFromOAuthResponseString:responseStr];
                
                // save the REQUEST token and secret to use for normal api calls
                [[NSUserDefaults standardUserDefaults] setObject:oauthDict[oauthTokenKey] forKey:requestToken];
                [[NSUserDefaults standardUserDefaults] setObject:oauthTokenKeySecret forKey:requestTokenSecret];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                NSString *authorizationURLWithParams = [NSString stringWithFormat:@"https://www.dropbox.com/1/oauth/authorize?oauth_token=%@&oauth_callback=mydropbox://userauthorization",oauthDict[oauthTokenKey]];
                
                // escape codes
                NSString *escapedURL = [authorizationURLWithParams stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                [_tokenAlert dismissWithClickedButtonIndex:0 animated:NO];
                
                // opens to user auth page in safari
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:escapedURL]];
            } else {
                // HANDLE BAD RESPONSE //
                NSLog(@"unexpected response getting token %@",[NSHTTPURLResponse localizedStringForStatusCode:httpResp.statusCode]);
                UIAlertView *badResponseAlertView = [[UIAlertView alloc] initWithTitle:@"Unexpected Response Getting Token"
                                                                         message:[NSHTTPURLResponse localizedStringForStatusCode:httpResp.statusCode]
                                                                        delegate:nil
                                                               cancelButtonTitle:@"Ok"
                                                               otherButtonTitles:nil];
                [badResponseAlertView show];
            }
        } else {
            // ALWAYS HANDLE ERRORS :-] //
            UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Request Token"
                                                                message:[error localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
            [errorAlertView show];
        }
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
