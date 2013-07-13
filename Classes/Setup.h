
enum { FPS = 60, AccelerometerFPS = 30 };

#define IMAGE_320x448 0
#define IMAGE_192x384 0
#define IMAGE_192x320 0
#define IMAGE_192x256 0
#define IMAGE_160x256 1
#define IMAGE_160x240 0

#if IMAGE_320x448
enum {
    ScreenWidth = 320,
    ScreenHeight = 448,
    BlockWidth = 320,
    BlockWidthPow2 = 512,
    BlockHeight = 32,
    BlockHeightPow2 = 32,
    BlockRows = 14,
    SyncImageEachNthFrame = 6
};
#elif IMAGE_192x384
enum {
    ScreenWidth = 192,
    ScreenHeight = 384,
    BlockWidth = 192,
    BlockWidthPow2 = 256,
    BlockHeight = 48,
    BlockHeightPow2 = 64,
    BlockRows = 8,
    SyncImageEachNthFrame = 3
};
#elif IMAGE_192x320
enum {
    ScreenWidth = 192,
    ScreenHeight = 320,
    BlockWidth = 192,
    BlockWidthPow2 = 256,
    BlockHeight = 48,
    BlockHeightPow2 = 64,
    BlockRows = 7,
    SyncImageEachNthFrame = 1
};
#elif IMAGE_192x256
enum {
    ScreenWidth = 192,
    ScreenHeight = 256,
    BlockWidth = 192,
    BlockWidthPow2 = 256,
    BlockHeight = 48,
    BlockHeightPow2 = 64,
    BlockRows = 6,
    SyncImageEachNthFrame = 1
};
#elif IMAGE_160x256
enum {
    ScreenWidth = 160,
    ScreenHeight = 256,
    BlockWidth = 160,
    BlockWidthPow2 = 256,
    BlockHeight = 64,
    BlockHeightPow2 = 64,
    BlockRows = 4,
    SyncImageEachNthFrame = 1
};
#elif IMAGE_160x240
enum {
    ScreenWidth = 160,
    ScreenHeight = 240,
    BlockWidth = 160,
    BlockWidthPow2 = 256,
    BlockHeight = 64,
    BlockHeightPow2 = 64,
    BlockRows = 4,
    SyncImageEachNthFrame = 1
};
#endif

enum {
    JpegQuality = 50
};
