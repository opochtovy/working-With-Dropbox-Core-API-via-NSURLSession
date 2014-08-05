//
//  NotesViewController.m
//  myDropboxFolder
//
//  Created by Oleg Pochtovy on 01.08.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

// the goal of this class NoteViewController is to retrieve a list of the files inside the app’s Dropbox folder
// NoteViewController is set as the NoteDetailsViewController’s delegate. This way, the NoteDetailsViewController can notify NoteViewController when the user finishes editing a note, or cancels editing a note.

#import "NotesViewController.h"
#import "NoteFile.h"
#import "NoteDetailsViewController.h"
#import "Dropbox.h"

@interface NotesViewController () <NoteDetailsViewControllerDelegate>

@property (nonatomic, strong) NSArray *notes;

// Creating an NSURLSession for our personal tasks - 1 step
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation NotesViewController

// Creating an NSURLSession for our personal tasks - 2 step
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        // our app calls initWithCoder when instantiating a view controller from a Storyboard; therefore this is the perfect spot to initialize and create the NSURLSession. We don’t want aggressive caching or persistence here, so we use the ephemeralSessionConfiguration convenience method, which returns a session with no persistent storage for caches, cookies, or credentials. This is a “private browsing” configuration.
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        // Next, we add the Authorization HTTP header to the configuration object which contains the access token, token secret and our Dropbox App API key. Remember, this is necessary because every call to the Dropbox API needs to be authenticated.
        [config setHTTPAdditionalHeaders:@{@"Authorization": [Dropbox apiAuthorizationHeader]}];
        
        // Finally, we create the NSURLSession using the above configuration.
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}
// Creating an NSURLSession for our personal tasks - end of 2 step

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
    [self notesOnDropbox]; // GET Notes through the Dropbox API - the goal of this method is to retrieve a list of the files inside the app’s Dropbox folder
}

// Here we create first networking task (GET Notes through the Dropbox API) - this method lists files found in the root dir of appFolder (mydropbox)
- (void)notesOnDropbox
{
    // 1 - In Dropbox, we can see the contents of a folder by making an authenticated GET request to a particular URL – like https://api.dropbox.com/1/metadata/dropbox/byteclub.
    NSURL *url = [Dropbox appRootURL];
    
    // 2 - NSURLSession has convenience methods to easily create various types of tasks. Here we are creating a data task in order to perform a GET request to that URL. When the request completes, our completionHandler block is called.
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            // here goes the code to parse the results after a GET request started
            
            // 2.1 - we made a HTTP request, so the response will be a HTTP response. So here we cast the NSURLResponse to an NSHTTPURLRequest response so we can access to the statusCode property. If we receive an HTTP status code of 200 then all is well.
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            if (httpResp.statusCode == 200) {
                
                NSError *jsonError;
                
                // 2.2 - The Dropbox API returns its data as JSON. So if we received a 200 response, then convert the data into JSON using iOS’s built in JSON deserialization.
                NSDictionary *notesJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                
                NSMutableArray *notesFound = [[NSMutableArray alloc] init];
                
                if (!jsonError) {
                    // So the last bit of code to add is the code that pulls out the parts we’re interested in from the JSON. In particular, we want to loop through the “contents” array for anything where “is_dir” is set to false.
                    
                    // 2.2.1 - We pull out the array of objects from the “contents” key and then iterate through the array. Each array entry is a file, so we create a corresponding NoteFile model object for each file.
                    // NoteFile is a helper class that pulls out the information for a file from the JSON dictionary.
                    // When we’re done, we add all the notes into the self.notes property. The table view is set up to display any entries in this array.
                    NSArray *contentsOfRootDirectory = notesJSON[@"contents"];
                    
                    for (NSDictionary *data in contentsOfRootDirectory) {
                        if (![data[@"is_dir"] boolValue]) {
                            NoteFile *note = [[NoteFile alloc] initWithJSONData:data];
                            [notesFound addObject:note];
                        }
                    }
                    
                    [notesFound sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                        return [obj1 compare:obj2];
                    }];
                    
                    self.notes = notesFound;
                    
                    // 2.2.2 - Now that we have the table view’s datasource updated, we need to reload the table data. Whenever we’re dealing with asynchronous network calls, we have to make sure to update UIKit on the main thread.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        [self.tableView reloadData];
                    });
                } else {
                    // HANDLE JSON Serialization Error //
                    UIAlertView *JSONSerializationErrorAlertView = [[UIAlertView alloc] initWithTitle:@"Unexpected Response during JSON Serialization"
                                                                                   message:[jsonError localizedDescription]
                                                                                  delegate:nil
                                                                         cancelButtonTitle:@"Ok"
                                                                         otherButtonTitles:nil];
                    [JSONSerializationErrorAlertView show];
                }
            }
        } else {
            // ALWAYS HANDLE ERRORS :-] //
            UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error Getting Request"
                                                                     message:[error localizedDescription]
                                                                    delegate:nil
                                                           cancelButtonTitle:@"Ok"
                                                           otherButtonTitles:nil];
            [errorAlertView show];
        }
    }];
    
    // 3 - a task defaults to a suspended state, so we need to call the resume method to start it running.
    [dataTask resume];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _notes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"NoteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    NoteFile *note = _notes[indexPath.row];
    cell.textLabel.text = [[note fileNameShowExtension:YES]lowercaseString];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *navigationController = segue.destinationViewController;
    NoteDetailsViewController *showNote = (NoteDetailsViewController *)[navigationController viewControllers][0];
    showNote.delegate = self;
    showNote.session = _session; // Now the detail view controller will share the same NSURLSession, so the detail view controller can use it to make API calls to DropBox.
    
    if ([segue.identifier isEqualToString:@"editNote"]) {
        
        // pass selected note to be edited //
        if ([segue.identifier isEqualToString:@"editNote"]) {
            NoteFile *note = _notes[[self.tableView indexPathForSelectedRow].row];
            showNote.note = note;
        }
    }
}

#pragma mark - NoteDetailsViewController Delegate methods

- (void)noteDetailsViewControllerDoneWithDetails:(NoteDetailsViewController *)controller
{
    // refresh to get latest
    [self dismissViewControllerAnimated:YES completion:nil];
    [self notesOnDropbox];
}

- (void)noteDetailsViewControllerDidCancel:(NoteDetailsViewController *)controller
{
    // just close modal VC
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
