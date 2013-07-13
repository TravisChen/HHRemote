#ifndef UNITY_IPHONE_INPUT_
#define UNITY_IPHONE_INPUT_

#include "iPhoneRemoteVector2.h"
#include "iPhoneRemoteVector3.h"

namespace iphone {

// touchscreen
struct Touch
{
	UInt32 id;
	Vector2f pos;
	Vector2f deltaPos;
	float deltaTime;
	UInt32 tapCount;
	UInt32 phase;
};

size_t GetTouchCount();
bool GetTouch(unsigned index, Touch& touch);

bool IsMultiTouchEnabled();
void SetMultiTouchEnabled(bool flag = true);


// accelerometer
struct Acceleration
{
	Vector3f acc;
	float deltaTime;
};

size_t GetAccelerationCount();
void GetAcceleration(unsigned index, Acceleration& acceleration);
Vector3f GetAcceleration();


// orientation
unsigned GetOrientation();

}

#endif
