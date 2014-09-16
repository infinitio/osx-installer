//
//  NTSynchronousTask.m
//  CocoatechCore
//
//  Created by Steve Gehrman on 9/29/05.
//  Copyright 2005 Steve Gehrman. All rights reserved.
//

#import "NTSynchronousTask.h"

@interface NTSynchronousTask ()
@property (retain) NSTask *task;
@property (retain) NSPipe *outputPipe;
@property (retain) NSPipe *inputPipe;
@property (readwrite, retain) NSData *output;
@property (getter = isDone) BOOL done;
@property (readwrite) int result;
@end

@implementation NTSynchronousTask
@synthesize output = mv_output;
@synthesize result = mv_result;
@synthesize task = mv_task;
@synthesize outputPipe = mv_outputPipe;
@synthesize inputPipe = mv_inputPipe;
@synthesize done = mv_done;

- (void)taskOutputAvailable:(NSNotification*)note
{
	self.output = [[note userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
	self.done = YES;
}

- (void)taskDidTerminate:(NSNotification*)note
{
    self.result = [self.task terminationStatus];
}

- (id)init;
{
    self = [super init];
	if (self)
	{
		self.task = [[NSTask alloc] init];
		self.outputPipe = [[NSPipe alloc] init];
		self.inputPipe = [[NSPipe alloc] init];
		
		self.task.standardInput = self.inputPipe;
		self.task.standardOutput = self.outputPipe;
		self.task.standardError = self.outputPipe;
	}
	
    return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

    self.task = nil;
    self.outputPipe = nil;
    self.inputPipe = nil;
    self.output = nil;
}

- (void)run:(NSString*)toolPath directory:(NSString*)currentDirectory withArgs:(NSArray*)args input:(NSData*)input
{
	BOOL success = NO;
	
	if (currentDirectory)
		self.task.currentDirectoryPath = currentDirectory;
	
	self.task.launchPath = toolPath;
	self.task.arguments = args;
				
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(taskOutputAvailable:)
												 name:NSFileHandleReadToEndOfFileCompletionNotification
											   object:[[self outputPipe] fileHandleForReading]];
		
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(taskDidTerminate:)
												 name:NSTaskDidTerminateNotification
											   object:[self task]];	
	
	[[[self outputPipe] fileHandleForReading] readToEndOfFileInBackgroundAndNotifyForModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil]];
	
	@try
	{
		[self.task launch];
		success = YES;
	}
	@catch (NSException *localException) { }
	
	if (success)
	{
		if (input)
		{
			// feed the running task our input
			[[self.inputPipe fileHandleForWriting] writeData:input];
			[[self.inputPipe fileHandleForWriting] closeFile];
		}
						
		// loop until we are done receiving the data
		if (!self.done)
		{
			double resolution = 1;
			BOOL isRunning;
			NSDate* next;
			
			do {
				next = [NSDate dateWithTimeIntervalSinceNow:resolution]; 
				
				isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
													 beforeDate:next];
			} while (isRunning && !self.done);
		}
	}
}

+ (NSData*)task:(NSString*)toolPath directory:(NSString*)currentDirectory withArgs:(NSArray*)args input:(NSData*)input
{
  NSData* result = nil;
	// we need this wacky pool here, otherwise we run out of pipes, the pipes are internally autoreleased
  @autoreleasepool
  {
    @try
    {
      NTSynchronousTask* task = [[NTSynchronousTask alloc] init];

      [task run:toolPath directory:currentDirectory withArgs:args input:input];

      if ([task result] == 0)
        result = [task output];
    }
    @catch (NSException *localException) { }
  }
	
  return result;
}


+(int)	task:(NSString*)toolPath directory:(NSString*)currentDirectory withArgs:(NSArray*)args input:(NSData*)input output: (NSData**)outData
{
  int					taskResult = 0;
	// we need this wacky pool here, otherwise we run out of pipes, the pipes are internally autoreleased
  @autoreleasepool
  {
    if( outData )
      *outData = nil;

    @try {
      NTSynchronousTask* task = [[NTSynchronousTask alloc] init];

      [task run:toolPath directory:currentDirectory withArgs:args input:input];

      taskResult = [task result];
      if( outData )
        *outData = [task output];

    } @catch (NSException *localException) {
      taskResult = errCppGeneral;
    }
  }
	
    return taskResult;
}

@end
