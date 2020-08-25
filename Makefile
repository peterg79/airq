
.PHONY: upload
upload:
		~/.local/bin/pipenv run ../../4refr0nt/luatool/luatool/luatool.py --port /dev/tty.usbserial-1490 --src config.lua --baud 115200
		~/.local/bin/pipenv run ../../4refr0nt/luatool/luatool/luatool.py --port /dev/tty.usbserial-1490 --src dht22.lua --baud 115200
		~/.local/bin/pipenv run ../../4refr0nt/luatool/luatool/luatool.py --port /dev/tty.usbserial-1490 --src init.lua --dofile --baud 115200

.PHONY: test
test:
		~/.local/bin/pipenv run ../../4refr0nt/luatool/luatool/luatool.py --port /dev/tty.usbserial-1490 --src graphics_test.lua --dofile --baud 115200

.PHONY: luacheck
luacheck:
		luacheck *.lua

.PHONY: nodemcu
nodemcu:
	cp user_modules.h ../../nodemcu/nodemcu-firmware/app/include/user_modules.h
	cp u8g2_fonts.h ../../nodemcu/nodemcu-firmware/app/include/u8g2_fonts.h
	pushd ../../nodemcu/nodemcu-firmware; docker run --rm -ti -v `pwd`:/opt/nodemcu-firmware marcelstoer/nodemcu-build build; popd
