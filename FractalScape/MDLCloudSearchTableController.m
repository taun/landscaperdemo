//
//  Created by Taun Chapman on 09/15/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MDLCloudSearchTableController.h"


@interface MDLCloudSearchTableController ()

@property (nonatomic,strong) NSArray*   publicCloudRecords;

@end

@implementation MDLCloudSearchTableController

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupAppearance];
}
- (void)setupAppearance {
//    UIImage* backgroundImage = [DaisyStyleKit imageOfSkMasterTableCellBackground];
//    self.tableView.backgroundView = [[UIImageView alloc]initWithImage: backgroundImage];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cloudManager = [[MDLCloudKitManager alloc] init];
    // Do any additional setup after loading the view, typically from a nib.
    //    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    //    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    //    self.navigationItem.rightBarButtonItem = addButton;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.cloudManager requestDiscoverabilityPermission:^(BOOL discoverable) {
        
        if (discoverable) {
            [self.cloudManager fetchPublicFractalRecordsWithCompletionHandler:^(NSArray *records, NSError* error) {
                [self publicPlantsInfo: records];
            }];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CloudKitAtlas" message:@"Getting your name using Discoverability requires permission." preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
                [self dismissViewControllerAnimated:YES completion:nil];
                
            }];
            
            [alert addAction:action];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
}];
}
- (IBAction)cancelButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) publicPlantsInfo: (NSArray*)plantRecords {
    self.publicCloudRecords = plantRecords;
//    NSLog(@"%@",plantRecords);
    [self.tableView reloadData];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.publicCloudRecords count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *PlantCellIdentifier = @"PlantCell";
    
//    MDLDaisyPlantMasterTableCell *cell = [tableView dequeueReusableCellWithIdentifier: PlantCellIdentifier forIndexPath:indexPath];
//    [self configureCell:cell atIndexPath: indexPath];
//    return cell;
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
//    CKRecord *object = [self.publicCloudRecords objectAtIndex: [indexPath indexAtPosition: 1]];
    
//    MDLDaisyPlantMasterTableCell* plantCell = (MDLDaisyPlantMasterTableCell*)cell;
//    plantCell.commonNameLabel.text = object[CommonNameField];
//    plantCell.scientificLabel.text = object[SciNameField];
//    plantCell.wikiNotesLabel.attributedText = [[NSAttributedString alloc]initWithString: object[WikiField]];
//    CKAsset* photoAsset = object[PhotoAssetField];
//    UIImage *image = [UIImage imageWithContentsOfFile:photoAsset.fileURL.path];
//    plantCell.thumbnailImageView.layer.shadowOpacity = [MDLInterfaceTweaks thumbnailShadow];
//    plantCell.thumbnailImageView.borderWidth = [MDLInterfaceTweaks thumbnailBorderWidth];
//    plantCell.thumbnailImageView.image = image;
    
//    plantCell.thumbnailImage.layer.shadowOpacity = FBTweakValue(@"Master", @"cell", @"Shadow Opacity", 0.3);
//    plantCell.thumbnailImage.borderWidth = FBTweakValue(@"Master", @"cell", @"Border Width", 2);
//    plantCell.thumbnailImage.image = [UIImage imageNamed: @"Amarylis"];
    
}


@end
