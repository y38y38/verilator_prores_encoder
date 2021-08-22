rm -rf ./tmp
mkdir -p ./tmp/
for file_name in ../prores_decoder/test/input/*.yuv ;do
    OUT_NAME=`basename $file_name`
    ./obj_dir/Vwrapper -l ./luma_matrix.txt -c ./chroma_matrix.txt -q ./qscale_128x16.txt -h 128 -v 16 -m 8 -i ${file_name}  -o ./tmp/${OUT_NAME%.yuv}.bin  
    ../prores_decoder/decoder ./tmp/${OUT_NAME%.yuv}.bin ./tmp/${OUT_NAME%.yuv}_dec.yuv 
    diff ./tmp/${OUT_NAME%.yuv}_dec.yuv ../prores_decoder//test/org/${OUT_NAME%.yuv}_dec.yuv
    #../../yuv/sn16/sn16 ${file_name} ../prores_decoder/tmp/${OUT_NAME%.yuv}_dec.yuv 128 16
done
