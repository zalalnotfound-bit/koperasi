-- =====================================================================
-- KOP CONFIGURATION (Ubah pengaturan bot Anda di sini)
-- =====================================================================
local CONFIG = {
    WORLD_FARM  = "breakzalal27|20",   -- World tempat mengambil SSP
    WORLD_DROP  = "breakzalal27|30", -- World cadangan untuk mendrop item
    SSP_ITEM_ID = 5706              -- ID Item SSP yang digunakan
}

-- =====================================================================
-- INISIALISASI BOT YANG AMAN
-- =====================================================================
local bot = getBot()

if bot == nil then
    print("[ERROR] Skrip ini membutuhkan konteks bot.")
    return
end

print("[INFO] Bot berhasil diinisialisasi dan siap berjalan.")

-- =====================================================================
-- FUNGSI PENDUKUNG (HELPER FUNCTIONS)
-- =====================================================================

-- Fungsi untuk mendrop seluruh isi inventory kecuali item SSP
local function dropAllExceptSSP()
    local inventory = bot:getInventory()
    for _, item in ipairs(inventory:getItems()) do
        if item.count > 0 and item.id ~= CONFIG.SSP_ITEM_ID then
            print("[DROP] Mendrop item ID: " .. item.id .. " sebanyak " .. item.count)
            bot:drop(item.id, item.count)
            sleep(750) 
        end
    end
end

-- Fungsi untuk memproses pengambilan SSP di world farm
local function collectSSP(world)
    local foundSSP = false
    for _, obj in ipairs(world:getObjects()) do
        if obj.id == CONFIG.SSP_ITEM_ID then
            foundSSP = true
            bot:moveTile(math.floor(obj.x / 32), math.floor(obj.y / 32))
            sleep(400)
            bot:collectObject(obj.oid, 2)
            sleep(600)
        end
    end
    return foundSSP
end

-- =====================================================================
-- LOOPING UTAMA BOT
-- =====================================================================
while true do
    -- Pastikan bot terhubung sebelum mulai
    if not bot:isInWorld() then
        print("[INFO] Menghubungkan ulang atau menunggu bot masuk ke world...")
        sleep(2000)
    else
        -- 1. Persiapan Awal: Aktifkan auto collect & masuk ke World Farm
        bot.auto_collect = true
        print("[INFO] Auto collect diaktifkan.")

        print("[WARP] Menuju world farm: " .. CONFIG.WORLD_FARM)
        bot:warp(CONFIG.WORLD_FARM)
        sleep(4000) 

        local world = bot:getWorld()
        if world ~= nil then
            -- 2. Proses Scan & Ambil SSP
            local foundSSP = collectSSP(world)


            -- 4. Pindah ke Titik Kumpul (0,0)
            print("[MOVE] Berpindah ke tile (0, 0)...")
            bot:moveTile(0, 0)
            sleep(1500)

            -- 5. Konsumsi SSP sampai tidak bisa dipakai lagi
            print("[INFO] Memulai penggunaan SSP sampai tidak bisa dipakai...")
            while true do
                local inventory = bot:getInventory()
                local countBefore = inventory:findItem(CONFIG.SSP_ITEM_ID)

                if countBefore <= 0 then
                    print("[INFO] Jumlah SSP sudah 0.")
                    break
                end

                bot:use(CONFIG.SSP_ITEM_ID)
                sleep(1500)

                local inventoryAfter = bot:getInventory()
                local countAfter = inventoryAfter:findItem(CONFIG.SSP_ITEM_ID)

                if countBefore == countAfter then
                    print("[INFO] SSP sudah tidak bisa dipakai lagi (jumlah tetap/macet).")
                    break
                end
            end

            -- Matikan auto collect dan pindah ke world cadangan
            bot.auto_collect = false
            print("[INFO] Auto collect dimatikan.")

            print("[WARP] Pindah ke world cadangan: " .. CONFIG.WORLD_DROP)
            bot:warp(CONFIG.WORLD_DROP)
            sleep(4000)

            -- 6. Bersihkan Inventory (Kecuali SSP) di World Cadangan
            if bot:isInWorld(CONFIG.WORLD_DROP) then
                print("[CLEANUP] Membersihkan inventory...")
                dropAllExceptSSP()
                sleep(1000)
            else
                print("[WARNING] Gagal masuk ke world cadangan, mencoba warp ulang...")
                bot:warp(CONFIG.WORLD_DROP)
                sleep(4000)
                dropAllExceptSSP()
            end

            -- 7. Siklus Ulang
            print("[CYCLE] Siklus selesai. Mengulang kembali ke world pertama...")
            sleep(2000)
        end
    end
    sleep(1000)
end