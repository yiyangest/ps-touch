/*
 File: EchoClientAppDelegate.m
 
 Abstract: Interface definitions for the GUI client portion of the CocoaEcho example.
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Computer, Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright © 2005 Apple Computer, Inc., All Rights Reserved
 */ 

/**************************************************************************
 ADOBE SYSTEMS INCORPORATED
 Copyright 2010 Adobe Systems Incorporated
 All Rights Reserved.
 
 NOTICE:  Adobe permits you to use, modify, and distribute this file
 in accordance with the terms of the Adobe license agreement accompanying
 it.  If you have received this file from a source other than Adobe, then
 your use, modification, or distribution of it requires the prior written
 permission of Adobe.
 **************************************************************************/


#import <Cocoa/Cocoa.h>

@interface EchoClientAppDelegate : NSObject
{
    IBOutlet id inputField;
    IBOutlet id responseField;
    IBOutlet id passwordField;
    IBOutlet id serverTableView;
    IBOutlet id colorInvertButton;
    IBOutlet id colorGetButton;
    IBOutlet id scriptErrorButton;
    IBOutlet id subscribeButton;
    IBOutlet id sendJPEGButton;
    IBOutlet id getJPEGButton;
    IBOutlet id sendPixmapButton;
    IBOutlet id getPixmapButton;
    IBOutlet id sendBlobButton;
    IBOutlet id highASCIIButton;
    IBOutlet id foregroundColorWidget;
    IBOutlet id backgroundColorWidget;
    IBOutlet id imageWidget;
    IBOutlet id connectionStatusWidget;
	
    NSNetServiceBrowser * serviceBrowser;
    NSMutableArray * serviceList;
	
    NSInputStream * inputStream;
    NSOutputStream * outputStream;
    NSMutableData * dataBuffer;
	
	NSString * password;
	int packetBodySize;
}

- (IBAction)sendText:(id)sender;
- (IBAction)setPassword:(id)sender;
- (IBAction)getColorPressed:(id)sender;
- (IBAction)invertPressed:(id)sender;
- (IBAction)scriptErrorPressed:(id)sender;
- (IBAction)subscribePressed:(id)sender;
- (IBAction)getJPEGPressed:(id)sender;
- (IBAction)sendJPEGPressed:(id)sender;
- (IBAction)getPixmapPressed:(id)sender;
- (IBAction)sendPixmapPressed:(id)sender;
- (IBAction)sendBlobPressed:(id)sender;
- (IBAction)sendHighASCIIPressed:(id)sender;
- (void)subscribeColorChanges;
- (void)processForegroundChange: (NSString *)string;
- (void)processBackgroundChange: (NSString *)string;
- (void)processReceivedJPEG: (NSData *)data;
- (void)openStreams;
- (void)closeStreams;
- (void)sendJavaScriptMessage:(NSData*)dataToSend;
- (void)sendNetworkMessage:(NSData*)dataToSend type:(int)dataType;
@end
