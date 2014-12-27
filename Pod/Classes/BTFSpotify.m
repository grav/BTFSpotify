//
// Created by Mikkel Gravgaard on 26/07/14.
// Copyright (c) 2014 Betafunk. All rights reserved.
//

#import "CocoaLibSpotify.h"
#import "BTFSpotify.h"
#import "ReactiveCocoa.h"

@interface NSArray (Utils)
- (id)findFirst:(BOOL(^)(id x))b;
@end

@implementation NSArray (Utils)
- (id)findFirst:(BOOL(^)(id x))b {
    __block id x;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if(b(obj)) {
            x = obj;
            *stop = YES;
        }
    }];
    return x;
}

@end

@interface BTFSpotify () <SPSessionDelegate, SPLoginViewControllerDelegate>
@property (nonatomic, strong) SPPlaybackManager *playbackManager;
@property(nonatomic) BOOL wantsPresentingViewController;
@property (nonatomic, strong) RACSignal *session;

@property(nonatomic) uint8_t const *appKey;
@property(nonatomic) size_t appKeySize;
@end

@implementation BTFSpotify {
    BOOL _didCreateSession;
}

- (instancetype)initWithAppKey:(const uint8_t *)appkey size:(size_t)size {
    if(!(self = [super init])) return nil;
    self.appKey = appkey;
    self.appKeySize = size;
    return self;
}


- (SPPlaybackManager *)playbackManager {
    if(!_playbackManager && [SPSession sharedSession]){
        _playbackManager = [[SPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
    }
    return _playbackManager;
}


- (RACSignal *)session{
    if(!_session){
        _session = [[RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
            NSCAssert(!_didCreateSession, @"already tried creating session");
            _didCreateSession = YES;
            NSError *error;

            BOOL result = [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:self.appKey
                                                                                              length:self.appKeySize]
                                                                     userAgent:@"dk.betafunk.splif"
                                                                 loadingPolicy:SPAsyncLoadingManual
                                                                         error:&error];
            NSCAssert(result, @"");
            // TODO - might want to handle error nicer here


            NSLog(@"Logging in...");
            SPSession *session = [SPSession sharedSession];
            session.delegate = self;

            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSDictionary *storedCredentials = [defaults valueForKey:@"SpotifyUsers"];
            id key = [[storedCredentials allKeys] firstObject];

            // TODO - handle case where storedCredentials is too old!
            if (key) {
                NSString *pw = storedCredentials[key];
                [session attemptLoginWithUserName:key existingCredential:pw];
            } else {
                // TODO - handle case where user cancels - we'll never complete then!
                self.wantsPresentingViewController = YES;
                SPLoginViewController *loginVC = [SPLoginViewController loginControllerForSession:session];
                loginVC.loginDelegate = self;
                [[[RACObserve(self, presentingViewController) ignore:nil] delay:1] subscribeNext:^(UIViewController *presentingVC) {
                    [presentingVC presentViewController:loginVC animated:YES completion:nil];
                }];
            }
            RACSignal *didSucceed = [[self rac_signalForSelector:@selector(sessionDidLoginSuccessfully:)] flattenMap:^RACStream *(RACTuple *tuple) {
                return [self load:tuple.first];
            }];
            RACSignal *didFail = [[self rac_signalForSelector:@selector(session:didFailToLoginWithError:)] flattenMap:^RACStream *(RACTuple *tuple) {
                return [RACSignal error:tuple.second];
            }];

            RACSignal *didFail2 = [[self rac_signalForSelector:@selector(loginViewController:didCompleteSuccessfully:)] flattenMap:^RACStream *(RACTuple *tuple) {
                BOOL didSucceedLogin = [tuple.second boolValue];
                return didSucceedLogin ? nil : [RACSignal error:[NSError errorWithDomain:@"btf.spotify"
                                                                        code:-1
                                                                    userInfo:@{NSLocalizedDescriptionKey:@"User cancelled"}]];
            }];

            RACSignal *returnSignals = [RACSignal merge:@[didSucceed, didFail,didFail2]];
            [returnSignals subscribe:subscriber];

            return nil;
        }] replayLazily];


    }
    return _session;
}

