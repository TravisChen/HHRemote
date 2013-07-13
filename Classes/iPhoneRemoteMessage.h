#ifndef REMOTE_MESSAGE_H
#define REMOTE_MESSAGE_H

#include "iPhoneRemoteVersion.h"

struct RemoteMessage
{
    inline RemoteMessage(unsigned int t, unsigned int i,
                         unsigned int l) :
        type(t),
        id(i),
        length(l) {}

    enum MessageType
    {
        Exit = 0,
        ImageBlock = 1,
        Input = 2,
        Ping = 3,
        InvalidLicense = 4,
        InvalidVersion = 5,
        UnsupportedPlatform = 6
    };

    unsigned int type;
    unsigned int id;
    unsigned int length;
};

struct ImageMessage : public RemoteMessage
{
    inline ImageMessage() :
        RemoteMessage(RemoteMessage::ImageBlock, 0, 0) { }

    int width;
    int height;
    int compression;
    int frameId;
    int frameY;
    int compressedSize;

    // Image data immediately follows.
};

struct PingMessage : public RemoteMessage
{
    int width;
    int height;
    int m_BlockWidth;
    int m_BlockHeight;
    int m_SendImages;
    unsigned int m_Version;

    inline PingMessage(int w, int h, int bw, int bh, bool si) :
        width(w),
        height(h),
        m_BlockWidth(bw),
        m_BlockHeight(bh),
        m_SendImages(si),
        m_Version(IPHONE_REMOTE_VERSION),
        RemoteMessage(RemoteMessage::Ping, 0, sizeof(PingMessage)) { }
};


#endif
