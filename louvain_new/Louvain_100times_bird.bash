

#!/bin/bash

./convert -i ./input/BIRD_10km_Louvain.txt -o ./input/BIRD_10km.bin

# changing t values from 1 to 100
export itime=1
export ntime=100


while [ ${itime} -le ${ntime} ]; do
	
	# repeat 100 times for each t value
	export try_id=1
	export nst=100

	while [ ${try_id} -le ${nst} ]; do
		echo "Welcome $try_id times.........................."
		./louvain ./input/BIRD_10km.bin -l -1 -v  -t ${itime} > ./output/BIRD_10km_reso_${itime}_S_${try_id}.tree
	
	
		r=$(./hierarchy ./output/BIRD_10km_reso_${itime}_S_${try_id}.tree | awk 'NR==1' |  grep -o [0-9])
		((r2=r-1))
		echo ${r2}

		./hierarchy ./output/BIRD_10km_reso_${itime}_S_${try_id}.tree -l $r2 > ./output/BIRD_10km_reso_${itime}_S_${try_id}.txt

		let try_id=try_id+1
	
	done
	
	
	let itime=itime+1
done

end
