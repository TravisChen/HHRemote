#ifndef UNITY_MINI_CONFIG_
#define UNITY_MINI_CONFIG_

#include <stddef.h>

typedef unsigned char                   UInt8;
typedef signed char                     SInt8;
typedef unsigned short                  UInt16;
typedef signed short                    SInt16;

#if __LP64__
typedef unsigned int                    UInt32;
typedef signed int                      SInt32;
#else
typedef unsigned long                   UInt32;
typedef signed long                     SInt32;
#endif

typedef unsigned int					uint;

#define AssertIf(x)           { if (x) printf ("%s %s %i\n", x, __FILE__, __LINE__); }
#define Assert(x)             { if (x) ; else printf ("No Assert String available %s %i\n", __FILE__, __LINE__); }
#define AssertString(x)       { printf ("Assert: %s %s %i\n", x, __FILE__, __LINE__); }
#define ErrorString(x)		  { printf ("Error: %s %s %i\n", x, __FILE__, __LINE__); }

#define IPHONE_REMOTE 1
#define DISABLE_TOUCHPAD_SIMULATION IPHONE_REMOTE

#endif