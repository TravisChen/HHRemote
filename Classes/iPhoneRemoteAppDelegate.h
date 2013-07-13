#import <UIKit/UIKit.h>
#import "BonjourBrowser.h"

@class EAGLView;

@interface GLRemoteTapAppDelegate : NSObject <UIApplicationDelegate, BonjourBrowserDelegate> {
	IBOutlet UIWindow *m_Window;
	IBOutlet UnityRemoteView *m_UnityRemoteView;
	BonjourBrowser *m_Browser;
	UILabel	*m_ConnectionErrorLabel;
    UIToolbar *m_Toolbar;
    UIToolbar *m_ConnectionErrorToolbar;
    UIAlertView *m_IPAddressAlert;
    UIAlertView *m_IPErrorAlert;
    UITextField *m_IPTextField;
    bool m_ShowImage;
}

- (void) setupBonjourView: (NSString*) title;
- (void) shutdownViews;

@end

