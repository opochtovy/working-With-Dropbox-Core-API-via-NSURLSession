//
//  PhotoCell.h
//  myDropboxFolder
//
//  Created by Oleg Pochtovy on 04.08.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *thumbnailImage;
@property (nonatomic, strong) IBOutlet UILabel *fileName;

@end
