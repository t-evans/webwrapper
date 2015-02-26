//
//  TableViewCell.h
//  WebWrapper
//
//  Created by Troy Evans on 12/30/13.
//  Copyright (c) 2013 Nutrislice. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *icon;
@property (weak, nonatomic) IBOutlet UIImageView *image;

@end
