$name = "7x7_color"
./Targets/Decode/Build/BJpegDecode.exe ./Temp/jpgs/"$name".jpg ./Temp/jpgs/"$name".rgba                                    | Out-File -Encoding utf8 .\Temp\a.txt
if ($?) {
./Targets/Encode/Build/BJpegEncode.exe ./Temp/jpgs/"$name".rgba ./Temp/jpgs/"$name".def.jpg ./Temp/jpgs/"$name".out.jpg 11 | Out-File -Encoding utf8 .\Temp\b0.txt
if ($?) {
./Targets/Encode/Build/BJpegEncode.exe ./Temp/jpgs/"$name".rgba ./Temp/jpgs/"$name".def.jpg ./Temp/jpgs/"$name".out.jpg 22 | Out-File -Encoding utf8 .\Temp\b.txt
if ($?) {
./Targets/Decode/Build/BJpegDecode.exe ./Temp/jpgs/"$name".out.jpg ./Temp/jpgs/"$name".out.rgba                            | Out-File -Encoding utf8 .\Temp\c.txt
}
}
}