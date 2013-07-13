#ifndef UNITY_IPHONE_INPUT_IMPL_
#define UNITY_IPHONE_INPUT_IMPL_

#include "iPhoneRemoteVector3.h"
#import <UIKit/UIKit.h>

namespace iphone {
void OnProcessTouchEvents(NSSet* touches, NSSet* allTouches);
void OnDidAccelerate(Vector3f const& acceleration, NSTimeInterval timestamp);
}

#endif
