//
//  CSRecordViewController.m
//  RecordMyScreen
//
//  Created by @coolstarorg on 12/29/12.
//  Copyright (c) 2012 CoolStar Organization. All rights reserved.
//

#import "CSRecordViewController.h"
#import <IOMobileFrameBuffer.h>
#include <sys/time.h>
#import <CoreVideo/CVPixelBuffer.h>


@interface CSRecordViewController ()
{
    CSScreenRecorder *_screenRecorder;
}
@end

@implementation CSRecordViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _screenRecorder = [[CSScreenRecorder alloc] init];
        _screenRecorder.delegate = self;
        self.tabBarItem = [[[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Record", @"") image:[UIImage imageNamed:@"video"] tag:0] autorelease];
    }
    return self;
}

- (void)dealloc
{
    [_screenRecorder release];
    _screenRecorder = nil;
    
    [super dealloc];
}

#pragma mark - UI
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _record = [[[UISegmentedControl alloc] initWithItems:@[@"Record"]] autorelease];
    _record.momentary = YES;
    _record.segmentedControlStyle = UISegmentedControlStyleBar;
    _record.tintColor = [UIColor greenColor];
    [_record setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    [_record addTarget:self action:@selector(record:) forControlEvents:UIControlEventValueChanged];
    
    _stop = [[[UISegmentedControl alloc] initWithItems:@[@"Stop"]] autorelease];
    _stop.momentary = YES;
    _stop.segmentedControlStyle = UISegmentedControlStyleBar;
    _stop.tintColor = [UIColor redColor];
    _stop.enabled = NO;
    [_stop setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    [_stop addTarget:self action:@selector(stop:) forControlEvents:UIControlEventValueChanged];
    
    _progressView.hidden = YES;
    
    
    // Check for iPad for layout
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        _record.frame = CGRectMake(20, 103, 135, 33);
        _stop.frame = CGRectMake(170, 103, 135, 33);
    } else {
     
        _record.frame = CGRectMake(230, 150, 135, 33);
        _stop.frame = CGRectMake(400, 150, 135, 33);
    }
    
    [self.view addSubview:_record];
    [self.view addSubview:_stop];
    
    
    // Do any additional setup after loading the view from its nib.
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    } else {
        return YES;
    }
}

#pragma mark - Starting / Stopping

- (void)record:(id)sender
{
    // Update the UI
    _statusLabel.text = @"00:00:00";
    _stop.enabled = YES;
    _record.enabled = NO;
    
    // Remove the old video
    [[NSFileManager defaultManager] removeItemAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/video.mp4"] error:nil];
    
    NSString *videoPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/video.mp4"];
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"record"] boolValue]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM:dd:yyyy h:mm:ss a"];
        NSString *date = [dateFormatter stringFromDate:[NSDate date]];
        NSString *outName = [NSString stringWithFormat:@"Documents/%@.mp4",date];
        videoPath = [NSHomeDirectory() stringByAppendingPathComponent:outName];
        [dateFormatter release];
    }
    
    // Set the number of audio channels
    NSNumber *audioChannels = [[NSUserDefaults standardUserDefaults] objectForKey:@"channels"];
    NSNumber *sampleRate = [[NSUserDefaults standardUserDefaults] objectForKey:@"samplerate"];
    NSString *audioPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/audio.caf"];
    
    _screenRecorder.videoOutPath = videoPath;
    _screenRecorder.audioOutPath = audioPath;
    _screenRecorder.numberOfAudioChannels = audioChannels;
    _screenRecorder.audioSampleRate = sampleRate;
    
    [_screenRecorder startRecordingScreen];
}

- (void)stop:(id)sender
{
    [_screenRecorder stopRecordingScreen];
}

- (void)screenRecorderDidStopRecording:(CSScreenRecorder *)recorder
{
    // Disable the stop button
    _stop.enabled = NO;
    
    // Announce Encoding will begin
    _statusLabel.text = @"Encoding Movie...";
    
    // Show progress view
    _progressView.hidden = NO;

    // Update the UI for another round
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            _statusLabel.text = @"Ready";
            _progressView.hidden = YES;
            _record.enabled = YES;
        });
    });
}

- (void)screenRecorder:(CSScreenRecorder *)recorder recordingTimeChanged:(NSTimeInterval)recordingInterval
{
    // get an NSDate object from NSTimeInterval
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:recordingInterval];
    
    // Make a date formatter (Possibly reuse instead of creating each time)
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    
    // Set the current time since recording began
    NSString *timeString = [dateFormatter stringFromDate:timerDate];
    _statusLabel.text = timeString;
    [dateFormatter release];
}

// Stubs. Do Error handling shit here.
- (void)screenRecorder:(CSScreenRecorder *)recorder videoContextSetupFailedWithError:(NSError *)error
{
    
}

- (void)screenRecorder:(CSScreenRecorder *)recorder audioRecorderSetupFailedWithError:(NSError *)error
{
    
}

- (void)screenRecorder:(CSScreenRecorder *)recorder audioSessionSetupFailedWithError:(NSError *)error
{
    
}

@end
