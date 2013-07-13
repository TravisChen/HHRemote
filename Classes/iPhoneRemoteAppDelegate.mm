#import "UnityRemoteView.h"
#import "iPhoneRemoteAppDelegate.h"
#import "iPhoneRemoteInput.h"
#import "iPhoneRemoteInputImpl.h"
#import "iPhoneRemoteInputPackets.h"
#import "Setup.h"
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define kWebServiceType @"_unityiphoneremote._tcp"
#define kInitialDomain  @"Machines"
#define kUnityRemotePort 2574

GLRemoteTapAppDelegate* gSingleton = NULL;

void NotifyDisconnectSocketFailure (const char* message);


@implementation GLRemoteTapAppDelegate
- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
	[application setStatusBarHidden:TRUE];
    m_Window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];  
    m_Window.backgroundColor = [UIColor blackColor];
    [m_Window makeKeyAndVisible];
	gSingleton = self;

	[self setupBonjourView: @"Make sure you are connected\nto Wifi and Unity is running."];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self setupBonjourView: @"Make sure you are connected\nto Wifi and Unity is running."];
}

- (void)shutdownViews
{
	if (m_UnityRemoteView)
	{
		[m_UnityRemoteView shutdown];
		[m_UnityRemoteView removeFromSuperview];
		[m_UnityRemoteView release];
		m_UnityRemoteView = NULL;
	}

	if (m_Browser)
	{
		[[m_Browser view]removeFromSuperview];
		[m_Browser release];
		m_Browser = NULL;
	}

	if (m_ConnectionErrorLabel)
	{
		[m_ConnectionErrorLabel removeFromSuperview];
		[m_ConnectionErrorLabel release];
		m_ConnectionErrorLabel = NULL;
	}

//    if (m_Toolbar)
//    {
//        [m_Toolbar removeFromSuperview];
//        [m_Toolbar release];
//        m_Toolbar = NULL;
//    }
}

- (void)showImagesToggled:(UISwitch *)sender
{
    m_ShowImage = sender.on;
}

- (void)setupBonjourView: (NSString*) title
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;

    [self shutdownViews];

    m_Browser = [[BonjourBrowser alloc] initForType:kWebServiceType
                          inDomain:kInitialDomain
                     customDomains:nil 
          showDisclosureIndicators:NO
                  showCancelButton:NO];

    m_Browser.delegate = self;
    m_Browser.showTitleInNavigationBar = NO;
    m_Browser.searchingForServicesString =
        NSLocalizedString(@"Searching for web services", @"Searching for web services string");

    if (title != NULL)
    {
        CGRect screenRect = [[UIScreen mainScreen] bounds];

        CGRect labelRect = CGRectMake(5.0f, 5.0f, screenRect.size.width - 10.0f,
            60.0f);
        CGRect browserRect = CGRectMake(0.0f, 70.0f, screenRect.size.width,
            screenRect.size.height - 120.0f);
        CGRect toolbarRect = CGRectMake(0.0f, screenRect.size.height - 50.0f,
            screenRect.size.width, 50.0f);
        CGRect connectionToolbarRect = CGRectMake(0.0f, 0.0f,
					 screenRect.size.width, 70.0f);

        [[m_Browser view]setFrame:browserRect];

        m_ConnectionErrorLabel = [[UILabel alloc]initWithFrame: labelRect];
        m_ConnectionErrorLabel.font = [UIFont boldSystemFontOfSize: 18];
        m_ConnectionErrorLabel.text = title;
        m_ConnectionErrorLabel.numberOfLines = 0;
        m_ConnectionErrorLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]; 
        m_ConnectionErrorLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        m_ConnectionErrorLabel.shadowColor = [UIColor colorWithRed:0.0 green:0.2 blue:0.4 alpha:1.0];
        m_ConnectionErrorLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);

        m_ConnectionErrorToolbar = [UIToolbar new];
        m_ConnectionErrorToolbar.barStyle = UIBarStyleDefault;
        m_ConnectionErrorToolbar.tintColor = [UIColor colorWithRed:0.3 green:0.32 blue:0.45 alpha:1.0];
        [m_ConnectionErrorToolbar sizeToFit];
        m_ConnectionErrorToolbar.frame = connectionToolbarRect;
        UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithCustomView:m_ConnectionErrorLabel];
        NSArray *item = [NSArray arrayWithObjects: item1, nil];
        [m_ConnectionErrorToolbar setItems:item animated:NO];
        [item1 release];
        [m_Window addSubview:m_ConnectionErrorToolbar];

