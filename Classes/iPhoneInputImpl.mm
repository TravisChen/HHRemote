#include "iPhoneRemoteInput.h"
#include "iPhoneRemoteInputImpl.h"
#include "iPhoneRemoteVector3.h"
#include <vector>
#include <algorithm>
#if !defined(DISABLE_TOUCHPAD_SIMULATION)
#	include "GetInput.h"
#	include "ScreenManager.h"
#	include "InputManager.h"
#	include "GUIManager.h"
#endif

using namespace std;
#if !defined(DISABLE_TOUCHPAD_SIMULATION)
std::string GetJoystickAxisName(int joyNum,int axis) { return Format("joystick %d axis %d", 0, 0); }
std::string GetNiceKeyname(int key) { return ""; }
#endif


void InputReadMousePosition () {}
void InputReadMouseState() {}
void InputReadKeyboardState() {}
void InputReadJoysticks() {}


namespace iphone
{

struct TouchImpl : public Touch
{
	enum { EmptyTouchId = ~0UL };
	UITouch const* native;
	int eventFrame;
	float timestamp;
	
	bool isEmpty() const { return native == 0; }
	bool isFinished() const { return (isEmpty() || (phase == UITouchPhaseEnded) || (phase == UITouchPhaseCancelled)); }
	bool isNow(uint frame) const { return (eventFrame == frame); }
	bool isOld(uint frame) const { return (eventFrame < frame); }
};

enum { MaxTouchCount = 16 };
int gEventFrame = 0;
TouchImpl gTouches[MaxTouchCount];

namespace {
	TouchImpl* FindTouch(UITouch const* native, uint eventFrame)
	{
		Assert(native);
		// check if we have touch in the array already
		for (unsigned q = 0; q < MaxTouchCount; ++q)
		{			
			TouchImpl& t = gTouches[q];
			if (t.native != native)
				continue;

			// NOTE: touch event can be finished and then begin again between InputProcess() calls (by tapping finger fast)
			// to handle such situation we assign touch to new finger and make sure old one finishes
			if (!t.isOld(eventFrame) && (t.phase == UITouchPhaseEnded || t.phase == UITouchPhaseCancelled))
				continue;
			
			Assert(t.id == q)
			return &t;
		}
		
		// find empty slot for touch
		for (unsigned q = 0; q < MaxTouchCount; ++q)
		{
			TouchImpl& t = gTouches[q];
			if (t.native != 0)
				continue;
			
			t.native = (UITouch *)native;
			Assert(t.id == q)
			return &t;
		}
		
		Assert(!"Out of free touches!");
		return 0;
	}
	Vector2f AdaptTouchPosition(float x, float y)
	{
	#if !defined(IPHONE_REMOTE)
		if (GetScreenManager().IsVerticalOrientation())
			return Vector2f(x, GetScreenManager().GetHeight() - y);
		else
			return Vector2f(y, x);
	#else
		CGRect screenBounds = [[UIScreen mainScreen] bounds];
		int w = (int)screenBounds.size.width;
		int h = (int)screenBounds.size.height;
		
		if (w == 768)
		{
				return Vector2f(x * 0.416666666666667f, (1024 - y) * 0.46875f);
		}
		else if (h == 568) // iPhone 5 / iPod 5
		{
				return Vector2f(x, (568 - y) * 0.84507f);
		}
		else
		{
				return Vector2f(x, 480 - y);
		}

	#endif
	}
	bool UpdateTouchData(UITouch const* native, uint eventFrame)
	{
		TouchImpl* touch = FindTouch(native, eventFrame);
		if (!touch)
			return false;
		
		Assert(native);
		
		UInt32 newPhase = [native phase];
		if (newPhase == UITouchPhaseBegan)
		{
			touch->timestamp = [native timestamp];
			
			// during the same frame Ended/Cancelled should never appear after Begin
			Assert(touch->phase == UITouchPhaseEnded || touch->phase == UITouchPhaseCancelled);
		}

		// handle phase priorities
		// Move is more important than Stationary
		// Ended/Cancelled is more important than Move
		// Begin is most important (during the same frame Ended/Cancelled never appears after Begin)
		if (newPhase == UITouchPhaseBegan || touch->isOld(eventFrame))
		{
			touch->tapCount = 0;
			touch->deltaPos = Vector2f(0, 0);
			touch->deltaTime = 0.0f;
			touch->phase = newPhase;
		}
		else if (newPhase == UITouchPhaseEnded || newPhase == UITouchPhaseCancelled)
			touch->phase = newPhase;
		else if (newPhase == UITouchPhaseMoved && touch->phase == UITouchPhaseStationary)
			touch->phase = newPhase;
		
		touch->pos = AdaptTouchPosition([native locationInView:nil].x, [native locationInView:nil].y);
		touch->deltaPos += touch->pos - AdaptTouchPosition([native previousLocationInView:nil].x, [native previousLocationInView:nil].y);

		touch->tapCount = [native tapCount];
		touch->deltaTime += std::max((float)([native timestamp] - touch->timestamp), 0.0f);
		touch->timestamp = [native timestamp];
		touch->eventFrame = eventFrame;
		
		// sanity checks
		touch->deltaTime = std::max(touch->deltaTime, 0.0f);
		touch->timestamp = std::max(touch->timestamp, 0.0f);

		return true;
	}
	void ResetTouches()
	{
		for (unsigned q = 0; q < MaxTouchCount; ++q)
		{
			gTouches[q].id = q;
			gTouches[q].native = 0;
			gTouches[q].eventFrame = 0;
			gTouches[q].phase = UITouchPhaseCancelled;
		}
	}
	void FreeExpiredTouches(uint eventFrame)
	{
		for (unsigned q = 0; q < MaxTouchCount; ++q)
		{
			TouchImpl& touch = gTouches[q];
			if (touch.isOld(eventFrame) && touch.isFinished())
				touch.native = 0;
		}
	}
	void UpdateStationaryTouches(uint eventFrame)
	{
		for (unsigned q = 0; q < MaxTouchCount; ++q)
		{
			TouchImpl& touch = gTouches[q];
			if (touch.isOld(eventFrame) && !touch.isFinished())
			{
				touch.phase = UITouchPhaseStationary;
				touch.deltaPos = Vector2f(0, 0);
				touch.eventFrame = eventFrame;
			}
		}
	}
	void AssertNoStaleTouches(NSSet* allTouches)
	{
		for (unsigned q = 0; q < MaxTouchCount; ++q)
		{
			if (gTouches[q].isFinished())
				continue;
			
			bool found = false;
			for (UITouch* touch in allTouches)
				found |= (gTouches[q].native == touch);
		
			Assert(found);
			if (!found)
			{
				gTouches[q].phase = UITouchPhaseCancelled;
				ErrorString("Stale touch detected!");
			}
		}
	}
}

void OnProcessTouchEvents(NSSet* touches, NSSet* allTouches)	
{
	FreeExpiredTouches(iphone::gEventFrame);
	for (UITouch* touch in touches)
		UpdateTouchData(touch, iphone::gEventFrame);
	AssertNoStaleTouches(allTouches);
}

#if !defined(DISABLE_TOUCHPAD_SIMULATION)
void CaptureEventMousePosition (InputEvent& e)
{
	e.Init();
	
	Vector2f p = GetInputManager().GetMousePosition();
	
	e.mouseRay = Ray (Vector3f (0,0,0), Vector3f (0,0,1));
	e.lastMouseRay = Ray (Vector3f (0,0,0), Vector3f (0,0,1));
	
	e.mousePos = p;
	e.mousePos.y = GetScreenManager().GetHeight() - e.mousePos.y;
	e.pressure = 1.0f;
	
	e.clickCount = 1; // @TBD: tap count
	e.camera = 0;
}
#endif
	
size_t GetActiveTouchCount()
{
	size_t count = 0;
	for (unsigned q = 0; q < MaxTouchCount; ++q)
		if (!gTouches[q].isFinished())
			++count;
	return count;
}	
	
void SimulateMouseInput()
{
	#if !defined(DISABLE_TOUCHPAD_SIMULATION)
	{ // simulate mouse buttons
		enum { MaxSimulatedMouseButtons = 3 };
		static uint prevTouchPointCount = 0;
		for (int q = 0; q < MaxSimulatedMouseButtons; ++q)
		{
			if (q < GetActiveTouchCount())
				GetInputManager().SetMouseButton(q, true);
			else if (q < prevTouchPointCount)
				GetInputManager().SetMouseButton(q, false);
		}
		prevTouchPointCount = GetActiveTouchCount();
	}
	
	{ // simulate trackpad
		uint activeTouchCount = 0;
		Vector2f pos(0.0f, 0.0f);
		static Vector2f prevPos(0.0f, 0.0f);
		
		// average all touch positions/movements
		for (unsigned q = 0; q < MaxTouchCount; ++q)
		{
			TouchImpl& touch = gTouches[q];
			if (touch.isFinished())
				continue;
			
			pos += touch.pos;
			++activeTouchCount;
		}
		
		if (activeTouchCount > 0)
		{
			float invCount = 1.0f / (float)activeTouchCount;
			pos.x *= invCount;
			pos.y *= invCount;
			
			GetInputManager().SetMousePosition(pos);
			GetInputManager().SetMouseDelta(Vector3f(pos.x - prevPos.x, pos.y - prevPos.y, 0.0f));
			prevPos = pos;
		}
	}
	
	{ // simulate Unity InputEvents
		InputEvent ie;

		if (SqrMagnitude(GetInputManager().GetMouseDelta()) > 1e-6)
		{
			CaptureEventMousePosition (ie);
			ie.type = InputEvent::kMouseMove;
			ie.button = 0;
			
			if (GetInputManager().GetMouseButton(0))
			{
				ie.type = InputEvent::kMouseDrag;
				ie.button |= InputEvent::kLeftButton;
			}
			if (GetInputManager().GetMouseButton(1))
			{
				ie.type = InputEvent::kMouseDrag;
				ie.button |= InputEvent::kRightButton;
			}
			
			GetGUIManager().QueueEvent (ie);
		}
		
		static bool lastMouseB0 = false;
		if (GetInputManager().GetMouseButton(0) != lastMouseB0)
		{
			CaptureEventMousePosition (ie);
			ie.button = InputEvent::kLeftButton;
			ie.type = GetInputManager().GetMouseButton(0) ? InputEvent::kMouseDown : InputEvent::kMouseUp;
			GetGUIManager().QueueEvent (ie);
			lastMouseB0 = GetInputManager().GetMouseButton(0);
		}
		
		static bool lastMouseB1 = false;
		if (GetInputManager().GetMouseButton(1) != lastMouseB1)
		{
			CaptureEventMousePosition (ie);
			ie.button = InputEvent::kRightButton;
			ie.type = GetInputManager().GetMouseButton(1) ? InputEvent::kMouseDown : InputEvent::kMouseUp;
			GetGUIManager().QueueEvent (ie);
			lastMouseB1 = GetInputManager().GetMouseButton(1);
		}
	}
	#endif
}

typedef std::vector<Acceleration> AccelerationBufferT;
AccelerationBufferT gAccelerations;
int gLastAccelerationEventFrame = 0;
NSTimeInterval gLastAccelerationTimestamp = -1;
Vector3f gLastAcceleration = Vector3f(0,0,0);
	
void ResetAccelerations()
{
	gAccelerations.resize(0);
	gLastAcceleration = Vector3f(0,0,0);
}
void OnDidAccelerate(Vector3f const& acceleration, NSTimeInterval timestamp)
{
	if (gLastAccelerationEventFrame != gEventFrame)
		ResetAccelerations();
		
	const float dt = (gLastAccelerationTimestamp > 0)? (timestamp - gLastAccelerationTimestamp): 0.0f;
	
	Acceleration newAcceleration;
	newAcceleration.acc  = acceleration;
	newAcceleration.deltaTime = dt;
	gAccelerations.push_back(newAcceleration);
	
	gLastAcceleration = acceleration;
	gLastAccelerationTimestamp = timestamp;
	gLastAccelerationEventFrame = gEventFrame;
}
size_t GetAccelerationCount()
{
	return gAccelerations.size();
}
void GetAcceleration(unsigned index, Acceleration& acceleration)
{
	Assert(index < gAccelerations.size());
	acceleration = gAccelerations[index];
}
Vector3f GetAcceleration()
{
	return gLastAcceleration;
}
	
size_t GetTouchCount()
{
	//printf_console("GetTouchCount:: %d ::", gEventFrame);
	size_t count = 0;
	for (unsigned q = 0; q < MaxTouchCount; ++q)
	{
		if (gTouches[q].isNow(iphone::gEventFrame - 1) && !gTouches[q].isEmpty())
			++count;
		//printf_console("%d ", gTouches[q].eventFrame);
	}
	
	//printf_console("::: GetTouchCount ::: %d\n", count);
	return count;
}
bool GetTouch(unsigned index, Touch& touch)
{
	size_t count = 0;
	for (unsigned q = 0; q < MaxTouchCount; ++q)
		if (gTouches[q].isNow(iphone::gEventFrame - 1) && !gTouches[q].isEmpty())
		{
			if (count++ != index) continue;
			
			Assert(!gTouches[q].isEmpty());
			touch = gTouches[q];
			return true;
		}
	return false;
}
	
bool IsMultiTouchEnabled()
{
	return ([UIApplication sharedApplication].keyWindow.multipleTouchEnabled == YES);
}
void SetMultiTouchEnabled(bool flag)
{
	// @TBD: not implemented
	//[[UIApplication sharedApplication].keyWindow setMultipleTouchEnabled:flag];
	[[UIApplication sharedApplication].keyWindow setMultipleTouchEnabled:YES];
}

unsigned GetOrientation()
{
	if ([UIDevice currentDevice].generatesDeviceOrientationNotifications == NO)
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	return ([UIDevice currentDevice].orientation);
}
void ShutdownDeviceOrientation()
{
	if ([UIDevice currentDevice].generatesDeviceOrientationNotifications == YES)
		[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}
}

void ClearInputEvents () {}

// Clears all input axes, keydowns, mouse buttons and sets up how event handlers
void ResetInput () {}
void ResetInputAfterPause ()
{
	// @TBD: correctly cleanup touch events and their timestamps
}

void InputInit()
{
	iphone::gEventFrame = 1;
	iphone::ResetTouches();
	iphone::ResetAccelerations();
}
void InputProcess()
{
	Assert((iphone::gEventFrame != 0) && "Must call InputInit() before");
	iphone::UpdateStationaryTouches(iphone::gEventFrame);	
	
	++iphone::gEventFrame;

	iphone::SimulateMouseInput();
}
void InputShutdown ()
{
	iphone::ResetTouches();
	iphone::ResetAccelerations();
	iphone::ShutdownDeviceOrientation();
}
