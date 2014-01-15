//
//  TPXSecondViewController.m
//  MatchedUp
//
//  Created by pixelhacker on 1/14/14.
//  Copyright (c) 2014 tinypixel. All rights reserved.
//

#import "TPXSecondViewController.h"

@interface TPXSecondViewController ()

@end

@implementation TPXSecondViewController

- (void)viewDidLoad{
    [super viewDidLoad];

    PFQuery *query = [PFQuery queryWithClassName:kTPXPhotoClassKey];
    [query whereKey:kTPXPhotoUserKey equalTo:[PFUser currentUser]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if([objects count] > 0){
            PFObject *photo = objects[0];
            PFFile *pictureFile = photo[kTPXPhotoPictureKey];
            [pictureFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                self.profileImageView.image = [UIImage imageWithData:data];
            }];
        }
        
        
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
