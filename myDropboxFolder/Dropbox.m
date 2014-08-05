//
//  Dropbox.m
//  myDropboxFolder
//
//  Created by Oleg Pochtovy on 31.07.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

// This clas is a small API that handles most of preparation work before using the Dropbox API that we need to authenticate the user. In Dropbox API, this is done by OAuth – a popular open source protocol that allows secure authorization. OAuth authentication happens in three high level steps:
// 1. Obtain an OAuth request token to be used for the rest of the authentication process. This is the request token.
// 2. A web page is presented to the user through their web browser. Without the user’s authorization in this step, it isn’t possible for your application to obtain an access token from step 3.
// 3. After step 2 is complete, the application calls a web service to exchange the temporary request token (from step1) for a permanent access token, which is stored in the app.

#import "Dropbox.h"

// To use this app you have to create a new Dropbox Platform app first:

// 1. To get started with your Dropbox App, open the Dropbox App Console located at https://www.dropbox.com/developers/apps
// 2. Sign in if you have a Dropbox account, but if not, just create a free Dropbox account.
// 3. Choose the Create App option. You’ll be presented with a series of questions – provide the following responses:
// 3.1. What type of app do you want to create? - Dropbox API app
// 3.2. What type of data does your app need to store on Dropbox? - Files and Datastores
// 3.3. Can your app be limited to its own, private folder? - No – My App needs access to files already on Dropbox
// 3.4. What type of files does your app need access to? - All File Types

// 4. Finally, provide a name for your app, it doesn’t matter what you choose as long as it’s unique. Dropbox will let you know if you’ve chosen a name that’s already in use.
// 5. After you click "Create App" you’ll see the next screen containing the App key and App secret. You need them to put right here below:

#warning INSERT YOUR OWN API KEY and SECRET HERE
static NSString *apiKey = @"API KEY";
static NSString *appSecret = @"SECRET";

// 6. Next, create a folder in the root directory of your main Dropbox folder and name it whatever you wish. If you share this folder with other Dropbox users and send them a build of your app, they will be able to create notes and upload photos for all to see. Put the name of this folder right here below:

#warning THIS FOLDER MUST BE CREATED AT THE TOP LEVEL OF YOUR DROPBOX FOLDER, you can then share this folder with others
NSString * const appFolder = @"YOUR DROPBOX FOLDER";

// 7. To distribute this app to other users and give them access tokens, you will need to turn on the “Enable additional users” setting for your Dropbox Platform App.

NSString * const oauthTokenKey = @"oauth_token";
NSString * const oauthTokenKeySecret = @"oauth_token_secret";
NSString * const dropboxUIDKey = @"uid";

NSString * const dropboxTokenReceivedNotification = @"have_user_request_token";

#pragma mark - saved in NSUserDefaults
NSString * const requestToken = @"requestToken";
NSString * const requestTokenSecret = @"requestTokenSecret";

NSString * const accessToken = @"accessToken";
NSString * const accessTokenSecret = @"accessTokenSecret";

@implementation Dropbox

