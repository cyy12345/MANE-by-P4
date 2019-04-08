/*
   This IPv4 example uses the background thread itself to process all packets.
   You can use example one to send data to the session that's created in this
   example.
*/

#include "jrtplib3/rtpsession.h"
#include "jrtplib3/rtpsessionparams.h"
#include "jrtplib3/rtpudpv4transmitter.h"
#include "jrtplib3/rtpipv4address.h"
#include "jrtplib3/rtptimeutilities.h"
#include "jrtplib3/rtppacket.h"
#include <jrtplib3/rtpsourcedata.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <string>

using namespace jrtplib;

#ifdef RTP_SUPPORT_THREAD

//
// This function checks if there was a RTP error. If so, it displays an error
// message and exists.
//


size_t len;
uint8_t *loaddata;
uint8_t buff[1024*100] = {0};
uint8_t start_bits[4] = {0,0,0,1};
int pos = 0;
FILE *fd = fopen("./recv.264","wb+");

void checkerror(int rtperr)
{
	if (rtperr < 0)
	{
		std::cout << "ERROR: " << RTPGetErrorString(rtperr) << std::endl;
		exit(-1);
	}
}

//
// The new class routine
//

class MyRTPSession : public RTPSession
{
protected:
	void OnPollThreadStep();
	void ProcessRTPPacket(const RTPSourceData &srcdat,const RTPPacket &rtppack);
};

void MyRTPSession::OnPollThreadStep()
{
	BeginDataAccess();
		
	// check incoming packets
	if (GotoFirstSourceWithData())
	{
		do
		{
			RTPPacket *pack;
			RTPSourceData *srcdat;
			
			srcdat = GetCurrentSourceInfo();
			
			while ((pack = GetNextPacket()) != NULL)
			{
				ProcessRTPPacket(*srcdat,*pack);
				DeletePacket(pack);
			}
		} while (GotoNextSourceWithData());
	}
		
	EndDataAccess();
}

bool isFUid(uint8_t* loaddata){
	if((*loaddata & 31 )==28){
		return true;
	}
	return false;
}

void MyRTPSession::ProcessRTPPacket(const RTPSourceData &srcdat,const RTPPacket &rtppack)
{

	// You can inspect the packet and the source's info here
	std::cout << "Got packet " << rtppack.GetExtendedSequenceNumber() << " from SSRC " << srcdat.GetSSRC() << std::endl;
	loaddata = rtppack.GetPayloadData();
	//std::cout<<loaddata<<std::endl;
	len		 = rtppack.GetPayloadLength();
	//std::cout<<len<<std::endl;
	if(rtppack.GetPayloadType()==96){
		//std::cout<<rtppack.HasMarker()<<std::endl;
		if(rtppack.HasMarker()) // the last packet
			{
				if(!isFUid(loaddata)){  //not FU
					memcpy(&buff[pos],start_bits,4);
					pos=pos+4;
				}else{
					if(((*(loaddata+1))>>7)& 1){  //start FU
						memcpy(&buff[pos],start_bits,4);
						pos=pos+4;
						loaddata=loaddata+1;
						uint8_t temp = *loaddata & 31;
						*loaddata = 0;
						*loaddata = temp +96;  // replace nalu header
						len=len-1;
					}else{
						loaddata = loaddata+2;
						len = len-2;
					}
				}
				memcpy(&buff[pos],loaddata,len);
				//fwrite(start_bit,3,pos+3,fd);	
				fwrite(buff, 1, pos+len, fd);
				pos = 0;
			}
		else
			{
				if(!isFUid(loaddata)){  //not FU
					memcpy(&buff[pos],start_bits,4);
					pos=pos+4;
				}else{
					//std::cout<<(*(loaddata++)>>8 & 1)<<std::endl;
					if(((*(loaddata+1))>>7 )& 1){  //start FU
						memcpy(&buff[pos],start_bits,4);
						pos=pos+4;
						loaddata=loaddata+1;
						uint8_t temp = *loaddata & 31;
						*loaddata = 0;
						*loaddata = temp +96;  // replace nalu header
						len=len-1;
					}else{

						loaddata = loaddata+2; //not a start FU, just ignore first 2 bytes
						len = len-2;
					}

				}
				memcpy(&buff[pos],loaddata,len);
				pos = pos + len;	
			}
	}
}

//
// The main routine
// 

int main(void)
{
#ifdef RTP_SOCKETTYPE_WINSOCK
	WSADATA dat;
	WSAStartup(MAKEWORD(2,2),&dat);
#endif // RTP_SOCKETTYPE_WINSOCK
	
	MyRTPSession sess;
	uint16_t portbase;
	std::string ipstr;
	int status,num;

        // First, we'll ask for the necessary information
		
	// std::cout << "Enter local portbase:" << std::endl;
	// std::cin >> portbase;
	// std::cout << std::endl;
	portbase = 9000;
	// std::cout << std::endl;
	// std::cout << "Number of seconds you wish to wait:" << std::endl;
	// std::cin >> num;
	num = 30;
	
	// Now, we'll create a RTP session, set the destination
	// and poll for incoming data.
	
	RTPUDPv4TransmissionParams transparams;
	RTPSessionParams sessparams;
	
	// IMPORTANT: The local timestamp unit MUST be set, otherwise
	//            RTCP Sender Report info will be calculated wrong
	// In this case, we'll be just use 8000 samples per second.
	sessparams.SetOwnTimestampUnit(1.0/90000.0);		
	
	transparams.SetPortbase(portbase);
	status = sess.Create(sessparams,&transparams);	
	checkerror(status);
	
	// Wait a number of seconds
	RTPTime::Wait(RTPTime(num,0));
	
	sess.BYEDestroy(RTPTime(10,0),0,0);

#ifdef RTP_SOCKETTYPE_WINSOCK
	WSACleanup();
#endif // RTP_SOCKETTYPE_WINSOCK
	return 0;
}

#else

int main(void)
{
	std::cerr << "Thread support is required for this example" << std::endl;
	return 0;
}

#endif // RTP_SUPPORT_THREAD