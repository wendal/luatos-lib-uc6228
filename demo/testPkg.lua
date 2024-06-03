
_G.sys = require("sys")
require "sysplus"

xmodem = require("xmodem")

local uc6228 = require("uc6228")

local gps_uart_id = 15

sys.taskInit(function()
    uart.setup(gps_uart_id, 115200)
    uart.on(gps_uart_id,"receive", function()
        sys.publish("uart_rx")
    end)
    local got = false
    while got == false do
        uart.write(gps_uart_id, "M!T")
        sys.waitUntil("uart_tx", 8)
        local s = ""
        while 1 do
            local tmp = uart.read(gps_uart_id, 2048)
            if #tmp == 0 then
                break
            end
            log.info("当前数据", tmp)
            if #tmp <= 2 then
                log.info("有可能是", tmp, tmp:toHex())
                if tmp == "YC" then
                    got = true
                    log.info("Got YC")
                    break
                end
                if tmp == "C" then
                    got = true
                    breaklog.info("Got YC")
                    break
                end
            end
        end
    end

    if got then
        log.info("拿到同步信号了")
    else
        log.info("超时了")
        return
    end
    
    log.info("发送bootloader")
    xmodem.send(gps_uart_id, 115200, "/luadb/BL115200.pkg", false)
    sys.wait(200)
    log.info("发送固件")
    xmodem.send(gps_uart_id, 115200, "/luadb/r350.pkg", false)
    sys.wait(200)
    xmodem.close(gps_uart_id)
    sys.wait(500)
    require "testGnss"
end)
