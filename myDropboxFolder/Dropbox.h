//
//  Dropbox.h
//  myDropboxFolder
//
//  Created by Oleg Pochtovy on 31.07.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

// This clas is a small API that handles most of preparation work before using the Dropbox API that we need to authenticate the user.

#import <Foundation/Foundation.h>

// OAuth Stuff
extern NSString * const oauthTokenKey;
extern NSString * const oauthTokenKeySecret;
extern NSString * const requestToken;
extern NSString * const requestTokenSecret;
extern NSString * const accessToken;
extern NSString * const accessTokenSecret;
extern NSString * const dropboxUIDKey;
extern NSString * const dropboxTokenReceivedNotification;

// App settings
extern NSString * const appFolder;

typedef void (^DropboxRequestTokenCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);

@interface Dropbox : NSObject

// oauth
+ (void)requestTokenWithCompletionHandler:(DropboxRequestTokenCompletionHandler)completionBlock; // this class method obtains an OAuth request token to be used for the rest of the authentication process
+ (void)exchangeTokenForUserAccessTokenURLWithCompletionHandler:(DropboxRequestTokenCompletionHandler)completionBlock; // this class method calls a web service to exchange the temporary request token (from +requestTokenWithCompletionHandler:) for a permanent access token, which is stored in the app.
+ (NSString*)apiAuthorizationHeader; // this helper method returns a string, in the OAuth specification format. This string contains the access token, token secret and our Dropbox App API key. Remember, this is necessary because every call to the Dropbox API needs to be authenticated.

// helpers
+ (NSDictionary*)dictionaryFromOAuthResponseString:(NSString*)response; // method to get dictionary to save necessary fields ("requestToken" and "requestTokenSecret" in method getOAuthRequestToken, "accessToken" and "accessTokenSecret" in method exchangeRequestTokenForAccessToken)

// next is a convenience method to generate the URL for method -notesOnDropbox in NotesViewController class (in Dropbox, we can see the contents of a folder by making an authenticated GET request to a particular URL – like https://api.dropbox.com/1/metadata/dropbox/mydropbox ).
+ (NSURL*)appRootURL;

// next is a convenience method to generate the URL for method -done in NoteDetailsViewController class
+ (NSURL*)uploadURLForPath:(NSString*)path;

// this method creates a random file name; dropbox will handle it if we overwrite a file and create a new name
+ (NSURL*)createPhotoUploadURL;
@end
