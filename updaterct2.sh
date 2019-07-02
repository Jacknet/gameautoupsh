#!/bin/sh

# Grab build IDs of new rct2 JSON and old rct2 JSON
$(curl -s 'https://openrct2.org/altapi/?command=get-latest-download&flavourId=9&gitBranch=develop' > rct2n.json)
nbuild=$(cat rct2n.json | jq -r '.buildId')
obuild=$(cat rct2.json | jq -r '.buildId')

# Check if build IDs match or not
if [ "$nbuild" -eq "$obuild" ]
then
	# Disregard update and remove new JSON as it matches
	echo "You are in the latest OpenRCT2 version!"
	rm -rf rct2n.json
else
	# Different ID detects new version and installs
	echo "New version detected!"
	
	# Stop service and copy most recent autosaved map
	echo "Stopping server..."
	sudo systemctl stop rct2
	echo "Saving current map from autosave..."
	rm -rf rct2/save/park.sv6
	cd rct2/save/autosave
	save=$(ls -t autosave* | head -1)
	cp $save ../park.sv6
	cd ~
	
	# Announce installation
        echo "Now installing..."
	
	# Removes old JSON and swaps it with new JSON
	rm -rf rct2.json
	mv rct2n.json rct2.json
	
	# Retrieves new version by the URL on the JSON
	url=$(cat rct2.json | jq -r '.url')
	wget -O rct2.tar.gz $url
	
	# Removes old version and installs new one
	rm -rf OpenRCT2
	tar -xzf rct2.tar.gz
	rm -rf rct2.tar.gz
	
	# Restart server
	echo "Starting server..."
	sudo systemctl start rct2
fi
