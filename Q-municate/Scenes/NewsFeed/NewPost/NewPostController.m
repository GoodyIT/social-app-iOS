//
//  NewPostController.m
//  reach-ios
//
//  Created by Admin on 2016-12-08.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "NewPostController.h"
#import "UIPlaceholderTextView.h"
#import "UIColor+CustomColors.h"
#import "PopUpViewController.h"
#import "NSString+Validation.h"
#import "UIImage+Base64.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "QMAlert.h"

@import AVKit;

@interface NewPostController ()<UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate>
{
    BOOL _videoUploaded;
    BOOL _photoUploaded;
    CGFloat originalY;
}

@property (weak, nonatomic) IBOutlet UIButton *shareBtn;
@property (weak, nonatomic) IBOutlet UIPlaceholderTextView *mainTextView;
@property (weak, nonatomic) IBOutlet UIPlaceholderTextView *tagTextView;
@property (weak, nonatomic) IBOutlet UIImageView *uploadedImageView;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoBtn;
@property (weak, nonatomic) IBOutlet UIButton *addVideoBtn;

@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) UIImagePickerController *videoPicker;
@property (strong, nonatomic) AVPlayerViewController *playerViewController;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) id notificationToken;

@property (strong, nonatomic) NSURL *videoFilePath;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *shareBtnBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *innerViewTopConstraint;

@property (strong, nonatomic) BFTask* task;
@end

@implementation NewPostController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.videoFilePath = nil;
    
    [self prepareUI];
    if (self.post != nil) {
        [self updateUI];
    }
    [self addTapGesture];
    [self prepareAccessoryView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.view.backgroundColor = [UIColor colorWithHexString:@"EBEBF1"];
    [self addKeyboardObservers];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self.view endEditing:YES];
    [super viewWillDisappear:animated];
    [self.player pause];
    [self removeKeyboardObservers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Keyboard

- (void)addKeyboardObservers{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeKeyboardObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification*) notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    if (keyboardSize.height != 0.0f)
    {
        if (self.mainTextView.isFirstResponder) {
            self.innerViewTopConstraint.constant = -keyboardSize.height*2/3-25;
            self.shareBtnBottomConstraint.constant = keyboardSize.height*2/3+25;
        } else {
            self.innerViewTopConstraint.constant = -keyboardSize.height-25;
            self.shareBtnBottomConstraint.constant = keyboardSize.height+25;
        }
        
        [self.view layoutIfNeeded];
    }
}

- (void)keyboardWillHide:(NSNotification*) notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    if (keyboardSize.height != 0.0f)
    {
        self.shareBtnBottomConstraint.constant = 0;
        self.innerViewTopConstraint.constant = 0;
    }
}

- (void) updateUI
{
    self.title = @"Edit Post";
    self.mainTextView.text = self.post.text;
    NSString* str = @"";
    for (HashtagModel* hastagModel in self.post.hashtags) {

       str =  [str stringByAppendingString:hastagModel.hashtagText];
    }
    str = [str stringByReplacingOccurrencesOfString:@"#" withString:@" "];
    self.tagTextView.text = str;
    
    if (![self.post.video isKindOfClass:[NSNull class]]) {
        self.videoFilePath = [NSURL URLWithString:self.post.video];
        _videoUploaded = YES;
        [self playVideo];
    } else {
        _photoUploaded = YES;
        [self.uploadedImageView sd_setImageWithURL:[NSURL URLWithString:self.post.image] placeholderImage:[UIImage imageNamed:@"profile_back"]];
    }
}

