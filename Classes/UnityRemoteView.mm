#import "UnityRemoteView.h"
#import "Setup.h"
#import "iPhoneRemoteInput.h"
#import "iPhoneRemoteInputImpl.h"
#import "iPhoneRemoteInputPackets.h"
#include "iPhoneRemoteVersion.h"
#include "iPhoneRemoteMessage.h"
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <algorithm>

static double GetTimeSinceStartup ()
{
	static NSDate* gStartDate = NULL;

	if (gStartDate == NULL)
    {
		gStartDate = [[NSDate alloc]init];
    }

	return -[gStartDate timeIntervalSinceNow];
}

void InputInit();
void InputProcess();
void InputShutdown();
void NotifyDisconnectSocket();
void NotifyDisconnectSocketFailure (const char* message);

@implementation UnityRemoteView

- (id)initWithFrame:(CGRect)frame editorAddress:(struct sockaddr_in *) addr
{
	if (self = [super initWithFrame:frame])
	{
        memcpy(&m_Sin, addr, sizeof(struct sockaddr_in));

        m_LastScreenshotTime = GetTimeSinceStartup();
        m_LastSentMessageID = 1;
        m_LastReceivedMessageID = 0;
        m_ShowImages = true;

		[[UIAccelerometer sharedAccelerometer] setDelegate:nil];
		[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0f / (float)AccelerometerFPS)];
		[[UIAccelerometer sharedAccelerometer] setDelegate:self];

		InputInit();

		m_UpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f / (float)FPS target:self selector:@selector(Update) userInfo:nil repeats:YES];
		[m_UpdateTimer retain];

        m_fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

        if (m_fd == -1)
        {
            NSLog(@"Cannot create client socket");
        }

        int flags;

        if ((flags = fcntl(m_fd, F_GETFL, 0)) == -1)
        {
            flags = 0;
        }
        
        fcntl(m_fd, F_SETFL, flags | O_NONBLOCK | O_NDELAY);
	}

	return self;
}

- (void)sendMessage:(RemoteMessage *)data length:(int)len
{
    data->id = m_LastSentMessageID++;

    ssize_t bytesSent = sendto(m_fd, (const void *)data, len, 0,
        (struct sockaddr *)&m_Sin, sizeof(struct sockaddr_in));

    if (bytesSent == -1)
    {
        NSLog(@"Error: %s", strerror(errno));
        NotifyDisconnectSocketFailure("Error while sending message to Editor");
    }
}

- (void)shutdown
{
	[m_UpdateTimer invalidate];
	[m_UpdateTimer release];

	InputShutdown();

	[[UIAccelerometer sharedAccelerometer] setDelegate:nil];

    close(m_fd);
}


- (void)dealloc
{
	[super dealloc];
}

- (void)Update
{
    RemoteMessage *msg = (RemoteMessage *)m_block;

    socklen_t addrLength;
    bool anyImageData = false;

	InputProcess();

    for (int i = 0; i < 32; i++)
    {
        ssize_t size = 0;
        struct sockaddr_in sin_other;

        if ((size = recvfrom(m_fd, msg, kReceiveBufferSize,
            0, (struct sockaddr *)&sin_other, &addrLength)) != -1)
        {
			// that's not actually cool, but we dont't want to use reliable udp for communication, and we really need to proceed editor disconnect 
            if (m_LastReceivedMessageID != 0 && msg->id < m_LastReceivedMessageID && msg->type != RemoteMessage::Exit )
            {
                NSLog(@"Out-of-sequence datagram dropped");
                continue;
            }

            switch (msg->type)
            {
                case RemoteMessage::ImageBlock: {
                        ImageMessage *im = (ImageMessage *)msg;
                        unsigned char *jpegData = ((unsigned char *)im) + sizeof(ImageMessage);
                        [self initImageAtIndex:im->frameY data:jpegData
                                length:im->compressedSize];
                        anyImageData = true;
                        m_LastScreenshotTime = GetTimeSinceStartup();
                    }

                    break;
                case RemoteMessage::InvalidLicense:
                    NotifyDisconnectSocketFailure("iPhone license is not valid");
                    return;
				case RemoteMessage::Exit:
					NotifyDisconnectSocketFailure("Editor disconnected");
					return;
                case RemoteMessage::InvalidVersion:
                    NotifyDisconnectSocketFailure("This remote is not compatible with Editor version");
                    return;
                case RemoteMessage::UnsupportedPlatform:
                    NotifyDisconnectSocketFailure("Selected platform is not supported by Unity Remote");
                    return;
            }

            continue;
        }

        break;
    }


    static iphone::InputPacket packet;
    static iphone::InputPacket lastPacket;

    packet.accelerator = iphone::GetAcceleration();
    packet.orientation = iphone::GetOrientation();
    packet.touchCount = iphone::GetTouchCount();
    
    Assert(packet.touchCount <= iphone::InputPacket::MaxTouchCount);

    for (uint q = 0; q < packet.touchCount; ++q)
    {
        bool result = GetTouch(q, packet.touches[q]);
        Assert(result);
    }

    static bool firstRun = true;

    double timeNow = GetTimeSinceStartup();

    if (!firstRun && ((timeNow - m_LastScreenshotTime) > 5.0) && !showStatusBanner)
    {
        showStatusBanner = true;
        [self redrawScreen];
        return;
    }

    if (firstRun || (memcmp(&packet, &lastPacket, sizeof(packet)) != 0))
    {
        msg->type = RemoteMessage::Input;
        msg->id = 0;

        size_t packetSize = write((unsigned char *)msg + sizeof(RemoteMessage),
            packet) + sizeof(RemoteMessage);
        msg->length = packetSize;

        [self sendMessage:msg length: packetSize];

        lastPacket = packet;
        firstRun = false;
    }


    // Send ping request if necessary

    static int frameCounter = 0;

    if (firstRun || (frameCounter++ % (SyncImageEachNthFrame * 5) == 0))
    {
        PingMessage pm(ScreenWidth, ScreenHeight, BlockWidth, BlockHeight,
                       m_ShowImages);

        [self sendMessage:&pm length: sizeof(pm)];
    }

	if (anyImageData)
    {
        [self redrawScreen];
    }
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	iphone::OnProcessTouchEvents(touches, [event allTouches]);
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	iphone::OnProcessTouchEvents(touches, [event allTouches]);
}

- (void)touchesCanceled:(NSSet*)touches withEvent:(UIEvent*)event
{
	iphone::OnProcessTouchEvents(touches, [event allTouches]);
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	iphone::OnProcessTouchEvents(touches, [event allTouches]);
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
	iphone::OnDidAccelerate(Vector3f(acceleration.x, acceleration.y, acceleration.z), acceleration.timestamp);
}

- (void)setShowImages:(BOOL)toggle
{
    m_ShowImages = toggle;
}

@end
