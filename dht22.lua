-- init mqtt client with logins, keepalive timer 120sec
local m = mqtt.Client("esp8266", 120, mqtt_user, mqtt_password)

-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline"
-- to topic "/lwt" if client don't send keepalive packet
m:lwt("lwt", "offline", 0, 0)

m:on("connect", function(client) print ("connected") end)
-- m:on("connfail", function(client, reason) print ("connection failed", reason) end)
m:on("offline", function(client) print ("offline") end)

-- on publish message receive event
m:on("message", function(client, topic, data)
  print(topic .. ":" )
  if data ~= nil then
    print(data)
  end
end)

-- on publish overflow receive event
m:on("overflow", function(client, topic, data)
  print(topic .. " partial overflowed message: " .. data )
end)

print("Connecting to MQTT broker...")
m:connect(mqtt_ip, mqtt_port, mqtt_secure, function(client)
    print("connected")
    -- Calling subscribe/publish only makes sense once the connection
    -- was successfully established. You can do that either here in the
    -- 'connect' callback or you need to otherwise make sure the
    -- connection was established (e.g. tracking connection status or in
    -- m:on("connect", function)).

    -- subscribe topic with qos = 0
    -- client:subscribe("/topic", 0, function(client) print("subscribe success") end)
    -- publish a message with data = hello, QoS = 0, retain = 0
    -- client:publish("/topic", "hello", 0, 0, function(client) print("sent") end)
end,
function(client, reason)
    print("failed reason: " .. reason)
end)

-- init display
local disp
-- setup I2c and connect display
local function init_i2c_display()
    local sla = 0x3c
    i2c.setup(0, u8g2_sda, u8g2_scl, i2c.SLOW)
    disp = u8g2.ssd1306_i2c_128x64_noname(0, sla)
end

local function u8g2_prepare()
   disp:setFont(u8g2_font)
   disp:setFontRefHeightExtendedText()
   disp:setDrawColor(1)
   disp:setFontPosTop()
   disp:setFontDirection(0)
 end

local function toF(c)
    return c * 9 / 5 + 32
end

init_i2c_display()
u8g2_prepare()

print("Collecting Temperature and Humidity...")
tmr.create():alarm(2000, tmr.ALARM_AUTO, function()
    status, temp, humi, temp_dec, humi_dec = dht.read(dht22_pin)
    if status == dht.OK then
        -- local jsonmsg = string.format("{\"temperature\": %d.%03d, \"humidity\": %d.%03d}", math.floor(temp), temp_dec, math.floor(humi), humi_dec)
        local jsonmsg = string.format("{\"temperature\": %.1f, \"humidity\": %.1f}", temp, humi)
        print(jsonmsg)
        m:publish(mqtt_topic, jsonmsg, 0, 0, function(client) print("Data sent") end)
        local displaymsg1 = string.format("%.1f%sC", temp, string.char(176))
        local displaymsg2 = string.format("%.1f%sF", toF(temp), string.char(176))
        local displaymsg3 = string.format("%.1f%%", humi)
        disp:clearBuffer()
        disp:drawStr( 0, 0, displaymsg1)
        disp:drawStr( 0, u8g2_line_height, displaymsg2)
        disp:drawStr( 0, u8g2_line_height * 2, displaymsg3)
        disp:sendBuffer()
    elseif status == dht.ERROR_CHECKSUM then
        print("DHT Checksum error.")
    elseif status == dht.ERROR_TIMEOUT then
        print("DHT timed out.")
    end
end)