- (void) prepareUI
{
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 13, 23)];
    [backButton setBackgroundImage:[UIImage imageNamed:@"Back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(dismissScreen) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    [self.navigationItem setLeftBarButtonItems:@[backButtonItem] animated:YES];
    
    self.shareBtn.layer.cornerRadius = 5;
    self.shareBtn.clipsToBounds = YES;
    
    
    self.mainTextView.placeholder = @"Describe your current issue";
    self.tagTextView.placeholder = @"Enter hashtags here and separate by a space. No need to put # symbol";
    self.mainTextView.placeholderColor = [UIColor cccGreyColor];
    self.tagTextView.placeholderColor = [UIColor cccGreyColor];
    
    self.mainTextView.layer.borderColor = [[UIColor cccGreyColor] CGColor];
    self.mainTextView.layer.borderWidth = 2;
    self.mainTextView.layer.cornerRadius = 5;
    self.mainTextView.clipsToBounds = YES;
    
    self.tagTextView.layer.borderColor = [[UIColor cccGreyColor] CGColor];
    self.tagTextView.layer.borderWidth = 2;
    self.tagTextView.layer.cornerRadius = 5;
    self.tagTextView.clipsToBounds = YES;
    
    self.tagTextView.keyboardType = UIKeyboardTypeTwitter;
    
    self.playerViewController = [[AVPlayerViewController alloc] init];
    _player = [[AVPlayer alloc] init];
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    _photoUploaded = NO;
    _videoUploaded = NO;
    
    originalY = self.view.frame.origin.y;
    
    @weakify(self)
    // adding notification for showing chat connection
    [[NSNotificationCenter defaultCenter]
                                        addObserverForName:UIApplicationDidEnterBackgroundNotification
                                        object:nil
                                        queue:nil
                                        usingBlock:^(NSNotification * _Nonnull __unused note) {
                                            
                                            @strongify(self);
                                            [self.view endEditing:YES];
                                        }];
}

- (void)prepareAccessoryView {
    UIToolbar *accessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetMaxX(self.view.frame), 50)];
    accessoryView.barTintColor = [UIColor groupTableViewBackgroundColor];
    accessoryView.tintColor = [UIColor skyBlueColor];

    accessoryView.items = @[
                            [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(handleTap)]];
    [accessoryView sizeToFit];
    self.mainTextView.inputAccessoryView = accessoryView;
    self.tagTextView.inputAccessoryView = accessoryView;
}

- (void)addTapGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self.view addGestureRecognizer:tap];
}

- (void)handleTap {
    [self.view endEditing:YES];
}

- (void) dismissScreen
{
    [self.view endEditing:YES];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)playVideo {
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:self.videoFilePath];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset: asset];
    
    [self.player replaceCurrentItemWithPlayerItem:item];
    
    self.playerViewController = [[AVPlayerViewController alloc] init];
    self.playerViewController.player = self.player;
    self.playerViewController.showsPlaybackControls = NO;
    [self.playerViewController.view setFrame:CGRectMake(0, 0, self.uploadedImageView.bounds.size.width, self.uploadedImageView.bounds.size.height)];
    
    [self.uploadedImageView addSubview:self.playerViewController.view];
    
    @weakify(self);
    self.notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification)
                              {
                                  AVPlayerItem *playerItem = [notification object];
                                  [playerItem seekToTime:kCMTimeZero];
                                  @strongify(self);
                                  [self.player play];
                              }];
    [self.player play];
}

