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
#include "appkey.c"
static NSString *const kReuseId = @"reuseid";

@interface BTFViewController () <UITableViewDataSource,UIAlertViewDelegate>
@property (nonatomic, strong) NSArray *playlists;
@property(nonatomic, strong) BTFSpotify *btfSpotify;
@end

@implementation BTFViewController

- (instancetype)init {
    if (!(self = [super init])) return nil;



    self.btfSpotify = [[BTFSpotify alloc] initWithAppKey:g_appkey size:g_appkey_size];
    [self racUpPlaylists];

    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex==1){
        [self racUpPlaylists];
    }
}

- (void)racUpPlaylists
{

    RAC(self,playlists) = [self.btfSpotify.allPlaylists catch:^RACSignal *(NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"I give up!" otherButtonTitles:@"Try again!",nil];
        [alertView show];
        return [RACSignal empty];
    }];
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
