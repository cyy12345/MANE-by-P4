FILE_NAME=foreman_only_quality
~/evalvid-2.7/psnr 352 288 420 $FILE_NAME.yuv $FILE_NAME-filtered.yuv > psnr.txt
~/evalvid-2.7/psnr 352 288 420 $FILE_NAME.yuv $FILE_NAME-filtered.yuv ssim> ssim.txt