- (IBAction)addPhoto:(id) __unused sender {
    [self.view endEditing:YES];
    [self.player pause];
    @weakify(self);
    
    self.imagePicker.finalizationBlock = ^(UIImagePickerController __unused  *picker, NSDictionary *info) {
        @strongify(self);
        //Your implementation here
        UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
        if (self.player.status == AVPlayerStatusReadyToPlay){
            [self.playerViewController.view removeFromSuperview];
        }
        self.uploadedImageView.image = image;
        self->_photoUploaded = YES;
        self->_videoUploaded = NO;
        
        [self dismissViewControllerAnimated:YES completion:nil];        
    };
    
    self.imagePicker.cancellationBlock = ^(UIImagePickerController  __unused *picker)
    {
        @strongify(self);
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    
    self.imagePicker.cancellationBlock = ^(UIImagePickerController __unused  *picker) {
        @strongify(self);
        [self.player play];
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Add Picture" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *chooseExisting = [UIAlertAction actionWithTitle:@"Choose Existing Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull  __unused action) {
        @strongify(self);
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:self.imagePicker animated:YES completion:nil];
    }];
    
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull  __unused action) {
        @strongify(self);
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:self.imagePicker animated:YES completion:nil];
    }];
    
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull  __unused action) {
        [self.player play];
    }];
    
    [alertController addAction:chooseExisting];
    [alertController addAction:takePhoto];
    [alertController addAction:cancel];
   
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [alertController setModalPresentationStyle:UIModalPresentationPopover];
        
        UIPopoverPresentationController *popPresenter = [alertController
                                                         popoverPresentationController];
        popPresenter.sourceView = self.addPhotoBtn;
        popPresenter.sourceRect = self.addPhotoBtn.bounds;
        popPresenter.permittedArrowDirections = UIPopoverArrowDirectionUp;
    }

    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)addVideo:(id) __unused sender {
    [self.player pause];
    @weakify(self);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Add Video" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *chooseExistingVideo = [UIAlertAction actionWithTitle:@"Choose Existing Video" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull __unused  action) {
        @strongify(self);
        
        /*
         Show the image picker controller as a popover (iPad) or as a modal view controller
         (iPhone and iPhone 6 plus).
         */
        
        
        [self presentViewController:[self _videoPicker] animated:YES completion:nil];
    }];
    
    UIAlertAction *takeVideo = [UIAlertAction actionWithTitle:@"Take Video" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull __unused  action) {
        // camera view show
        @strongify(self);
        [self startCameraControllerFromViewController:self usingDelegate:self];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull __unused  action) {
        //[weakSelf dismissViewControllerAnimated:YES completion:nil];
         [self.player play];
    }];
    
    [alertController addAction:chooseExistingVideo];
    [alertController addAction:takeVideo];
    [alertController addAction:cancel];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [alertController setModalPresentationStyle:UIModalPresentationPopover];
        
        UIPopoverPresentationController *popPresenter = [alertController
                                                         popoverPresentationController];
        popPresenter.sourceView = self.addVideoBtn;
        popPresenter.sourceRect = self.addVideoBtn.bounds;
        popPresenter.permittedArrowDirections = UIPopoverArrowDirectionUp;
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - record play video actions
-(BOOL)startCameraControllerFromViewController:(UIViewController*)controller
                                 usingDelegate:(id )delegate {
    // 1 - Validattions
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO)
        || (delegate == nil)
        || (controller == nil)) {
        return NO;
    }
    // 2 - Get image picker
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    // Displays a control that allows the user to choose movie capture
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
    cameraUI.edgesForExtendedLayout = UIRectEdgeNone;
    cameraUI.videoQuality = UIImagePickerControllerQualityTypeHigh;
    cameraUI.modalPresentationStyle = UIModalPresentationPopover;
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    cameraUI.allowsEditing = NO;
    @weakify(self);
    cameraUI.cancellationBlock = ^(UIImagePickerController* picker)
    {
        [picker dismissViewControllerAnimated:YES completion:nil];
    };
    cameraUI.finalizationBlock = ^(UIImagePickerController* __unused  picker, NSDictionary* info){
        @strongify(self);
        NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
        [self dismissViewControllerAnimated:NO completion:nil];
        // Handle a movie capture
        if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
            self.videoFilePath = [info objectForKey:UIImagePickerControllerMediaURL];
            NSString *moviePath = (NSString *)[self.videoFilePath absoluteString];
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(moviePath)) {
                UISaveVideoAtPathToSavedPhotosAlbum(moviePath, self,
                                                    @selector(video:didFinishSavingWithError:contextInfo:), nil);
            }
            [self playVideo];
            self->_photoUploaded = NO;
            self->_videoUploaded = YES;
        }
    };
  //  cameraUI.delegate = delegate;
    // 3 - Display image picker
    [controller presentViewController:cameraUI animated:YES completion:nil];
    return YES;
}

-(void)video:(NSString*) __unused videoPath didFinishSavingWithError:(NSError*)__unused error contextInfo:(void*) __unused contextInfo {

}

#pragma mark Image Picker Controller Delegate

- (void)imagePickerController:(UIImagePickerController *) __unused picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.videoFilePath = info[UIImagePickerControllerMediaURL];
    [self playVideo];
    self->_photoUploaded = NO;
    self->_videoUploaded = YES;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *) __unused picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Make sure playback is resumed from any interruption.
    [self.player play];
}

- (IBAction)sharePost:(id) __unused sender {
    [self.view endEditing:YES];
    if(!_photoUploaded && !_videoUploaded)
    {
        [QMAlert showAlertWithMessage:@"Please, upload a video or a photo." actionSuccess:NO inViewController:self];
        return;
    }
    
    if ([self.mainTextView.text isEmptyOrWhiteSpace]) {
        [QMAlert showAlertWithMessage:@"Please, describe your current issue!" actionSuccess:NO inViewController:self];
        return;
    }

    if(self.tagTextView.text.length > 200){
        [QMAlert showAlertWithMessage:@"The length of hashtags could not be more then 200 symbols." actionSuccess:NO inViewController:self];
        return;
    }
    
    [self performSegueWithIdentifier:kPostPublishType sender:nil];

}

- (UIImagePickerController* ) _videoPicker {
    if (self.videoPicker == nil){
        self.videoPicker = [[UIImagePickerController alloc] init];
    }
    
    self.videoPicker.edgesForExtendedLayout = UIRectEdgeNone;
 //   self.videoPicker.modalPresentationStyle = UIModalPresentationPopover;
    self.videoPicker.delegate = self;
    // Initialize UIImagePickerController to select a movie from the camera roll.
    self.videoPicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    self.videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie];
    
    return self.videoPicker;
}

