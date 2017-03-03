//
//  NewGroupViewController.m
//  reach-ios
//
//  Created by Admin on 2016-12-27.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "NewGroupViewController.h"
#import "UIPlaceholderTextView.h"
#import "UIColor+CustomColors.h"
#import "PopUpViewController.h"
#import "NSString+Validation.h"
#import "UIImage+Base64.h"

@interface NewGroupViewController ()<UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate>
{
    CGFloat     originalY;
    BOOL        _haveSetupMedia;
}
@property (weak, nonatomic) IBOutlet UIButton *addPhotoBtn;
@property (weak, nonatomic) IBOutlet UIButton *shareBtn;
@property (weak, nonatomic) IBOutlet UIPlaceholderTextView *mainTextView;
@property (weak, nonatomic) IBOutlet UIPlaceholderTextView *titleTextView;
@property (weak, nonatomic) IBOutlet UIImageView *uploadedImageView;

@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) id notificationToken;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *shareBtnBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *innerViewTopConstraint;

@property (strong, nonatomic) BFTask* task;
@end

@implementation NewGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self prepareUI];
    [self addTapGesture];
    [self prepareAccessoryView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [self removeKeyboardObservers];
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
//        self.innerViewTopConstraint.constant = -keyboardSize.height;
//        self.shareBtnBottomConstraint.constant = keyboardSize.height;
        
        if (self.titleTextView.isFirstResponder) {
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

- (void) prepareUI
{
    self.navigationItem.title = [@"New Group for " stringByAppendingString:self.categoryName];
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor],
       NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold" size:21.0]}];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 13, 23)];
    [backButton setBackgroundImage:[UIImage imageNamed:@"Back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(dismissScreen) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    [self.navigationItem setLeftBarButtonItems:@[backButtonItem] animated:YES];
    
    self.shareBtn.layer.cornerRadius = 5;
    self.shareBtn.clipsToBounds = YES;
    
    self.mainTextView.placeholder = @"Please give a description of your group, 350 character max";
    self.titleTextView.placeholder = @"Enter a title for your group, 50 character max";
    self.mainTextView.placeholderColor = [UIColor cccGreyColor];
    self.titleTextView.placeholderColor = [UIColor cccGreyColor];
    
    self.mainTextView.layer.borderColor = [[UIColor cccGreyColor] CGColor];
    self.mainTextView.layer.borderWidth = 2;
    self.mainTextView.layer.cornerRadius = 5;
    self.mainTextView.clipsToBounds = YES;
    
    self.titleTextView.layer.borderColor = [[UIColor cccGreyColor] CGColor];
    self.titleTextView.layer.borderWidth = 2;
    self.titleTextView.layer.cornerRadius = 5;
    self.titleTextView.clipsToBounds = YES;
    
    self.titleTextView.keyboardType = UIKeyboardTypeTwitter;

    _haveSetupMedia = NO;
    
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
    self.titleTextView.inputAccessoryView = accessoryView;
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

- (IBAction)addPhoto:(id) __unused sender {
    [self.view endEditing:YES];
    @weakify(self);
    
    self.imagePicker.finalizationBlock = ^(UIImagePickerController __unused  *picker, NSDictionary *info) {
        @strongify(self);
        //Your implementation here
        UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
        self.uploadedImageView.image = image;
        self->_haveSetupMedia = YES;
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    
    self.imagePicker.cancellationBlock = ^(UIImagePickerController  __unused *picker)
    {
        @strongify(self);
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    
    self.imagePicker.cancellationBlock = ^(UIImagePickerController __unused  *picker) {
        @strongify(self);
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
    }];
    
    [alertController addAction:chooseExisting];
    [alertController addAction:takePhoto];
    [alertController addAction:cancel];
    
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
    popPresenter.sourceView = sender;
    popPresenter.sourceRect = ((UIView*)sender).bounds;
    
    [self presentViewController:alertController animated:YES completion:nil];
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

- (IBAction)sharePost:(id) __unused sender {
    if(!_haveSetupMedia)
    {
        [SVProgressHUD showErrorWithStatus:@"Please, upload a photo"];
        return;
    }
    
    if ([self.mainTextView.text isEmptyOrWhiteSpace]) {
        [SVProgressHUD showErrorWithStatus:@"Please give a description of your group."];
        return;
    }
    
    if(self.mainTextView.text.length < 4){
        [SVProgressHUD showErrorWithStatus:@"Group description must be more than 4 characters."];
        return;
    }
    
    if(self.mainTextView.text.length > 350){
        [SVProgressHUD showErrorWithStatus:@"Please enter less than 350 characters."];
        return;
    }
    
    if(self.titleTextView.text.length == 0){
        [SVProgressHUD showErrorWithStatus:@"Enter a title for your group."];
        return;
    }
    
    if(self.titleTextView.text.length > 50){
        [SVProgressHUD showErrorWithStatus:@"please enter less than 50 characters."];
        return;
    }
    
    [self performSegueWithIdentifier:kPostPublishType sender:nil];    
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
    [self.view endEditing:YES];
    
    NSString *choosedImage = (self.uploadedImageView.image == nil) ? @"" : [self.uploadedImageView.image encodeToBase64String];

    [SVProgressHUD show];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    
    @weakify(self);
    [[[QMNetworkManager sharedManager] createNewGroupWithName:self.titleTextView.text description:self.mainTextView.text image:choosedImage categoryID:self.categoryID permission:permission] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        [SVProgressHUD dismiss];
        @strongify(self)
        if (self == nil) return nil;
        if (!serverTask.isFaulted) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewGroup" object:nil];
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
        }
        
        return nil;
    }];
}

@end
