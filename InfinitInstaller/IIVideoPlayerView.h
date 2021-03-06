//
//  IIVideoPlayerView.h
//  InfinitInstaller
//
//  Created by Christopher Crone on 30/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IIVideoPlayerProtocol;

@interface IIVideoPlayerView : NSView

@property (nonatomic, unsafe_unretained, readwrite) id<IIVideoPlayerProtocol> delegate;
@property (nonatomic, readwrite) NSURL* url;
@property (nonatomic, readonly) NSUInteger play_count;

- (void)play;
- (void)pause;
- (void)restart;

@end

@protocol IIVideoPlayerProtocol <NSObject>

- (void)finishedPlayOfVideo:(IIVideoPlayerView*)sender;

@end