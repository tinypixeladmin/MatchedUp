//
//  TPXLoginViewController.m
//  MatchedUp
//
//  Created by pixelhacker on 1/14/14.
//  Copyright (c) 2014 tinypixel. All rights reserved.
//

#import "TPXLoginViewController.h"

@interface TPXLoginViewController ()
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSMutableData *imageData;

@end

@implementation TPXLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.activityIndicator.hidden = YES;
	// Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated{
    if([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]){
        [self updateUserInfo];
        
        [self performSegueWithIdentifier:@"loginToTabBarSegue" sender:self];
    }
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions
- (IBAction)loginFBBtnPressed:(UIButton *)sender {
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    NSArray *permissionsArray = @[@"user_about_me", @"user_interests", @"user_relationships", @"user_birthday", @"user_location", @"user_relationship_details"];
    
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        [self.activityIndicator stopAnimating];
        self.activityIndicator.hidden = YES;
        
        if(!user){
            
            
            
            if(!error){
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"The Facebook Login was cancelled" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                
                [alertView show];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[error description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            }
        } else {
            [self updateUserInfo];
            [self performSegueWithIdentifier:@"loginToTabBarSegue" sender:self];
            
            
        }
    }];
}

#pragma mark - Helper Method
-(void) updateUserInfo{
    FBRequest *req = [FBRequest requestForMe];
    
    [req startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error){
            NSDictionary *userDict = (NSDictionary *)result;
            NSMutableDictionary *userProfile = [[NSMutableDictionary alloc] initWithCapacity:8];
            
            //create URL
            NSString *facebookID = userDict[@"id"];
            NSURL *photoURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            
            
            if(userDict[@"name"]){
                userProfile[kTPXUserProfileNameKey] = userDict[@"name"];
            }
            
            if(userDict[@"first_name"]){
                userProfile[kTPXUserProfileFirstNameKey] = userDict[@"first_name"];
            }
            
            if(userDict[@"location"][@"name"]){
                userProfile[kTPXUserProfileLocationKey] = userDict[@"location"][@"name"];
            }
            
            if(userDict[@"gender"]){
                userProfile[kTPXUserProfileGenderKey] = userDict[@"gender"];
            }
            
            if(userDict[@"birthday"]){
                userProfile[kTPXUserProfileBirthdayKey] = userDict[@"birthday"];
            }
            
            if(userDict[@"interested_in"]){
                userProfile[kTPXUserProfileInterestedInKey] = userDict[@"interested_in"];
            }
            
            if([photoURL absoluteString]){
                userProfile[kTPXUserProfilePictureURL] = [photoURL absoluteString];
                
            }
            
            [[PFUser currentUser] setObject:userProfile forKey:kTPXUserProfileKey];
            [[PFUser currentUser] saveInBackground];
        
            [self requestImage];
        } else {
            NSLog(@"Error in FB Request %@", error);
        }
    }];
}


-(void)uploadPFFileToParse:(UIImage *)image{
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    
    if(!imageData) return;
    
    PFFile *photoFile = [PFFile fileWithData:imageData];
    
    [photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(succeeded){
            PFObject *photo = [PFObject objectWithClassName:kTPXPhotoClassKey];
            [photo setObject:[PFUser currentUser] forKey:kTPXPhotoUserKey];
            [photo setObject:photoFile forKey:kTPXPhotoPictureKey];
            [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                NSLog(@"Photo saved successfully");
            }];
        }
    }];
}


-(void)requestImage{
    PFQuery *query = [PFQuery queryWithClassName:kTPXPhotoClassKey];
    [query whereKey:kTPXPhotoUserKey equalTo:[PFUser currentUser]];
    
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if(number == 0){
            PFUser *user = [PFUser currentUser];
            self.imageData = [[NSMutableData alloc] init];
            
            NSURL *profilePictureURL = [NSURL URLWithString:user[kTPXUserProfileKey][kTPXUserProfilePictureURL]];
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:profilePictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:4.0];
            NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
            
            if(!urlConnection){
                NSLog(@"Failed to download photo");
            }
        }
    }];
}


#pragma mark - NSURLDataDelegation
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.imageData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    UIImage *profileImage = [UIImage imageWithData:self.imageData];
    [self uploadPFFileToParse:profileImage];
}







@end
