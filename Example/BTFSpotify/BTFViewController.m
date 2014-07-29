//
//  BTFViewController.m
//  BTFSpotify
//
//  Created by Mikkel Gravgaard on 07/29/2014.
//  Copyright (c) 2014 Mikkel Gravgaard. All rights reserved.
//

#import "BTFViewController.h"
#import "BTFSpotify.h"
#import "ReactiveCocoa.h"
#import "SPPlaylist.h"

static NSString *const kReuseId = @"reuseid";

@interface BTFViewController () <UITableViewDataSource>
@property (nonatomic, strong) NSArray *playlists;
@property(nonatomic, strong) BTFSpotify *btfSpotify;
@end

@implementation BTFViewController

- (instancetype)init {
    if (!(self = [super init])) return nil;

    self.btfSpotify = [BTFSpotify new];

    RAC(self,playlists) = self.btfSpotify.allPlaylists;

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.dataSource = self;

    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kReuseId];

    [[RACObserve(self, playlists) ignore:nil] subscribeNext:^(NSArray *playlists) {
        NSLog(@"got %d items",playlists.count);
        [tableView reloadData];
    }];
    [self.view addSubview:tableView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(!self.btfSpotify.presentingViewController){
        self.btfSpotify.presentingViewController = self;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.playlists.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReuseId
                                                            forIndexPath:indexPath];
    SPPlaylist *playlist = self.playlists[(NSUInteger) indexPath.row];
    cell.textLabel.text = playlist.name;
    return cell;
}

@end
