//
//  SHKMail.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/17/10.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHKConfiguration.h"
#import "SHKMail.h"

@implementation SHKMail

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Email");
}

+ (BOOL)canShareText
{
	return YES;
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canShareFileOfMimeType:(NSString *)mimeType size:(NSUInteger)size
{
	return YES;
}

+ (BOOL)shareRequiresInternetConnection
{
	return NO;
}

+ (BOOL)requiresAuthentication
{
	return NO;
}


#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare
{
	return [MFMailComposeViewController canSendMail];
}

- (BOOL)shouldAutoShare
{
	return YES;
}



#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{
	self.quiet = YES;
	
	if (![self validateItem])
		return NO;
	
	return [self sendMail]; // Put the actual sending action in another method to make subclassing SHKMail easier
}

- (BOOL)sendMail
{	
	MFMailComposeViewController *mailController = [[[MFMailComposeViewController alloc] init] autorelease];
	if (!mailController) {
		// e.g. no mail account registered (will show alert)
		[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
		return YES;
	}
	
    [self retain]; //must retain, because mailController does not retain its delegates. Released in callback.
	mailController.mailComposeDelegate = self;
	mailController.navigationBar.tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:,mailController);
	
	NSString *body = self.item.text;
	BOOL isHTML = self.item.isMailHTML;
	NSString *separator = (isHTML ? @"<br/><br/>" : @"\n\n");
    
	if (body == nil)
	{
		body = @"";
		
		if (self.item.URL != nil)
		{
			NSString *urlStr = [self.item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			if (isHTML)
				body = [body stringByAppendingFormat:@"%@%@", separator, urlStr];
			else
				body = urlStr;
		}
		
		if (self.item.data)
		{
			NSString *attachedStr = SHKLocalizedString(@"Attached: %@", self.item.title ? self.item.title : self.item.filename);
			
			if (isHTML)
				body = [body stringByAppendingFormat:@"%@%@", separator, attachedStr];
			else
				body = attachedStr;
		}
		
		// fallback
		if (body == nil)
			body = @"";
		
		// sig
		if (self.item.mailShareWithAppSignature)
		{
			body = [body stringByAppendingString:separator];
			body = [body stringByAppendingString:SHKLocalizedString(@"Sent from %@", SHKCONFIG(appName))];
		}
	}
	
	if (self.item.data)		
		[mailController addAttachmentData:self.item.data mimeType:self.item.mimeType fileName:self.item.filename];
	
	NSArray *toRecipients = self.item.mailToRecipients;
    if (toRecipients)
		[mailController setToRecipients:toRecipients];
    
	if (self.item.image){
        
        CGFloat jpgQuality = self.item.mailJPGQuality;
        [mailController addAttachmentData:UIImageJPEGRepresentation(self.item.image, jpgQuality) mimeType:@"image/jpeg" fileName:@"Image.jpg"];
	}
	
	[mailController setSubject:self.item.title];
	[mailController setMessageBody:body isHTML:isHTML];
			
	[[SHK currentHelper] showViewController:mailController];
	
	return YES;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	
	switch (result) 
	{
		case MFMailComposeResultSent:
			[self sendDidFinish];
			break;
		case MFMailComposeResultSaved:
			[self sendDidFinish];
			break;
		case MFMailComposeResultCancelled:
			[self sendDidCancel];
			break;
		case MFMailComposeResultFailed:
			[self sendDidFailWithError:nil];
			break;
	}
	[self autorelease];
}


@end
