//
//  NoteFile.m
//  myDropboxFolder
//
//  Created by Oleg Pochtovy on 01.08.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

// NoteFile is a helper class that pulls out the information for a file (note) from the JSON dictionary

#import "NoteFile.h"
#import "Dropbox.h"

typedef void(^NoteFileUpdateCompletionBlock)(NoteFile *updatedFile);

@implementation NoteFile

- (id)initWithJSONData:(NSDictionary *)data
{
    self = [super init];
    if (self) {
        self.path = data[@"path"];
        self.root = data[@"root"];
        self.thumbExists = [data[@"thumb_exists"] boolValue];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
        NSDate *date = [formatter dateFromString:data[@"modified"]];
        if (date) {
            self.modified = date;
        }
        self.mimeType = data[@"mime_type"];
    }
    return self;
}

- (NSString *)fileNameShowExtension:(BOOL)showExtension
{
    NSString *path = self.path;
    NSString *filePath = [[path componentsSeparatedByString:@"/"] lastObject];
    if (!showExtension) {
        filePath = [[filePath componentsSeparatedByString:@"."] firstObject];
    }
    return filePath;
}

// sort by level, then achievement points
- (NSComparisonResult)compare:(NoteFile *)other
{
    NSComparisonResult order;
    
    // first compare modified
    order = [other.modified compare:self.modified];
    
    // if same modified alpha by path
    if (order == NSOrderedSame) {
        order = [other.path compare:self.path];
    }
    return order;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"File from %@ %@", self.root, self.path];
}

@end