- (void)loginViewController:(SPLoginViewController *)controller didCompleteSuccessfully:(BOOL)didLogin {

}


- (void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error {
    NSLog(@"session failed login: %@",error);
}



- (void)sessionDidLoginSuccessfully:(SPSession *)aSession {
    NSLog(@"Spotify logged in");
}

- (RACSignal *)starredPlaylist
{
    return [self.session flattenMap:^RACStream *(SPSession *session) {
        return [self load:session.starredPlaylist];
    }];
}

- (RACSignal *)playlistWithName:(NSString *)name{
    return [[[self allPlaylists] map:^id(NSArray *playlists) {
        return [playlists findFirst:^BOOL(SPPlaylist *playlist) {
            return [playlist.name isEqualToString:name];
        }];
    }] flattenMap:^RACStream *(id value) {
        if(value){
            return [RACSignal return:value];
        } else {
            NSString *error = [NSString stringWithFormat:@"Could not find playlist named '%@'",name];
            return [RACSignal error:[NSError errorWithDomain:@"btf.spotify"
                                                        code:-1
                                                    userInfo:@{NSLocalizedDescriptionKey:error}]];
        }
    }];

}

- (RACSignal *)addItem:(SPTrack *)item toPlaylist:(SPPlaylist *)playlist atIndex:(NSUInteger)idx{
    return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
        [playlist addItem:item atIndex:idx
                 callback:^(NSError *error) {
            if(error) {
                [subscriber sendError:error];
            } else {
                [subscriber sendNext:@YES];
                [subscriber sendCompleted];
            }
        }];
        return nil;
    }];
}

- (RACSignal *)createPlaylist:(NSString *)playlistName
{
    return [[self playlistContainer] flattenMap:^RACStream *(SPPlaylistContainer *container) {
        return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
            [container createPlaylistWithName:playlistName callback:^(SPPlaylist *createdPlaylist) {
                // TODO - createdPlaylist doesn't seem to be a valid playlist object
                [subscriber sendNext:createdPlaylist];
                [subscriber sendCompleted];
            }];
            return nil;
        }];
    }];

}

- (RACSignal *)playlistContainer
{
    return [self.session flattenMap:^RACStream *(SPSession *s) {
            return [self load:s.userPlaylists];
    }];
}

- (RACSignal *)allPlaylists
{
    return [[self playlistContainer] flattenMap:^RACStream *(SPPlaylistContainer *container) {
        return [self load:container.flattenedPlaylists];
    }];
}

- (RACSignal *)search:(NSString *)query
{
    return [self.session flattenMap:^RACStream *(SPSession *s) {
        SPSearch *search = [SPSearch searchWithSearchQuery:query inSession:s];
        return [self load:search];
    }];
}

- (RACSignal *)load:(id)thing{
    return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
        [SPAsyncLoading waitUntilLoaded:thing timeout:kSPAsyncLoadingDefaultTimeout
                                   then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
                                       if(loadedItems.count==1){
                                           [subscriber sendNext:loadedItems.firstObject];
                                           [subscriber sendCompleted];
                                       } else if(loadedItems.count>1){
                                           [subscriber sendNext:loadedItems];
                                           [subscriber sendCompleted];
                                       } else {
                                           NSCAssert(notLoadedItems.count>0,@"");
                                           NSString *string = [NSString stringWithFormat:@"Could not load %@",thing];
                                           NSError *error = [NSError errorWithDomain:@"btf.spotify"
                                                                                code:-1
                                                                            userInfo:@{NSLocalizedDescriptionKey:string}];
                                           [subscriber sendError:error];
                                       }
                                   }];
        return nil;
    }];
}




- (void)session:(SPSession *)aSession didGenerateLoginCredentials:(NSString *)credential forUserName:(NSString *)userName {
    NSLog(@"didGenerateLoginCreds");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *storedCredentials = [[defaults valueForKey:@"SpotifyUsers"] mutableCopy];

    if (storedCredentials == nil)
        storedCredentials = [NSMutableDictionary dictionary];

    [storedCredentials setValue:credential forKey:userName];
    [defaults setValue:storedCredentials forKey:@"SpotifyUsers"];
}


@end