rm -rf ./tmp00
mkdir -p ./tmp00/
for file_name in ../prores_decoder/test/input_sample10bit/*00.yuv ;do
    OUT_NAME=`basename $file_name`
    ./obj_dir/Vwrapper -l ./luma_matrix.txt -c ./chroma_matrix.txt -q ./qscale_128x16.txt -h 128 -v 16 -m 8 -i ${file_name}  -o ./tmp00/${OUT_NAME%.yuv}.bin  
    diff ./tmp00/${OUT_NAME%.yuv}.bin ../prores_decoder/test/output_sample10bit/${OUT_NAME%.yuv}.bin
done
#./all_test/tt0.sh &
#./all_test/tt1.sh &
#./all_test/tt2.sh &
#./all_test/tt3.sh &
#./all_test/tt4.sh &
#./all_test/tt5.sh &
#./all_test/tt6.sh &
#./all_test/tt7.sh &
#./all_test/tt8.sh &
#./all_test/tt9.sh &