// this class method obtains an OAuth request token to be used for the rest of the authentication process
+ (void)requestTokenWithCompletionHandler:(DropboxRequestTokenCompletionHandler)completionBlock
{
    NSString *authorizationHeader = [self plainTextAuthorizationHeaderForAppKey:apiKey
                                                                      appSecret:appSecret
                                                                          token:nil
                                                                    tokenSecret:nil];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    [sessionConfig setHTTPAdditionalHeaders:@{@"Authorization": authorizationHeader}];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.dropbox.com/1/oauth/request_token"]];
    [request setHTTPMethod:@"POST"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    
    [[session dataTaskWithRequest:request completionHandler:completionBlock] resume];
}

// this class method returns an additional header to send with request
+(NSString*)plainTextAuthorizationHeaderForAppKey:(NSString*)appKey
                                        appSecret:(NSString*)appSecret
                                            token:(NSString*)token
                                      tokenSecret:(NSString*)tokenSecret
{
    // version, method, and oauth_consumer_key are always present
    NSString *header = [NSString stringWithFormat:@"OAuth oauth_version=\"1.0\",oauth_signature_method=\"PLAINTEXT\",oauth_consumer_key=\"%@\"",apiKey];
    
    // look for oauth_token, include if one is passed in
    if (token) {
        header = [header stringByAppendingString:[NSString stringWithFormat:@",oauth_token=\"%@\"",token]];
    }
    
    // add oauth_signature which is app_secret&token_secret , token_secret may not be there yet, just include @"" if it's not there
    if (!tokenSecret) {
        tokenSecret = @"";
    }
    header = [header stringByAppendingString:[NSString stringWithFormat:@",oauth_signature=\"%@&%@\"",appSecret,tokenSecret]];
    return header;
}

// method to get dictionary with fields "requestToken" and "requestTokenSecret"
+(NSDictionary*)dictionaryFromOAuthResponseString:(NSString*)response
{
    NSArray *tokens = [response componentsSeparatedByString:@"&"];
    NSMutableDictionary *oauthDict = [[NSMutableDictionary alloc] initWithCapacity:5];
    
    for(NSString *t in tokens) {
        NSArray *entry = [t componentsSeparatedByString:@"="];
        NSString *key = entry[0];
        NSString *val = entry[1];
        [oauthDict setValue:val forKey:key];
    }
    
    return [NSDictionary dictionaryWithDictionary:oauthDict];
}

// this class method calls a web service to exchange the temporary request token (from +requestTokenWithCompletionHandler:) for a permanent access token, which is stored in the app.
+(void)exchangeTokenForUserAccessTokenURLWithCompletionHandler:(DropboxRequestTokenCompletionHandler)completionBlock
{
    NSString *urlString = [NSString stringWithFormat:@"https://api.dropbox.com/1/oauth/access_token?"];
    NSURL *requestTokenURL = [NSURL URLWithString:urlString];
    
    NSString *reqToken = [[NSUserDefaults standardUserDefaults] valueForKey:requestToken];
    NSString *reqTokenSecret = [[NSUserDefaults standardUserDefaults] valueForKey:requestTokenSecret];
    
    NSString *authorizationHeader = [self plainTextAuthorizationHeaderForAppKey:apiKey
                                                                      appSecret:appSecret
                                                                          token:reqToken
                                                                    tokenSecret:reqTokenSecret];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    [sessionConfig setHTTPAdditionalHeaders:@{@"Authorization": authorizationHeader}];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestTokenURL];
    [request setHTTPMethod:@"POST"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    [[session dataTaskWithRequest:request completionHandler:completionBlock] resume];
    
}

// this helper method returns a string, in the OAuth specification format. This string contains the access token, token secret and our Dropbox App API key. Remember, this is necessary because every call to the Dropbox API needs to be authenticated.
+ (NSString *)apiAuthorizationHeader
{
    NSString *token = [[NSUserDefaults standardUserDefaults] valueForKey:accessToken];
    NSString *tokenSecret = [[NSUserDefaults standardUserDefaults] valueForKey:accessTokenSecret];
    return [self plainTextAuthorizationHeaderForAppKey:apiKey
                                             appSecret:appSecret
                                                 token:token
                                           tokenSecret:tokenSecret];
}

// next is a convenience method to generate the URL for method -notesOnDropbox in NotesViewController class (in Dropbox, we can see the contents of a folder by making an authenticated GET request to a particular URL – like https://api.dropbox.com/1/metadata/dropbox/mydropbox ).
+ (NSURL*)appRootURL
{
    NSString *url = [NSString stringWithFormat:@"https://api.dropbox.com/1/metadata/dropbox/%@", appFolder];
    NSLog(@"listing files using url %@", url);
    return [NSURL URLWithString:url];
}

// next is a convenience method to generate the URL for method -done in NoteDetailsViewController class
+ (NSURL*)uploadURLForPath:(NSString*)path
{
    NSString *urlWithParams = [NSString stringWithFormat:@"https://api-content.dropbox.com/1/files_put/dropbox/%@/%@",
                               appFolder,
                               [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:urlWithParams];
    return url;
}

// this method creates a random file name; dropbox will handle it if we overwrite a file and create a new name
+ (NSURL *)createPhotoUploadURL
{
    NSString *urlWithParams = [NSString stringWithFormat:@"https://api-content.dropbox.com/1/files_put/dropbox/%@/photos/YOUR_DROPBOX_FOLDER_NAME_%i.jpg",appFolder,arc4random() % 1000];
    NSURL *url = [NSURL URLWithString:urlWithParams];
    return url;
}

@end
