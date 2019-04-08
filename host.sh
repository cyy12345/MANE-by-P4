#vlc-wrapper ~/test_jrtp/player.sdp &  && fg
#vlc-wrapper rtp://@:1212
#~/test_jrtp/jrtplib_receive
FILE_NAME=foreman
~/svef-1.5/receiver 4455 out.264 20000 > receivedtrace.txt
python2 ~/svef-1.5/nalufilter originaltrace-frameno.txt receivedtrace.txt 5000 25 > filteredtrace.txt
~/jsvm-master/bin/BitStreamExtractorStaticd $FILE_NAME.264 $FILE_NAME-filtered.264 -et filteredtrace.txt  
~/jsvm-master/bin/H264AVCDecoderLibTestStaticd $FILE_NAME-filtered.264 $FILE_NAME-filtered.yuv 
#python2 ~/svef-1.5/framefiller filteredtrace.txt 152064 300 foreman-filtered.yuv foreman-concealed.yuv