//        REMOVED IP TOOLBAR
//        
//        m_Toolbar = [UIToolbar new];
//        m_Toolbar.barStyle = UIBarStyleDefault;
//		    m_Toolbar.tintColor = [UIColor colorWithRed:0.3 green:0.32 blue:0.45 alpha:1.0];
//        [m_Toolbar sizeToFit];
//        m_Toolbar.frame = toolbarRect;
//
//        UISwitch *switchView = [[UISwitch alloc]
//            initWithFrame:CGRectMake(0.0, 0.0, 150.0, 50.0)];
//        m_ShowImage = true;
//        [switchView setOn:YES animated:NO];
//        [switchView addTarget:self action:@selector(showImagesToggled:)
//            forControlEvents:UIControlEventValueChanged];
//
//        UIBarButtonItem *button1 = [[UIBarButtonItem alloc]
//            initWithTitle:@"Enter IP Addr."
//                    style:UIBarButtonItemStyleBordered
//                   target:self
//                   action:@selector(manualAddressEnter:)];
//        UIBarButtonItem *switch1 = [[UIBarButtonItem alloc]
//            initWithCustomView:switchView];
//        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0,
//            85.0, 56.0)];
//        textLabel.text = @"Show image:";
//        textLabel.font = [UIFont boldSystemFontOfSize: 13];
//        textLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
//        textLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
//        UIBarButtonItem *label1 = [[UIBarButtonItem alloc]
//            initWithCustomView:textLabel];
//        NSArray *items = [NSArray arrayWithObjects: button1, label1, switch1, nil];
//        [m_Toolbar setItems:items animated:NO];
//        [button1 release];
//        [switch1 release];
//        [label1 release];
//        [m_Window addSubview:m_Toolbar];

        m_IPAddressAlert = [[UIAlertView alloc]
                initWithTitle:@"Enter IP Address" message:@"<>"
                     delegate:self cancelButtonTitle:@"Cancel"                    
                            otherButtonTitles:@"Submit", nil];

        m_IPErrorAlert = [[UIAlertView alloc]
                initWithTitle:@"Invalid IP Address" message:@""
                    delegate:self cancelButtonTitle:@"OK"                    
                            otherButtonTitles:nil];

        m_IPTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 30.0)];
        m_IPTextField.text = @"192.168.";
        m_IPTextField.secureTextEntry = NO;
        m_IPTextField.borderStyle = UITextBorderStyleRoundedRect;
        m_IPTextField.font = [UIFont systemFontOfSize:22.0];
        [m_IPAddressAlert addSubview:m_IPTextField];
    }

    [m_Window addSubview:[m_Browser view]];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    m_Window.frame = screenBounds;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [m_IPTextField resignFirstResponder];
    CGAffineTransform moveDown = CGAffineTransformMakeTranslation(0.0, -60);
    [m_IPAddressAlert setTransform: moveDown];

    if (buttonIndex != 1)
    {
        return;
    }

    NSString *text = m_IPTextField.text;
    const char *bytes = [text UTF8String];

    const char *p = bytes;

    int digits = 0;
    int val = 0;
    int blocks = 0;
    bool isDot = false;
    bool error = false;

    while (*p)
    {
        if (*p == '.')
        {
            if (isDot)
            {
                error = true;
                break;
            }

            isDot = true;
            p++;
        }
        else if (*p <= '9' && *p >= '0')
        {
            val = 0;
            digits = 0;
            isDot = false;

            while (*p && (*p <= '9' && *p >= '0'))
            {
                val = (val * 10) + (*p - '0');
                digits++;
                p++;
            }

            if (digits > 3 || val > 255)
            {
                error = true;
                break;
            }

            blocks++;
        }
        else
        {
            error = true;
            p++;
            break;
        }
    }

    if (error || blocks != 4)
    {
        [m_IPErrorAlert show];
    }
    else
    {
        struct sockaddr_in sin;
        sin.sin_family = AF_INET;
        sin.sin_port = htons(kUnityRemotePort);
        inet_pton(AF_INET, bytes, &(sin.sin_addr));
        [self userEnteredIPAddress:(&sin)];
    }
}

- (void) manualAddressEnter:(id)sender
{
    CGAffineTransform moveUp = CGAffineTransformMakeTranslation(0.0, 60);
    [m_IPAddressAlert setTransform: moveUp];
    [m_IPAddressAlert show];
    [m_IPTextField becomeFirstResponder];
}

- (void) bonjourBrowser:(BonjourBrowser*)browser didResolveInstance:(NSNetService*)service
{
	NSArray* addresses = [service addresses];

	for (int i = 0; i < [addresses count]; i++)
	{
		NSData* address = [[service addresses] objectAtIndex:i];
		struct sockaddr_in *socketAddressPtr = (struct sockaddr_in *)[address bytes];

		CGRect rect = [[UIScreen mainScreen] bounds];
		m_UnityRemoteView = [[UnityRemoteView alloc] initWithFrame:rect editorAddress: socketAddressPtr];
		[m_UnityRemoteView setShowImages:m_ShowImage];
        [m_Window addSubview:m_UnityRemoteView];
		[UIApplication sharedApplication].idleTimerDisabled = YES;
		return;
	}

	NotifyDisconnectSocketFailure("Failed to initiate connection");
}

- (void)userEnteredIPAddress:(struct sockaddr_in *)sin
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    m_UnityRemoteView = [[UnityRemoteView alloc] initWithFrame:rect editorAddress: sin];
    [m_Window addSubview:m_UnityRemoteView];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[self shutdownViews];
}

- (void)dealloc
{
	gSingleton = NULL;
	[m_Window release];
	[m_Browser release];
	[super dealloc];
}

@end

void NotifyDisconnectSocket ()
{
	NSLog(@"Unity has disconnected");
	[gSingleton setupBonjourView: @"Unity successfully disconnected."];
}

void NotifyDisconnectSocketFailure (const char* message)
{
	NSLog(@"Disconnect socket failure: %s", message);	
	[gSingleton setupBonjourView: [NSString stringWithFormat: @"%s", message]];
}
