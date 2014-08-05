//
//  NoteDetailsViewController.m
//  myDropboxFolder
//
//  Created by Oleg Pochtovy on 03.08.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

// the goal of this class NoteDetailsViewController is to create or edit file inside the app’s Dropbox folder

#import "NoteDetailsViewController.h"
#import "Dropbox.h"
#import "NoteFile.h"

@interface NoteDetailsViewController ()

@property (nonatomic, weak) IBOutlet UITextField *filename;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, weak) IBOutlet UITextView *textView;

@end

@implementation NoteDetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view
    
    if (self.note) {
        self.filename.text = [[_note fileNameShowExtension:YES] lowercaseString];
        [self retreiveNoteText];
    }
}

// Here we create second networking task (POST Notes through the Dropbox API)
- (void)retreiveNoteText
{
    // 1 - Set the request path and the URL of the file we wish to retrieve; the /files endpoint in the Dropbox API will return the contents of a specific file.
    NSString *fileApi = @"https://api-content.dropbox.com/1/files/dropbox";
    NSString *escapedPath = [_note.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", fileApi, escapedPath];
    
    NSURL *url = [NSURL URLWithString:urlStr];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // 2 - Create the data task with a URL that points to the file of interest. This call should be starting to look quite familiar as we go through this app.
    [[_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            if (httpResp.statusCode == 200) {
                
                // 3 - If our response code indicates that all is good, set up the textView on the main thread with the file contents we retrieved in the previous step. Remember, UI updates must be dispatched to the main thread.
                NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    self.textView.text = text;
                });
                
            } else {
                // HANDLE BAD RESPONSE //
                UIAlertView *badResponseAlertView = [[UIAlertView alloc] initWithTitle:@"POST Note Request Unexpected Response"
                                                                               message:[NSHTTPURLResponse localizedStringForStatusCode:httpResp.statusCode]
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"Ok"
                                                                     otherButtonTitles:nil];
                [badResponseAlertView show];
            }
        } else {
            // ALWAYS HANDLE ERRORS //
            UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error Posting Note"
                                                                     message:[error localizedDescription]
                                                                    delegate:nil
                                                           cancelButtonTitle:@"Ok"
                                                           otherButtonTitles:nil];
            [errorAlertView show];
        }
        // 4 - As soon as the task is initialized, call resume.
    }] resume];
}

#pragma mark - send messages to delegate

- (IBAction)done:(id)sender
{
    // must contain text in textview
    if (![_textView.text isEqualToString:@""]) {
        
        // check to see if we are adding a new note
        if (!self.note) {
            NoteFile *newNote = [[NoteFile alloc] init];
            newNote.root = @"dropbox";
            self.note = newNote;
        }
        
        _note.contents = _textView.text;
        _note.path = _filename.text;
        
        // old code
        //        // - UPLOAD FILE TO DROPBOX - //
        //        [self.delegate noteDetailsViewControllerDoneWithDetails:self];
        
        // new code implements everything we need to save and share our notes
        
        // 1 - To upload a file to Dropbox, again we need to use a certain API URL. Just like before when we needed a URL to list the files in a directory a helper method generates the URL for us.
        NSURL *url = [Dropbox uploadURLForPath:_note.path];
        // "path": "/mydropbox/test.txt"
        
        // 2 - NSMutableURLRequest. The new APIs can use both plain URLs and NSURLRequest objects, but we need the mutable form here to comply with the Dropbox API wanting this request to be a PUT request. Setting the HTTP method as PUT signals Dropbox that we want to create a new file.
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"PUT"];
        
        // 3 - Next we encode the text from our UITextView into an NSData Object.
        NSData *noteContents = [_note.contents dataUsingEncoding:NSUTF8StringEncoding];
        
        // 4 - Now that we’re created the request and NSData object, we next create an NSURLSessionUploadTask and set up the completion handler block. Upon success, we call the delegate method noteDetailsViewControllerDoneWithDetails: to close the modal content. In a production-level application we could pass a new NoteFile back to the delegate and sync up our persistent data. For the purposes of this application, we simply refresh the NotesViewController with a new network call.
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromData:noteContents completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            
            if (!error && httpResp.statusCode == 200) {
                [self.delegate noteDetailsViewControllerDoneWithDetails:self];
            } else {
                // alert for error saving / updating note
                UIAlertView *noteSavingErrorAlert = [[UIAlertView alloc] initWithTitle:@"No text"
                                                                      message:[error localizedDescription]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"Ok"
                                                            otherButtonTitles:nil];
                [noteSavingErrorAlert show];
            }
        }];
        
        // 5 - Again, all tasks are created as suspended so we must call resume on them to start them up.
        [uploadTask resume];
        
    } else {
        UIAlertView *noTextAlert = [[UIAlertView alloc] initWithTitle:@"No text"
                                                              message:@"Need to enter text"
                                                             delegate:nil
                                                    cancelButtonTitle:@"Ok"
                                                    otherButtonTitles:nil];
        [noTextAlert show];
    }
}

- (IBAction)cancel:(id)sender
{
    [self.delegate noteDetailsViewControllerDidCancel:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