- (UIImagePickerController *)imagePicker {
    if (_imagePicker == nil) {
        _imagePicker = [[UIImagePickerController alloc] init];
    }
    
    _imagePicker.allowsEditing = YES;
    _imagePicker.cropMode = DZNPhotoEditorViewControllerCropModeCustom;
    CGSize newRectSize = CGSizeMake(self.view.frame.size.width, 300);
    _imagePicker.cropSize = newRectSize;

    return _imagePicker;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id) __unused sender {
    @weakify(self);
   
    if ([segue.identifier isEqualToString:kPostPublishType]) {
        self.view.backgroundColor = [UIColor colorWithHexString:@"FFFFFF" withAlpha:0.6];
        PopUpViewController *popUpViewController = segue.destinationViewController;
        popUpViewController.commentText = self.mainTextView.text;
        popUpViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        popUpViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        popUpViewController.typeChoosedCallback = ^(NSNumber *isPublic) {
            @strongify(self);
            [self performRequestWithPermission:isPublic];
        };
    }
}

- (void)performRequestWithPermission:(NSNumber *)permission {

    [SVProgressHUD show];
    [self.view endEditing:YES];
    
    NSString *choosedImage = (self.uploadedImageView.image == nil) ? @"" : [self.uploadedImageView.image encodeToBase64String];
    NSString *video = @"";
    if(self.videoFilePath != nil) {
        NSData* assetData = [NSData dataWithContentsOfURL:self.videoFilePath];
        video = [assetData base64EncodedStringWithOptions:0];
    }

    NSCharacterSet *chs = [NSCharacterSet characterSetWithCharactersInString:@"#$&!.,^%)(*"];
    NSString *resultString = [[self.tagTextView.text componentsSeparatedByCharactersInSet:chs] componentsJoinedByString:@""];
    resultString = [resultString stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceCharacterSet]];
    NSMutableCharacterSet* mutableCharacterSet = [[NSCharacterSet whitespaceCharacterSet] mutableCopy];
    [mutableCharacterSet formUnionWithCharacterSet:[NSCharacterSet newlineCharacterSet]];
    NSArray *array = [resultString componentsSeparatedByCharactersInSet:mutableCharacterSet];
    array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
    NSString *hashtagsString = @"";
    for (NSString* _tag in array) {
       hashtagsString = [[[hashtagsString stringByAppendingString:@"#"] stringByAppendingString:_tag] stringByAppendingString:@" "];
    }
//    NSString *hashtagsString =[resultString stringByReplacingOccurrencesOfString:@" " withString:@" #"];
    
//    hashtagsString =[resultString stringByReplacingOccurrencesOfString:@"# " withString:@""];
//    hashtagsString = [hashtagsString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
//    hashtagsString = [NSString stringWithFormat:@"#%@ ", hashtagsString];
    NSArray* hastagArray = [hashtagsString componentsSeparatedByString:@"#####"];
    
    if (self.post != nil)
    {
        [self updatePostWithHashTag:hastagArray image:choosedImage video:video permission:permission];
    } else {
        [self createNewPostWithHashtags:hastagArray image:choosedImage video:video permission:permission];
    }
}

- (void) createNewPostWithHashtags: (NSArray*) hastagArray image:(NSString*)choosedImage video:(NSString*)video permission:(NSNumber*)permission
{
    if (_photoUploaded) {
        video = @"";
    } else {
        choosedImage = @"";
    }
    @weakify(self);
    self.task = [[[QMNetworkManager sharedManager] addNewPostWithText:self.mainTextView.text image:choosedImage hashtags: hastagArray permission:permission video:video] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        [SVProgressHUD dismiss];
        @strongify(self)
        if(self == nil) return nil;
        if (!serverTask.isFaulted) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPost" object:nil];
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
        }
        
        return nil;
    }];
}

- (void) updatePostWithHashTag: (NSArray*) hastagArray image:(NSString*)choosedImage video:(NSString*)video permission:(NSNumber*)permission
{
    if (_photoUploaded) {
        video = @"";
    } else {
        choosedImage = @"";
    }
    @weakify(self);
    [[[QMNetworkManager sharedManager] editPostWithText:self.mainTextView.text image:choosedImage hashtags:hastagArray permission:permission video:video postID:self.post.postID] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        [SVProgressHUD dismiss];
        
        @strongify(self);
        if(self == nil) return nil;
        if (!serverTask.isFaulted) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPost" object:nil];
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
        }
        return nil;
    }];
}

@end
