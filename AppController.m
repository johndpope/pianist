//
//  AppController.m
//  Pianist
//
//  Created by Matt Mower on 22/01/2009.
//  Copyright 2009 LucidMac Software. All rights reserved.
//

#import <PYMIDI/PYMIDI.h>

#import "Preferences.h"
#import "AppController.h"
#import "MIDIController.h"

#define MAX_COUNTER (100)

NSString * const UsedMidiDeviceKey = @"UsedMidiDevice";
NSString * const LastMidiDeviceKey = @"LastMidiDevice";

@interface AppController ()

- (void)playRound;
- (void)roundIsOver;
- (void)gameIsOver;

@end

@implementation AppController

+ (void)initialize {
  NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
  
  [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:UsedMidiDeviceKey];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

@synthesize counter;
@synthesize stave;
@synthesize currentRound;
@synthesize score;

- (void)awakeFromNib {
  midiController = [[MIDIController alloc] initWithDestination:self];
  [self rescanMidi:nil];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
  if( [item action] == @selector(startGame:) ) {
    return [midiController source] != nil;
  } else {
    return YES;
  }
}

- (IBAction)startGame:(id)sender {
  [self setScore:0];
  [self setCurrentRound:1];
  [self playRound];
}

- (IBAction)rescanMidi:(id)sender {
  // Remove all but the first two items from the MIDI menu
  NSArray *items = [midiMenu itemArray];
  for( NSMenuItem *item in [items subarrayWithRange:NSMakeRange(2,[items count]-2)] ) {
    [midiMenu removeItem:item];
  }
  
  for( PYMIDIEndpoint *source in [[PYMIDIManager sharedInstance] realSources] ) {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@",[source name]] action:@selector(setMidiSource:) keyEquivalent:@""];
    [item setTarget:self];
    [item setRepresentedObject:source];
    
    if( [source uniqueID] == [[NSUserDefaults standardUserDefaults] integerForKey:LastMidiDeviceKey] ) {
      [item setState:NSOnState];
    }
    
    [midiMenu addItem:item];
  }
}

- (IBAction)setMidiSource:(id)sender {
  [midiController setSource:[sender representedObject]];
  [sender setState:NSOnState];
}

- (void)playRound {
  notePlayed = NO;
  currentNote = 36 + ( random() % 25 );
  [self setCounter:0];
  [stave setShowNoteName:NO];
  [stave setNote:currentNote];
  
  timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                           target:self
                                         selector:@selector(check:)
                                         userInfo:nil
                                          repeats:YES];
}

- (void)check:(NSTimer *)notifyingTimer {
  if( notePlayed ) {
    [self roundIsOver];
  } else {
    if( [self counter] == MAX_COUNTER ) {
      [self roundIsOver];
    } else {
      [self setCounter:[self counter]+1];
    }
  }
}

- (void)roundIsOver {
  [timer invalidate];
  
  if( notePlayed ) {
    if( playedNote == currentNote ) {
      [stave setIsCorrect:YES];
      [self setScore:[self score]+[self counter]];
    } else {
      [stave setIsCorrect:NO];
      NSBeep();
    }
  } else {
    [stave setIsCorrect:NO];
    NSBeep();
  }
  
  [stave setShowNoteName:YES];
  
  if( [self currentRound] == 10 ) {
    [self gameIsOver];
  } else {
    [self setCurrentRound:[self currentRound]+1];
    [self performSelector:@selector(playRound) withObject:nil afterDelay:2.0];
  }
}

- (void)gameIsOver {
  NSBeep();
}

- (void)noteReceived:(int)noteNumber withVelocity:(int)velocity {
  playedNote = noteNumber;
  notePlayed = YES;
}

@end
