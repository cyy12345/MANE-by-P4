#vlc-wrapper -vvv Foreman/foreman.264 --sout \
#"#transcode{vcodec=h264,vb=25,scale=0,width/height=176/144,acodec=mpga,ab=128,channels=2,samplerate=44100}:rtp{dst=10.0.0.3,port=1212,mux=ts,ttl=10}"
#vlc-wrapper -vvv container/container.264 --sout \
#"#transcode{vcodec=h264,vb=25,scale=0,width/height=176/144,acodec=mpga,ab=128,channels=2,samplerate=44100}:rtp{dst=10.0.0.3,port=1212,mux=ts,ttl=10}"
#vlc-wrapper -vvv Bridge/bridge.264 --sout \
#"#transcode{vcodec=h264,vb=25,scale=0,width/height=176/144,acodec=mpga,ab=128,channels=2,samplerate=44100}:rtp{dst=10.0.0.3,port=1212,mux=ts,ttl=10}"
#~/test_jrtp/test_jrtp
FILE_NAME=foreman
~/jsvm-master/bin/H264AVCDecoderLibTestStatic $FILE_NAME.264 $FILE_NAME.yuv > originaldecoderoutput.txt
~/jsvm-master/bin/BitStreamExtractorStaticd -pt originaltrace.txt $FILE_NAME.264
python2 ~/svef-1.5/f-nstamp originaldecoderoutput.txt originaltrace.txt > originaltrace-frameno.txt
~/svef-1.5/streamer originaltrace-frameno.txt 25 10.0.0.3 4455 $FILE_NAME.264 1 > sent.txt
