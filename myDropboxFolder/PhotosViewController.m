//
//  PhotosViewController.m
//  myDropboxFolder
//
//  Created by Oleg Pochtovy on 04.08.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

// To view photos in this app you need to copy the "photos" directory to your app folder on Dropbox.

#import "PhotosViewController.h"
#import "PhotoCell.h"
#import "Dropbox.h"
#import "NoteFile.h"

@interface PhotosViewController () <UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, weak) IBOutlet UIProgressView *progress;
@property (nonatomic, weak) IBOutlet UIView *uploadView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *photoThumbnails;

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSURLSessionUploadTask *uploadTask;

@end

@implementation PhotosViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // 1
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        // 2
        [config setHTTPAdditionalHeaders:@{@"Authorization": [Dropbox apiAuthorizationHeader]}];
        
        // 3
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

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
    [self refreshPhotos];
}

- (void)refreshPhotos
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSString *photoDir = [NSString stringWithFormat:@"https://api.dropbox.com/1/search/dropbox/%@/photos?query=.jpg",appFolder]; // this means "the API call looks in the photos directory and only requests files with the .jpg extension"
    NSURL *url = [NSURL URLWithString:photoDir];
    
    [[_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            if (httpResp.statusCode == 200)
            {
                NSError *jsonError;
                NSArray *filesJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                NSLog(@"%@", filesJSON);
                NSMutableArray *noteFiles = [[NSMutableArray alloc] init];
                
                if (!jsonError) {
                    for (NSDictionary *fileMetadata in filesJSON) {
                        NoteFile *file = [[NoteFile alloc] initWithJSONData:fileMetadata];
                        [noteFiles addObject:file];
                    }
                    
                    [noteFiles sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                        return [obj1 compare:obj2];
                    }];
                    
                    _photoThumbnails = noteFiles;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                        [self.tableView reloadData];
                    });
                } else {
                    // HANDLE BAD RESPONSE //
                    UIAlertView *badResponseAlertView = [[UIAlertView alloc] initWithTitle:@"Unexpected Response Getting Photo Directory"
                                                                                              message:[jsonError localizedDescription]
                                                                                             delegate:nil
                                                                                    cancelButtonTitle:@"Ok"
                                                                                    otherButtonTitles:nil];
                    [badResponseAlertView show];
                }
            } else {
                // ALWAYS HANDLE ERRORS //
                UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error Getting Photo Directory"
                                                                         message:[error localizedDescription]
                                                                        delegate:nil
                                                               cancelButtonTitle:@"Ok"
                                                               otherButtonTitles:nil];
                [errorAlertView show];
            }
        }
    }] resume];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDatasource and UITableViewDelegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_photoThumbnails count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"PhotoCell";
    PhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NoteFile *photo = _photoThumbnails[indexPath.row];
    
    if (!photo.thumbNail) {
        // only download if we are moving
        if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
        {
            if (photo.thumbExists)
            {
                NSString *urlString = [NSString stringWithFormat:@"https://api-content.dropbox.com/1/thumbnails/dropbox%@?size=xl",photo.path];
                NSString *encodedUrl = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSURL *url = [NSURL URLWithString:encodedUrl];
                NSLog(@"Logging this url so no warning in starter project %@", url);
                
                // GO GET THUMBNAILS //
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                NSURLSessionDataTask *dataTask = [_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (!error)
                    {
                        UIImage *image = [[UIImage alloc] initWithData:data];
                        photo.thumbNail = image;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                            cell.thumbnailImage.image = photo.thumbNail;
                        });
                    } else {
                        // HANDLE ERROR //
                        UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error Getting Thumbnails"
                                                                                 message:[error localizedDescription]
                                                                                delegate:nil
                                                                       cancelButtonTitle:@"Ok"
                                                                       otherButtonTitles:nil];
                        [errorAlertView show];
                    }
                }];
                [dataTask resume];
            }
        }
    }
    
    return cell;
}

- (IBAction)choosePhoto:(UIBarButtonItem *)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate methods
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// When the user chooses a photo to upload, didFinishPickingMediaWithInfo calls uploadImage: to perform the file upload.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self uploadImage:image];
}

- (void)uploadImage:(UIImage *)image
{
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    
    // 1 - Previously, we used the session set up in initWithCoder and the associated convenience methods to create asynchronous tasks. This time, we’re using an NSURLSessionConfiguration that only permits one connection to the remote host, since our upload process handles just one file at a time.
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPMaximumConnectionsPerHost = 1;
    [config setHTTPAdditionalHeaders:@{@"Authorization": [Dropbox apiAuthorizationHeader]}];
    
    // 2 - The upload and download tasks report information back to their delegates
    NSURLSession *uploadSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    // for now just create a random file name, dropbox will handle it if we overwrite a file and create a new name
    NSURL *url = [Dropbox createPhotoUploadURL];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"PUT"];
    
    // 3 - Here we set the uploadTask property using the JPEG image obtained from the UIImagePicker.
    self.uploadTask = [uploadSession uploadTaskWithRequest:request fromData:imageData];
    
    // 4 - we display the UIProgressView hidden inside of PhotosViewController.
    self.uploadView.hidden = NO;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    // 5 - resume the task
    [_uploadTask resume];
}

- (IBAction)cancelUpload:(id)sender
{
    if (_uploadTask.state == NSURLSessionTaskStateRunning) {
        [_uploadTask cancel]; // to cancel a task it's easy as calling the cancel method
    }
}

// -> Now that the delegate has been set, we can implement the NSURLSessionTaskDelegate methods to update the progress view.

#pragma mark - NSURLSessionTaskDelegate methods

// This delegate method periodically reports information about the upload task back to the caller. It also updates UIProgressView (_progress) to show totalBytesSent / totalBytesExpectedToSend which is more informative (and much geekier) than showing percent complete.
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_progress setProgress:(double)totalBytesSent/(double)totalBytesExpectedToSend animated:YES];
    });
}

// this second delegate method indicates when the upload task is complete
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // 1
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        _uploadView.hidden = YES;
        [_progress setProgress:0.5];
    });
    
    if (!error) {
        // 2
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshPhotos];
        });
    } else {
        // ALERT FOR ERROR //
        UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error Completing Upload Task"
                                                                 message:[error localizedDescription]
                                                                delegate:nil
                                                       cancelButtonTitle:@"Ok"
                                                       otherButtonTitles:nil];
        [errorAlertView show];
    }
}

@end
