//
//  NoteDetailsViewController.h
//  myDropboxFolder
//
//  Created by Oleg Pochtovy on 03.08.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

// the goal of this class NoteDetailsViewController is to create or edit file inside the app’s Dropbox folder

#import <UIKit/UIKit.h>

@class NoteDetailsViewController;
@class NoteFile;

@protocol NoteDetailsViewControllerDelegate <NSObject>

- (void)noteDetailsViewControllerDidCancel:(NoteDetailsViewController *)controller;
- (void)noteDetailsViewControllerDoneWithDetails:(NoteDetailsViewController *)controller;

@end

@interface NoteDetailsViewController : UITableViewController

@property (nonatomic, weak) id <NoteDetailsViewControllerDelegate> delegate;
@property (nonatomic, strong) NoteFile *note;
@property (nonatomic, strong) NSURLSession *session;

@end
