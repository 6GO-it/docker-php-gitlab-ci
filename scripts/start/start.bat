docker stop %1
docker rm -f %1
docker run ^
	--name %1 ^
	-d ^
	-v "%cd%:/root" ^
	%2
