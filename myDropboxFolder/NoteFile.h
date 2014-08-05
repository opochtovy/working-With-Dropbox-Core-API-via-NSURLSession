//
//  NoteFile.h
//  myDropboxFolder
//
//  Created by Oleg Pochtovy on 01.08.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

// NoteFile is a helper class that pulls out the information for a file (note) from the JSON dictionary

#import <Foundation/Foundation.h>

typedef void(^ThumbnailCompletionBlock)();

@interface NoteFile : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *root;
@property (readwrite) BOOL thumbExists;
@property (nonatomic, strong) NSDate *modified;
@property (nonatomic, strong) NSString *contents;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) UIImage *thumbNail;

- (id)initWithJSONData:(NSDictionary *)data;

- (NSString *)fileNameShowExtension:(BOOL)showExtension;

@end
