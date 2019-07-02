#!/bin/sh

# Download new JSON and grab builds of both new and old JSON
$(curl -s 'https://launchermeta.mojang.com/mc/game/version_manifest.json' > mcn.json)
nbuild=$(cat mcn.json | jq -r '.latest.release')
obuild=$(cat mc.json | jq -r '.latest.release')

# Check if release numbers match or not
if [ "$nbuild" = "$obuild" ]
then
	# Disregard update and remove new JSON as it matches
	echo "You are in the latest MC server version!"
	rm -rf mcn.json
else
	# Different ID detects new version
	echo "New version detected!"
	
	# Stop service
	echo "Stopping server..."
	sudo systemctl stop mc
	
	# Announce installation
	echo "Now installing..."
	
	# Remove old JSON and swap it with new one
	rm -rf mc.json
	mv mcn.json mc.json
	
	# Count the number of versions recognized by JSON array.
	# Needed for buffer overflow prevention later in the script.
	vercount=$(expr $(cat mc.json | jq -r '.versions | length') - 1)
	
	# Counter values
	arrayid=0
	gamematch=0
	
	# Until gamematch is 1 (true), keep running script.
	# Will try to find matching version out of its master list.
	until [ "$gamematch" -eq 1 ]
	do
		# Grab current array's game ID to compare
		gameid=$(cat mc.json | jq -r .versions[$arrayid].id)
		
		# If array game ID matches the new build number
		# from earlier, then proceed. Loop otherwise.
		if [ "$gameid" = "$nbuild" ]
		then
			# Grab the URL where the version's JSON metadata is located
			verjson=$(cat mc.json | jq -r .versions[$arrayid].url)
			
			# Grab the URL of the server JAR from the version's JSON metadata
			jarurl=$(curl -s $verjson | jq -r '.downloads.server.url')
			
			# Remove old JAR and install new one
			cd mc
			rm -rf server.jar
			wget $jarurl
			cd ~
			
			# Increment gamematch to end loop
			let "gamematch++"
		fi
		
		# Increment array index
		let "arrayid++"
		
		# If statement that prevents possible buffer overflow
        	if [ $arrayid -gt $vercount ]
        	then
                	echo "New version not recognized. Stopping installation..."
                	let "gamematch++"
        	fi
		
		# Restart server
		echo "Starting server..."
		sudo systemctl start mc
	done
fi
