/*
 File: EchoClientAppDelegate.m
 
 Abstract: Implementation of the GUI CocoaEcho client.
 
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


// ccox - hard coded service name for this test app
#include "PSCryptor.h"

#define kNameOfService	"_photoshopserver._tcp."


#import "EchoClientAppDelegate.h"

#define qEncryption	1

static int32_t transaction_id = 1;


static PSCryptor *sPSCryptor = NULL;

@implementation EchoClientAppDelegate


- (void)sendJavaScriptMessage:(NSData*)dataToSend {

	[self sendNetworkMessage:dataToSend type:2 ];
}


- (void)sendNetworkMessage:(NSData*)dataToSend type:(int)dataType {

    if (outputStream) {
        int remainingToWrite = [dataToSend length];
		int prolog_length = 12;	// 3x 32 bit integers, not counting the length value itself
		// com status is outside the encrypted section
		
		int plainTextLength = prolog_length + remainingToWrite;
		size_t encryptedLength = plainTextLength;
		NSError *err = NULL;
		
#if qEncryption
		encryptedLength = PSCryptor::GetEncryptedLength (plainTextLength);
#endif

// the length is NOT encrypted
		// write length of message as 32 bit signed int
		// includes all bytes after the length
		int swabbed_temp = htonl( encryptedLength + 4 );
		NSInteger written = [outputStream write:(const uint8_t*)&swabbed_temp maxLength:4];
		if (written != 4)
			{
			err = [outputStream streamError];	// just here for debugging
			NSBeep();
			return;
			}
		
		NSStreamStatus status = [outputStream streamStatus];
		if ( status == NSStreamStatusError
			|| status == NSStreamStatusClosed
			|| status == NSStreamStatusNotOpen)
			{
			err = [outputStream streamError];	// just here for debugging
			NSBeep();
			return;
			}

// the communication status is NOT encrypted
		// write communication status value as 32 bit unsigned int
		swabbed_temp = htonl( 0 );
		[outputStream write:(const uint8_t*)&swabbed_temp maxLength:4];


// this part should be encrypted, until the end of the message
		
		char *tempBuffer = (char *) malloc (encryptedLength);
		
		// protocol version, 32 bit unsigned integer
		swabbed_temp = htonl( 1 );
		memcpy (tempBuffer+0, (const void *) &swabbed_temp, 4);
		
		// transaction id, 32 bit unsigned integer
		swabbed_temp = htonl( transaction_id++ );
		memcpy (tempBuffer+4,(const void *) &swabbed_temp, 4);
		
		// content type, 32 bit unsigned integer
		swabbed_temp = htonl( dataType );
		memcpy (tempBuffer+8, (const void *) &swabbed_temp, 4);
		
		// and the data passed in
		uint8 * marker = (uint8 *)[dataToSend bytes];
		memcpy (tempBuffer+12, marker, remainingToWrite);
		
		marker = (uint8 *) tempBuffer;
		// now encrypt the message packet
#if qEncryption
		sPSCryptor->EncryptDecrypt (true, tempBuffer, plainTextLength, tempBuffer, encryptedLength, &encryptedLength);
#endif
		
		// write the text
		remainingToWrite = encryptedLength;
         while (0 < remainingToWrite) {
            NSInteger actuallyWritten = [outputStream write:marker maxLength:remainingToWrite];
			
			status = [outputStream streamStatus];
			if ( actuallyWritten < 0
				|| status == NSStreamStatusError
				|| status == NSStreamStatusClosed
				|| status == NSStreamStatusNotOpen)
				{
				err = [outputStream streamError];
				free (tempBuffer);
				NSBeep();
				return;
				}
			
            remainingToWrite -= actuallyWritten;
            marker += actuallyWritten;
        }
		free (tempBuffer);
// encrypt until the end of the message

    }

}


- (IBAction)sendText:(id)sender {
    NSString * stringToSend = [NSString stringWithFormat:@"%@\n", [sender stringValue]];
    NSData * dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
	[ self sendJavaScriptMessage: dataToSend ];
}

- (IBAction)setPassword:(id)sender {
	password = [sender stringValue];
	// ccox - DEFERRED - we should stop and restart the connection
}

- (IBAction)getColorPressed:(id)sender {
    NSString * stringToSend = [NSString stringWithUTF8String:"app.foregroundColor.rgb.hexValue.toString();"];
    NSData * dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
	[ self sendJavaScriptMessage: dataToSend ];
}

- (IBAction)invertPressed:(id)sender {
    NSString * stringToSend = [NSString stringWithUTF8String:"var color = app.foregroundColor; color.rgb.red = 255 - color.rgb.red; color.rgb.green = 255 - color.rgb.green; color.rgb.blue = 255 - color.rgb.blue; app.foregroundColor = color;"];
    NSData * dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
	[ self sendJavaScriptMessage: dataToSend ];
}

- (IBAction)scriptErrorPressed:(id)sender {
    NSString * stringToSend = [NSString stringWithUTF8String:"alert(\"Barry's Coming"];
    NSData * dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
	[ self sendJavaScriptMessage: dataToSend ];
}


- (IBAction)sendBlobPressed:(id)sender {
	NSString *ducky = [[NSBundle mainBundle] pathForResource:@"Ducky" ofType:@"jpg"];
	NSData *imageData = [[NSData alloc] initWithContentsOfFile:ducky];
	[ self sendNetworkMessage:imageData type:5 ];
	[ imageData release ];
}


- (IBAction)sendHighASCIIPressed:(id)sender {
// Apple says "It is not safe is to include high-bit characters in your source code"
// you have to enter the escaped versions of the values for UTF8
// Since \xe2\x80\x94 is the 3-byte UTF-8 string for 0x2014...
// This is apparently due to GCC mangling high ASCII characters
// ccox - but that does not explain why a UTF16 string pasted into the edit field is also corrupted!

//	char *testString = "alert(\"€£¥ ©®℗℠™" HighASCII Test €£¥\");";

	char *testString = "alert(\"\xe2\x82\xac\xc2\xa3\xc2\xa5\x20\xc2\xa9\xc2\xae\xe2\x84\x97\xE2\x84\xA0\xE2"
						"\x84\xA2\x20\x48\x69\x67\x68\x41\x53\x43\x49\x49\x20\x54\x65"
						"\x73\x74\x20\xE2\x82\xAC\xC2\xA3\xC2\xA5\");  "
						"\"\xe2\x82\xac\xc2\xa3\xc2\xa5\x20\xc2\xa9\xc2\xae\xe2\x84\x97\xE2\x84\xA0\xE2"
						"\x84\xA2\x20\x48\x69\x67\x68\x41\x53\x43\x49\x49\x20\x54\x65"
						"\x73\x74\x20\xE2\x82\xAC\xC2\xA3\xC2\xA5\"";
    NSString * stringToSend = [NSString stringWithUTF8String:testString];
	
	// set the input, so we can see what was sent for comparison
	[inputField setStringValue:stringToSend];
	
    NSData * dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
	[ self sendJavaScriptMessage: dataToSend ];
}


- (IBAction)sendJPEGPressed:(id)sender {
	NSString *ducky = [[NSBundle mainBundle] pathForResource:@"Ducky" ofType:@"jpg"];
	NSData *imageData = [[NSData alloc] initWithContentsOfFile:ducky];
	
	// need one byte before the image data for format type
	NSMutableData *image_message = [NSMutableData alloc];
	
	unsigned char format = 1;	// JPEG
	[ image_message appendBytes:(const void *)&format length:1 ];
	[ image_message appendData: imageData ];
	
	[ self sendNetworkMessage:image_message type:3 ];
	
	[ image_message release ];
	[ imageData release ];
}


- (IBAction)sendPixmapPressed:(id)sender {
	int width = 256;
	int height = 256;
	int planes = 3;
	int bufferSize = width * height * planes;
	int i, j;
	
	NSMutableData *imageData = [[NSMutableData alloc] initWithLength:bufferSize];
	unsigned char *buffer = (unsigned char *) [imageData bytes];
	
	// put some simple gradients in the bits
	for (i = 0; i < height; ++i)
		{
		for (j = 0; j < width; ++j)
			{
			int offset = i*width*planes + j*3;
			buffer[ offset + 0 ] = (i) & 0xFF;
			buffer[ offset + 1 ] = (j) & 0xFF;
			buffer[ offset + 2 ] = (i + j) & 0xFF;
			}
		}
	
	
	// construct the header
	NSMutableData *image_message = [NSMutableData alloc];
	
	unsigned char format = 2;		// Pixmap
	[ image_message appendBytes:(const void *)&format length:1 ];
	
	// 4 bytes uint32 width
	unsigned int temp = htonl( width );
	[ image_message appendBytes:(const void *)&temp length:4 ];
	
	// 4 bytes uint32 height
	temp = htonl( height );
	[ image_message appendBytes:(const void *)&temp length:4 ];
	
	// 4 bytes uint32 rowBytes
	temp = htonl( planes*width );
	[ image_message appendBytes:(const void *)&temp length:4 ];
	
	// 1 byte color mode = 1 = RGB
	unsigned char tempC = 1;
	[ image_message appendBytes:(const void *)&tempC length:1 ];
	
	// 1 byte channel count
	tempC = planes;
	[ image_message appendBytes:(const void *)&tempC length:1 ];
	
	// 1 byte bits per channel
	tempC = 8;
	[ image_message appendBytes:(const void *)&tempC length:1 ];
	
	// append the bits
	[ image_message appendData: imageData ];
	
	// send the message
	[ self sendNetworkMessage:image_message type:3 ];
	
	// cleanup after Cocoa
	[ image_message release ];
	[imageData release];
}


- (IBAction)getJPEGPressed:(id)sender {
	// ask for JPEG thumbnail of frontmost image sized to fit in our thumbnail space
	// sized 128x128, RGB, 8 bit
    NSString * stringToSend = [NSString stringWithUTF8String:"var idNS = stringIDToTypeID( \"sendDocumentThumbnailToNetworkClient\" );\r"
															"var desc1 = new ActionDescriptor();\r"
															"desc1.putInteger( stringIDToTypeID( \"width\" ), 128 );\r"
															"desc1.putInteger( stringIDToTypeID( \"height\" ), 128 );\r"
															"desc1.putInteger( stringIDToTypeID( \"format\" ), 1 );\r"
															"executeAction( idNS, desc1, DialogModes.NO );"  ];
    NSData * dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
	[ self sendJavaScriptMessage: dataToSend ];
}

- (IBAction)getPixmapPressed:(id)sender {
	// ask for Pixmap thumbnail of frontmost image sized to fit in our thumbnail space
	// sized 128x128, RGB, 8 bit
    NSString * stringToSend = [NSString stringWithUTF8String:"var idNS = stringIDToTypeID( \"sendDocumentThumbnailToNetworkClient\" );"
															"var desc1 = new ActionDescriptor();"
															"desc1.putInteger( stringIDToTypeID( \"width\" ), 128 );"
															"desc1.putInteger( stringIDToTypeID( \"height\" ), 128 );"
															"desc1.putInteger( stringIDToTypeID( \"format\" ), 2 );"
															"executeAction( idNS, desc1, DialogModes.NO );"  ];
    NSData * dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
	[ self sendJavaScriptMessage: dataToSend ];
}


// subscribe to notifications for the toolChanged event
static int tool_subscription_transaction = -1;
- (IBAction)subscribePressed:(id)sender {

#if 0
// document changed
    NSString * stringToSend = [NSString stringWithUTF8String:"var idNS = stringIDToTypeID( \"networkEventSubscribe\" );"
															"var desc1 = new ActionDescriptor();"
															"desc1.putClass( stringIDToTypeID( \"eventIDAttr\" ), stringIDToTypeID( \"currentDocumentChanged\" ) );"
															"executeAction( idNS, desc1, DialogModes.NO );"  ];

#else
    NSString * stringToSend = [NSString stringWithUTF8String:"var idNS = stringIDToTypeID( \"networkEventSubscribe\" );"
															"var desc1 = new ActionDescriptor();"
															"desc1.putClass( stringIDToTypeID( \"eventIDAttr\" ), stringIDToTypeID( \"toolChanged\" ) );"
															"executeAction( idNS, desc1, DialogModes.NO );"  ];
#endif
    NSData * dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
	[ self sendJavaScriptMessage: dataToSend ];
	
	tool_subscription_transaction = transaction_id - 1;
}


#pragma mark -
#pragma mark current color display code

// subscribe to notifications for color changed events
static int foregroundColor_subscription = -1;
static int backgroundColor_subscription = -1;
static int foregroundColor_transaction = -1;
static int backgroundColor_transaction = -1;

- (void)subscribeColorChanges {
	// subscribe to foreground changes
	{
    NSString * stringToSend = [NSString stringWithUTF8String:"var idNS = stringIDToTypeID( \"networkEventSubscribe\" );"
															"var desc1 = new ActionDescriptor();"
															"desc1.putClass( stringIDToTypeID( \"eventIDAttr\" ), stringIDToTypeID( \"foregroundColorChanged\" ) );"
															"executeAction( idNS, desc1, DialogModes.NO );"  ];
    NSData * dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
	[ self sendJavaScriptMessage: dataToSend ];
	foregroundColor_subscription = transaction_id - 1;
	}
	
	// subscribe to background changes
	{
    NSString * stringToSend2 = [NSString stringWithUTF8String:"var idNS = stringIDToTypeID( \"networkEventSubscribe\" );"
															"var desc1 = new ActionDescriptor();"
															"desc1.putClass( stringIDToTypeID( \"eventIDAttr\" ), stringIDToTypeID( \"backgroundColorChanged\" ) );"
															"executeAction( idNS, desc1, DialogModes.NO );"  ];
    NSData * dataToSend2 = [stringToSend2 dataUsingEncoding:NSUTF8StringEncoding];
	[ self sendJavaScriptMessage: dataToSend2 ];
	backgroundColor_subscription = transaction_id - 1;
	}
	
	// get initial foreground
	{
    NSString * stringToSend = [NSString stringWithUTF8String:"\"ignored\\r\"+app.foregroundColor.rgb.hexValue.toString();"];
    NSData * dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
	[ self sendJavaScriptMessage: dataToSend ];
	foregroundColor_transaction = transaction_id - 1;
	}

	// get initial background
	{
    NSString * stringToSend = [NSString stringWithUTF8String:"\"ignored\\r\"+app.backgroundColor.rgb.hexValue.toString();"];
    NSData * dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
	[ self sendJavaScriptMessage: dataToSend ];
	backgroundColor_transaction = transaction_id - 1;
	}

}


static NSColor * ColorFromString( NSString *hexColor )
{
	if ( [hexColor length] < 6)
		return NULL;

	long color_value = strtol( [hexColor UTF8String], (char **)NULL, 16 );
	
	unsigned char red = (color_value >> 16) & 0xFF;
	unsigned char green = (color_value >> 8) & 0xFF;
	unsigned char blue = color_value & 0xFF;

	NSColor *theColor = [ NSColor colorWithDeviceRed: (red/255.0f) green:(green/255.0f) blue:(blue/255.0f) alpha: 1.0 ];

	return theColor;
}

static NSColor * ColorFromResponseString( NSString *string )
{
	// parse the string returned, of the style:     "toolChanged\rsomeTool"
	// find first return, take substring from that index
	NSRange range = [string rangeOfString:@"\r" ];
	if (range.length == 0)
		return NULL;
	
	NSString *hexColor = [string substringFromIndex: (range.location + 1) ];
	
	return ColorFromString( hexColor );
}

- (void)processForegroundChange: (NSString *)string {

	NSColor *theColor = ColorFromResponseString( string );
	
	if (theColor != NULL)
		[ foregroundColorWidget setColor: theColor ];
}

- (void)processBackgroundChange: (NSString *)string {

	NSColor *theColor = ColorFromResponseString( string );
	
	if (theColor != NULL)
		[ backgroundColorWidget setColor: theColor ];
}

- (void)processReceivedJPEG: (NSData *)data {
	NSImage *ourImage = [[NSImage alloc] initWithData:data];	// this will be NULL if the data isn't readable
	[imageWidget setImage: ourImage];		// imageWidget appears to be an NSImageView
}
							


#pragma mark -
#pragma mark random app cruft

- (void)awakeFromNib {
    serviceBrowser = [[NSNetServiceBrowser alloc] init];
    serviceList = [[NSMutableArray alloc] init];
    [serviceBrowser setDelegate:self];
    
    [serviceBrowser searchForServicesOfType:@kNameOfService inDomain:@""];
	
	[ foregroundColorWidget setBordered: false ];
	[ backgroundColorWidget setBordered: false ];
	
	// set default password
    password = [NSString stringWithUTF8String:"Swordfish"];
	[passwordField setStringValue:password];
	
	NSColor *theColor = [ NSColor colorWithDeviceRed: 0.5 green:0.5 blue:0.5 alpha: 1.0 ];
	[ connectionStatusWidget setColor: theColor ];

// ccox - WRITE ME - set default image content
}

#pragma mark -
#pragma mark NSNetServiceBrowser delegate methods

// We broadcast the willChangeValueForKey: and didChangeValueForKey: for the NSTableView binding to work.

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    if (![serviceList containsObject:aNetService]) {
        [self willChangeValueForKey:@"serviceList"];
        [serviceList addObject:aNetService];
        [self didChangeValueForKey:@"serviceList"];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    if ([serviceList containsObject:aNetService]) {
        [self willChangeValueForKey:@"serviceList"];
        [serviceList removeObject:aNetService];
        [self didChangeValueForKey:@"serviceList"];
    }
}

#pragma mark -
#pragma mark Service list action method

- (IBAction)serverClicked:(id)sender {
    NSTableView * table = (NSTableView *)sender;
    int selectedRow = [table selectedRow];
    
    if (inputStream && outputStream) {
        [self closeStreams];
    }
    
    if (-1 != selectedRow) {
        NSNetService * selectedService = [serviceList objectAtIndex:selectedRow];
        if ([selectedService getInputStream:&inputStream outputStream:&outputStream]) {
            [self openStreams];
        }
    }

	// setup our encryption system, using the user supplied password
	if (sPSCryptor != NULL)
		delete sPSCryptor;
	
	// lifetime of the string is shared with the NSString it came from
	const char * pass_cstring = [ password cStringUsingEncoding:NSUTF8StringEncoding ];
	sPSCryptor = new PSCryptor (pass_cstring);


// now that encryption is setup, we can send messages
	[ self subscribeColorChanges ];
	
}

#pragma mark -
#pragma mark Stream methods

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent {
    NSInputStream * istream;
    switch(streamEvent) {
		case NSStreamEventHasBytesAvailable:
			{

			UInt8 buffer[1024];
			
            istream = (NSInputStream *)aStream;
            if (!dataBuffer) {
                dataBuffer = [[NSMutableData alloc] initWithCapacity:2048];
            }
			
			NSInteger actuallyRead = [istream  read:buffer maxLength:1024];
			
			if (actuallyRead < 0)
				{
				NSBeep();
				[self closeStreams];
				break;
				}
			
			[dataBuffer appendBytes:buffer length:actuallyRead];
			
			// see if we have enough to process, loop over messages in buffer
			while( YES ) {
			
				// Did we read the header yet?
				if ( packetBodySize == -1 ) {
				  // Do we have enough bytes in the buffer to read the header?
				  if ( [dataBuffer length] >= sizeof(int) ) {
					// extract length
					memcpy(&packetBodySize, [dataBuffer bytes], sizeof(int));
					packetBodySize = ntohl( packetBodySize );		// size is in network byte order
					
					// remove that chunk from buffer
					NSRange rangeToDelete = {0, sizeof(int)};
					[dataBuffer replaceBytesInRange:rangeToDelete withBytes:NULL length:0];
				  }
				  else {
					// We don't have enough yet. Will wait for more data.
					break;
				  }
				}
				
				// We should now have the header. Time to extract the body.
				if ( [dataBuffer length] >= ((NSUInteger) packetBodySize) ) {
				  // We now have enough data to extract a meaningful packet.
					const int kPrologLength = 16;
					char *buffer = (char *) [dataBuffer bytes];
					
					unsigned long com_status = *((unsigned long *)(buffer + 0));
					com_status = ntohl( com_status );

					
					// decrypt the message
					size_t decryptedLength = (size_t) packetBodySize - 4;	// don't include com status
					
					int skip_message = 0;
					
#if qEncryption
					if (com_status == 0 && sPSCryptor)
						{
						PSCryptorStatus result = sPSCryptor->EncryptDecrypt (false, buffer+4, decryptedLength, buffer+4, decryptedLength, &decryptedLength);
						
						if (kCryptorSuccess != result)
							{
							// failure to decrypt, ignore this message and disconnect
							skip_message = 1;
							}
						}
#endif
					
					if (!skip_message)
						{
				  
						// protocol version, 32 bit unsigned int, network byte order
						unsigned long protocol_version = *((unsigned long *)(buffer + 4));
						protocol_version = ntohl( protocol_version );
						
						if (protocol_version != 1)
							{
							// corrupt, or protocol is newer than what we understand
							skip_message = 1;
							}
						
						if (!skip_message)
							{
							// transaction, 32 bit unsigned int, network byte order
							unsigned long transaction = *((unsigned long *)(buffer + 8));
							transaction = ntohl( transaction );
							
							// content type, 32 bit unsigned int, network byte order
							unsigned long content = *((unsigned long *)(buffer + 12));
							content = ntohl( content );
							NSFont *response_font = nil;
							if (content == 1 || com_status != 0)	// error string
								{
								// change text color?
								response_font = [NSFont boldSystemFontOfSize: 14];
								NSBeep();
								}
							
							unsigned char *received_data = (unsigned char *)(buffer+kPrologLength);
							int received_length = (decryptedLength-(kPrologLength-4));
							
							// see if this is a response we're looking for
							if (content == 3)		// image data
								{
								// process as image data
								
								unsigned char image_type = *((unsigned char *)received_data);
								
								if (image_type == 1)	// JPEG
									{
									int jpeg_length = received_length - 1;
									NSData *imagedata = [NSData dataWithBytes:(received_data+ 1) length:jpeg_length];
									[self processReceivedJPEG: imagedata ];
									}
								else if (image_type == 2)		// Pixmap
									{
									bool imageError = false;
									
									int pixmap_prolog_length = 3*4 + 3 + 1;

									int width = *((unsigned long *)(received_data + 1));
									width = ntohl(width);
									
									int height = *((unsigned long *)(received_data + 5));
									height = ntohl( height );
									
									int rowBytes = *((unsigned long *)(received_data + 9));
									rowBytes = ntohl( rowBytes );
									
									int mode = *((unsigned char *)received_data + 13);	// must be 1 for now
									int channels = *((unsigned char *)received_data + 14);
									int bitsPerChannel = *((unsigned char *)received_data + 15);	// must be 8 for now
									
									const unsigned char *raw_data = received_data + pixmap_prolog_length;
									int raw_length = received_length - pixmap_prolog_length;
									
									if (mode != 1 || bitsPerChannel != 8)
										imageError = true;
									
									// 4k being a largish display size
									if (width < 0 || width > 4096
										|| height < 0 || height > 4096)
										imageError = true;
									
									if (channels < 0 || channels > 4
										|| rowBytes < ((width*channels*bitsPerChannel)/8))
										imageError = true;
									
									if (raw_length < (height*rowBytes))
										imageError = true;
									
									
									if (!imageError)
										{
										// NULL so the rep will allocate it's own memory, and we won't have to keep the message buffer around
										NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																		pixelsWide:width pixelsHigh:height bitsPerSample:bitsPerChannel
																		samplesPerPixel:channels hasAlpha:FALSE isPlanar:FALSE
																		colorSpaceName:NSCalibratedRGBColorSpace
																		bytesPerRow:rowBytes bitsPerPixel:(bitsPerChannel*channels) ];

										// copy the message data into the image rep
										unsigned char *bitmapData = [imageRep bitmapData];
										memcpy( bitmapData, raw_data, raw_length );

										NSSize imageSize;
										imageSize.width = width;
										imageSize.height = height;
										NSImage *ourImage = [[NSImage alloc] initWithSize:imageSize];
										[ourImage addRepresentation:imageRep ];
										[imageWidget setImage: ourImage];		// imageWidget appears to be an NSImageView
										}
									else
										{
										NSString * error_string = [NSString stringWithUTF8String:"Bad parameters for Pixmap!"];
										NSBeep();
										response_font = [NSFont boldSystemFontOfSize: 14];
										[responseField setStringValue:error_string];
										[responseField setFont:response_font];
										}
									
									}
								
								}
							else 
								{
								
								// Set the response string
								NSString * string = [[NSString alloc] initWithBytes:received_data  length:received_length encoding:NSUTF8StringEncoding ];
								[responseField setStringValue:string];
								[responseField setFont:response_font];
								
								if (content != 1)
									{
									if (transaction == tool_subscription_transaction)
										{
										//[self processToolChangeNotification:string];
										}
									if (transaction == foregroundColor_subscription
										|| transaction == foregroundColor_transaction)
										{
										[self processForegroundChange:string];
										}
									if (transaction == backgroundColor_subscription
										|| transaction == backgroundColor_transaction)
										{
										[self processBackgroundChange:string];
										}
									}
							
								[string release];
								}
							
							}
						
						}
					
				  // Remove that chunk from buffer
				  NSRange rangeToDelete = {0, packetBodySize};
				  [dataBuffer replaceBytesInRange:rangeToDelete withBytes:NULL length:0];
				  
				  // We have processed the packet. Resetting the state.
				  packetBodySize = -1;
				}
				else {
				  // Not enough data yet. Will wait.
				  break;
				}
			  }
			}

            break;
        case NSStreamEventEndEncountered:
            [self closeStreams];
            break;
        case NSStreamEventHasSpaceAvailable:
        case NSStreamEventErrorOccurred:
        case NSStreamEventOpenCompleted:
        case NSStreamEventNone:
        default:
            break;
    }
}

- (void)openStreams {
    [inputStream retain];
    [outputStream retain];
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
	
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];
	packetBodySize = -1;
	
	NSColor *theColor = [ NSColor colorWithDeviceRed: 0.0 green:1.0 blue:0.0 alpha: 1.0 ];
	[ connectionStatusWidget setColor: theColor ];
}

- (void)closeStreams {
    [inputStream close];
    [outputStream close];
    [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream setDelegate:nil];
    [outputStream setDelegate:nil];
    [inputStream release];
    [outputStream release];
    inputStream = nil;
    outputStream = nil;
	packetBodySize = -1;
	
	NSColor *theColor = [ NSColor colorWithDeviceRed: 1.0 green:0.0 blue:0.0 alpha: 1.0 ];
	[ connectionStatusWidget setColor: theColor ];
}

@end
