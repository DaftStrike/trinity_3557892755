local mod = RegisterMod("Trinity", 1)

local hasInitializedStats = {}

-- Mary
local maryType = Isaac.GetPlayerTypeByName("Mary", false)

-- Peter
local peterType = Isaac.GetPlayerTypeByName("Peter", false)

-- Isaiah
local isaiahType = Isaac.GetPlayerTypeByName("Isaiah", false)

-- Atributos de cada personagem
local function GetBaseStats(player)
    local stats = {}
    local icons = Sprite()
    if player:GetPlayerType() == maryType then
        stats = {
            damage = -1,
            tears = -1,
            speed = -0.15,
            luck = -1,
        }
        if EID then
            EID:addBirthright(maryType, "{{Trinket}} Whenever Mom's Box is used, there is a 35% chance to swallow equipped trinkets")
            icons:Load("gfx/ui/maryFace.anm2", true)
            EID:addIcon("Player"..maryType, "Mary", -1, 16, 16, 6, 5, icons)
        end
    elseif player:GetPlayerType() == peterType then
        stats = {
            damage = 0,
            tears = 0.25,
            speed = 0,
            luck = -1,
        }
        if EID then
            EID:addBirthright(peterType, "{{HalfSoulHeart}} Taking damage to Red Hearts restores 0.5 of a Soul Heart unless the damage would kill Isaac")
            icons:Load("gfx/ui/peterFace.anm2", true)
            EID:addIcon("Player"..peterType, "Peter", -1, 16, 16, 6, 5, icons)
        end
    elseif player:GetPlayerType() == isaiahType then
        stats = {
            damage = -0.75,
            tears = 0.27,
            speed = 0.1,
            luck = 0,
        }
        if EID then
            EID:addBirthright(isaiahType, "{{Battery}} {{Card}}/{{RedCard}} or {{Rune}} grant 1 charge to the active item#{{Battery}} Taking damage grant 2 charges to the active item")
            icons:Load("gfx/ui/isaiahFace.anm2", true)
            EID:addIcon("Player"..isaiahType, "Isaiah", -1, 16, 16, 6, 5, icons)
        end
    end
    return stats
end

-- Inicialização
function mod:GiveCostumesOnInit(player)
    if not hasInitializedStats[player.InitSeed] then
        hasInitializedStats[player.InitSeed] = true

        if player:GetPlayerType() == maryType then -- Mary
            player:AddTrinket(Isaac.GetTrinketIdByName("Maggie's Drawing"))

        elseif player:GetPlayerType() == peterType then -- Peter
            player:AddCollectible(Isaac.GetItemIdByName("Mirror of Hearts"), 5)

        elseif player:GetPlayerType() == isaiahType then -- Isaiah
            player:AddCollectible(Isaac.GetItemIdByName("Paper Knife"))
        end

        player:AddCacheFlags(CacheFlag.CACHE_ALL)
        player:EvaluateItems()
    end
end

-- Aplicação dos atributos
function mod:CharacterCache(player, cacheFlag)
    local stats = GetBaseStats(player)

    -- Dano
    if cacheFlag == CacheFlag.CACHE_DAMAGE then
        if stats.damage then
            player.Damage = player.Damage + stats.damage
        end
    end

    -- Velocidade
    if cacheFlag == CacheFlag.CACHE_SPEED then
        if stats.speed then
            player.MoveSpeed = player.MoveSpeed + stats.speed
        end
    end

    -- Sorte
    if cacheFlag == CacheFlag.CACHE_LUCK then
        if stats.luck then
            player.Luck = player.Luck + stats.luck
        end
    end

    -- Tears
    if cacheFlag == CacheFlag.CACHE_FIREDELAY then
        local tearsUp = stats.tears or 0
        if tearsUp ~= 0 then
            -- Fórmula padrão de conversão FireDelay <-> Tears
            local currentTears = 30 / (player.MaxFireDelay + 1)
            local newTears = currentTears + tearsUp

            -- Evita valores impossíveis ou negativos
            if newTears < 0.1 then
                newTears = 0.1
            end

            player.MaxFireDelay = (30 / newTears) - 1

            -- Garante que nunca fique abaixo de 0
            if player.MaxFireDelay < 0 then
                player.MaxFireDelay = 0
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.GiveCostumesOnInit)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.CharacterCache)

function mod:PeterTears(tear)
    local player = tear.SpawnerEntity:ToPlayer()
    if player and player:GetPlayerType() == peterType then
        -- Define a cor para vermelho
        local redColor = Color(1, 0, 0, 1, 0, 0, 0)
        tear:SetColor(redColor, -1, 0)
    end
end

mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.PeterTears)

-- BIRTHRIGHT
    -- MARY BEGIN
local givenMomsBox = {}

-- Dá a Mom's Box e remove o item ativo anterior, se tiver
function mod:MaryBirthrightEffect(player)
    if player:GetPlayerType() ~= maryType then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then return end

    local id = player:GetCollectibleRNG(1):GetSeed()

    if not givenMomsBox[id] then
        if not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_BOX) then
            local currentItem = player:GetActiveItem(ActiveSlot.SLOT_PRIMARY)

            if currentItem ~= 0 then
                local game = Game()
                local room = game:GetRoom()
                local pos = room:FindFreePickupSpawnPosition(player.Position, 40, true)
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, currentItem, pos, Vector.Zero, nil)
            end
            player:AddCollectible(CollectibleType.COLLECTIBLE_MOMS_BOX)
        end
        -- Marca que Mary já recebeu a Mom's Box
        givenMomsBox[id] = true
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.MaryBirthrightEffect)

-- Engole trinket com 35% de chance ao usar Mom's Box
function mod:OnUseMomsBox(_, _, player, _, _)
    if player:GetPlayerType() ~= maryType then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then return end

    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_BIRTHRIGHT)

    if rng:RandomFloat() < 0.35 then
        -- Verifica se há trinket nos dois slots
        for i = 0, 1 do
            local trinket = player:GetTrinket(i)
            if trinket ~= 0 then
                -- Usa o efeito do Smelter para engolir o trinket
                player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, false, false, false)
                break
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.OnUseMomsBox, CollectibleType.COLLECTIBLE_MOMS_BOX)
    -- MARY END

    -- PETER BEGIN
-- Callback: Intercepta dano antes que ele seja aplicado
function mod:PeterTakingDamage(entity, amount, damageFlags, source, countdown)
    local player = entity:ToPlayer()
    if not player then return end
    if player:GetPlayerType() ~= peterType then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then return end

    local redHearts = player:GetHearts()
    local soulHearts = player:GetSoulHearts()
    local totalHealth = redHearts + soulHearts

    if amount >= totalHealth and redHearts > 0 then
        player:AddHearts(-(amount - soulHearts))
        player:AddSoulHearts(1)
        SFXManager():Play(SoundEffect.SOUND_SOUL_PICKUP)
        return true
    end
    mod:ScheduleCheck(player)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.PeterTakingDamage, EntityType.ENTITY_PLAYER)

-- Tabela para agendar cura após dano não letal
local playersToCheck = {}

function mod:ScheduleCheck(player)
    playersToCheck[player.Index] = {
        redHeartsBefore = player:GetHearts(),
        delay = 2
    }
end

function mod:PostUpdate()
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        local check = playersToCheck[player.Index]

        if check then
            check.delay = check.delay - 1

            if check.delay <= 0 then
                if player:GetHearts() < check.redHeartsBefore then
                    player:AddSoulHearts(1)
                    SFXManager():Play(SoundEffect.SOUND_SOUL_PICKUP)
                end
                playersToCheck[player.Index] = nil
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.PostUpdate)
    -- PETER ENDING

    -- ISAIAH BEGIN
function mod:IsaiahOnUseConsumable(_, player, _, _, _)
    if player:GetPlayerType() ~= isaiahType then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then return end

    local slot = ActiveSlot.SLOT_PRIMARY
    local item = player:GetActiveItem(slot)

    if item ~= 0 then
        local currentCharge = player:GetActiveCharge(slot)
        local maxCharge = Isaac.GetItemConfig():GetCollectible(item).MaxCharges or 0

        if currentCharge < maxCharge then
        player:SetActiveCharge(math.min(currentCharge + 1, maxCharge), slot)
        SFXManager():Play(SoundEffect.SOUND_BATTERYCHARGE)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_USE_CARD, mod.IsaiahOnUseConsumable)

function mod:IsaiahOnDamage(entity, amount, flags, source, countdown)
    local player = entity:ToPlayer()
    if not player or player:GetPlayerType() ~= isaiahType then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then return end

    local slot = ActiveSlot.SLOT_PRIMARY
    local item = player:GetActiveItem(slot)

    if item ~= 0 then
        local currentCharge = player:GetActiveCharge(slot)
        local maxCharge = Isaac.GetItemConfig():GetCollectible(item).MaxCharges or 0

        if currentCharge < maxCharge then
            player:SetActiveCharge(math.min(currentCharge + 2, maxCharge), slot)
            SFXManager():Play(SoundEffect.SOUND_BATTERYCHARGE)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.IsaiahOnDamage, EntityType.ENTITY_PLAYER)
    -- ISAIAH ENDING


--DESCRIÇÕES PERSONALIZADAS
if EID then
    -- Itens Passivos
        -- D-Clover
    EID:addCollectible(Isaac.GetItemIdByName("D-Clover"), "{{ArrowUp}} +4 Luck#{{Collectible}} Removes the last quality {{Quality0}} passive item Isaac picked up and replaces it with a new one from the same pool")
    EID:addCollectible(Isaac.GetItemIdByName("D-Clover"), "{{ArrowUp}} +4 Sorte#{{Collectible}} Remove o último item passivo de qualidade {{Quality0}} que Isaac pegou e o substitui por um novo da mesma pool", "Trevo d4 Folhas", "pt")
        -- Paper Knife
    EID:addCollectible(Isaac.GetItemIdByName("Paper Knife"), "{{ArrowUp}} Each time Isaac uses a {{Card}}/{{RedCard}} or {{Rune}}, gain +0.75 Damage until he takes damage")
    EID:addCollectible(Isaac.GetItemIdByName("Paper Knife"), "{{ArrowUp}} Toda vez que Isaac usar uma {{Card}}/{{RedCard}} ou {{Rune}}, ganha +0.75 de Dano até receber dano", "Faca de Papel", "pt")

        -- Worn Tire
    EID:addCollectible(Isaac.GetItemIdByName("Worn Tire"), "{{ArrowUp}} +0.2 Speed#{{SpeedSmall}} Prevents Isaac's Speed from being lowered for the rest of the run")
    EID:addCollectible(Isaac.GetItemIdByName("Worn Tire"), "{{ArrowUp}} +0.2 Velocidade#{{SpeedSmall}} Previne a velocidade de Isaac de ser reduzida pelo restante da run", "Pneu Careca","pt")

    function DescCheck(player)
        for i = 0, Game():GetNumPlayers() - 1 do
            player = Isaac.GetPlayer(i)
        -- Trinkets
            -- Quando tem Mom's Box
            if HasMomsBox(player) then
                    -- Old Credit Card
            EID:addTrinket(Isaac.GetTrinketIdByName("Old Credit Card"), "{{Coin}} Grants {{ColorRainbow}}+20%{{CR}} coins every time Isaac gain a charge for his active item")
            EID:addTrinket(Isaac.GetTrinketIdByName("Old Credit Card"), "{{Coin}} Garante {{ColorRainbow}}+20%{{CR}} moedas sempre que Isaac ganhar carga para seu item ativo", "Cartão de Crédito Velho", "pt")
                -- Maggie's Drawing
            EID:addTrinket(Isaac.GetTrinketIdByName("Maggie's Drawing"), "{{Collectible439}} 1.5x Damage, Tears and Range")
            EID:addTrinket(Isaac.GetTrinketIdByName("Maggie's Drawing"), "{{Collectible439}} 1.5x de Dano, Tears e Alcance", "Desenho da Maggie", "pt")
                -- Fire Killer
            EID:addTrinket(Isaac.GetTrinketIdByName("Fire Killer"), "Extinguish all fireplaces upon entering the room#{{Burning}} Grants immunity to fire damage#{{Collectible439}} Some fire enemies will die automatically")
            EID:addTrinket(Isaac.GetTrinketIdByName("Fire Killer"), "Extingue todas as fogueiras ao entrar na sala#{{Burning}} Garante imunidade a dano de fogo#{{Collectible439}} Alguns inimigos de fogo morrerão automaticamente", "Corta-fogo", "pt")

            -- Sem Mom's Box
            else 
                -- Old Credit Card
            EID:addTrinket(Isaac.GetTrinketIdByName("Old Credit Card"), "{{Coin}} Grants +10% coins every time Isaac gains a charge for his active item")
            EID:addTrinket(Isaac.GetTrinketIdByName("Old Credit Card"), "{{Coin}} Garante +10% moedas sempre que Isaac ganhar carga para seu item ativo", "Cartão de Crédito Velho", "pt")
                -- Maggie's Drawing
            EID:addTrinket(Isaac.GetTrinketIdByName("Maggie's Drawing"), "Does nothing in particular")
            EID:addTrinket(Isaac.GetTrinketIdByName("Maggie's Drawing"), "Não faz nada em particular", "Desenho da Maggie", "pt")
                -- Fire Killer
            EID:addTrinket(Isaac.GetTrinketIdByName("Fire Killer"), "Extinguish all fireplaces upon entering the room#{{Burning}} Grants immunity to fire damage")
            EID:addTrinket(Isaac.GetTrinketIdByName("Fire Killer"), "Extingue todas as fogueiras ao entrar na sala#{{Burning}} Garante imunidade a dano de fogo", "Corta-fogo", "pt")
            end

        -- Itens Ativos
            -- Quando tem Book of Virtues
            if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                    -- Mirror of Hearts
                EID:addCollectible(Isaac.GetItemIdByName("Mirror of Hearts"), "{{BlendedHeart}} When activated,{{Heart}} will have damage priority for the entire floor#{{AngelDevilChance}} No Devil/Angel chance is lost#{{Collectible584}} {{ColorTransform}}1 middle ring wisp#{{Heart}} {{ColorTransform}}1 health {{Damage}} 0.5 dps#{{HalfSoulHeart}} {{ColorTransform}}Grants half a Soul Heart after disappearing")
                EID:addCollectible(Isaac.GetItemIdByName("Mirror of Hearts"), "{{BlendedHeart}} Quando ativo,{{Heart}} recebe prioridade de dano pelo resto do andar#{{AngelDevilChance}} Chance de Diabo/Anjo não é perdida#{{Collectible584}} {{ColorTransform}}1 wisp de anel médio#{{Heart}} {{ColorTransform}}1 de vida {{Damage}} 0.5 dps#{{HalfSoulHeart}} {{ColorTransform}}Garante meio coração de alma após desaparecer", "Espelho de Corações", "pt")
                    -- Hacker Laptop
                EID:addCollectible(Isaac.GetItemIdByName("Hacker Laptop"), "{{Collectible}} Spawns a random item from a different pool than the current room's pool#{{Collectible584}} {{ColorTransform}}1 outer ring wisp#{{Heart}} {{ColorTransform}}12 health {{Damage}} Can't shoot!")
                EID:addCollectible(Isaac.GetItemIdByName("Hacker Laptop"), "{{Collectible}} Spawna um item de uma pool diferente da pool da sala atual#{{Collectible584}} {{ColorTransform}}1 wisp de anel externo#{{Heart}} {{ColorTransform}}12 de vida {{Damage}} Não atira!", "Notebook Hacker", "pt")
                    -- Chessboard
                EID:addCollectible(Isaac.GetItemIdByName("Chessboard"), "{{Luck}} Makes Isaac ramdomly black or white for the floor#{{HalfBlackHeart}} Black: 2x Damage, 0,65x Tears#{{EthernalHeart}} White: 0.65x Damage, 2x Tears. Exceeds the Tears limit if Isaac has a Tears up item#Changes color each time Isaac uses it in the same floor#{{Collectible584}} {{ColorTransform}}2 middle ring wisp#{{Heart}} {{ColorTransform}}4 health {{Damage}} 3.2 dps")
                EID:addCollectible(Isaac.GetItemIdByName("Chessboard"), "{{Luck}} Isaac fica aleatoriamente preto ou branco pelo andar#{{HalfBlackHeart}} Preto: 2x de Dano, 0,65x de Tears#{{EthernalHeart}} Branco: 0.65x de Dano, 2x de Tears. Excede o limite de Tears se Isaac tem um item que aumenta Tears#Muda a cor sempre que Isaac usar o item no mesmo andar#{{Collectible584}} {{ColorTransform}}2 wisps de anel médio#{{Heart}} {{ColorTransform}}4 de vida {{Damage}} 3.2 dps", "Tabuleiro de Xadrez", "pt")

            -- Sem Book of Virtues
            else
                    -- Mirror of Hearts
                EID:addCollectible(Isaac.GetItemIdByName("Mirror of Hearts"), "{{BlendedHeart}} When activated,{{Heart}} will have damage priority for the entire floor#{{AngelDevilChance}} No Devil/Angel chance is lost")
                EID:addCollectible(Isaac.GetItemIdByName("Mirror of Hearts"), "{{BlendedHeart}} Quando ativo,{{Heart}} recebe prioridade de dano pelo resto do andar#{{AngelDevilChance}} Chance de Diabo/Anjo não é perdida", "Espelho de Corações", "pt")
                    -- Hacker Laptop
                EID:addCollectible(Isaac.GetItemIdByName("Hacker Laptop"), "{{Collectible}} Spawns a random item from a different pool than the current room's pool")
                EID:addCollectible(Isaac.GetItemIdByName("Hacker Laptop"), "{{Collectible}} Spawna um item de uma pool diferente da pool da sala atual", "Notebook Hacker", "pt")
                    -- Chessboard
                EID:addCollectible(Isaac.GetItemIdByName("Chessboard"), "{{Luck}} Makes Isaac ramdomly black or white for the floor#{{HalfBlackHeart}} Black: 2x Damage, 0,65x Tears#{{EthernalHeart}} White: 0.65x Damage, 2x Tears. Exceeds the Tears limit if Isaac has a Tears up item#Changes color each time Isaac uses it in the same floor")
                EID:addCollectible(Isaac.GetItemIdByName("Chessboard"), "{{Luck}} Isaac fica aleatoriamente preto ou branco pelo andar#{{HalfBlackHeart}} Preto: 2x de Dano, 0,65x de Tears#{{EthernalHeart}} Branco: 0.65x de Dano, 2x de Tears. Excede o limite de Tears se Isaac tem um item que aumenta Tears#Muda a cor sempre que Isaac usar o item no mesmo andar", "Tabuleiro de Xadrez", "pt")

            end
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, DescCheck)
end

-- ITENS PASSIVOS

    -- D-CLOVER BEGIN
local dClover = Isaac.GetItemIdByName("D-Clover")
local dCloverUp = 4

local trackedItems = {}
local cloverAppliedCount = {}

-- Rastreia o último item passivo de qualidade 0 obtido antes do D-Clover
function mod:TrackLastQualityZeroItem(player)
    local pIndex = player:GetCollectibleRNG(1):GetSeed()
    if not trackedItems[pIndex] then
        trackedItems[pIndex] = {}
    end
    local pTracked = trackedItems[pIndex]
    local data = player:GetData()

    for itemID = 1, CollectibleType.NUM_COLLECTIBLES - 1 do
        if player:HasCollectible(itemID) and not pTracked[itemID] then
            local config = Isaac.GetItemConfig():GetCollectible(itemID)
            if config and config.Type == ItemType.ITEM_PASSIVE and config.Quality == 0 and itemID ~= dClover then
                data.lastItemZeroID = itemID
                data.lastItemPool = ItemPoolType.POOL_TREASURE -- fallback padrão
                local itemPool = Game():GetItemPool()
                data.lastItemPool = itemPool:GetPoolForRoom(RoomType.ROOM_NULL, 0) -- melhor estimativa da pool atual
            end
            pTracked[itemID] = true
        end
    end
end

-- Aplica o efeito ao pegar o D-Clover
function mod:OnCloverPickup(player)
    local playerID = player:GetCollectibleRNG(1):GetSeed()
    local data = player:GetData()

    local currentCount = player:GetCollectibleNum(dClover)
    local alreadyApplied = cloverAppliedCount[playerID] or 0

    if currentCount > alreadyApplied then
        cloverAppliedCount[playerID] = currentCount        

        if data.lastItemZeroID then
            -- Remove o item antigo
            player:RemoveCollectible(data.lastItemZeroID)

            -- Spawna novo item passivo da mesma pool
            local game = Game()
            local room = game:GetRoom()
            local pos = room:FindFreePickupSpawnPosition(player.Position, 40, true)
            local rng = player:GetCollectibleRNG(dClover)
            local itemPool = game:GetItemPool()
            local pool = data.lastItemPool or ItemPoolType.POOL_TREASURE

            -- Tenta pegar um item passivo válido da mesma pool
            local newItemID = Isaac.GetItemIdByName("Sad Onion") -- fallback
            for _ = 1, 20 do
                local testID = itemPool:GetCollectible(pool, true, rng:Next())
                local config = Isaac.GetItemConfig():GetCollectible(testID)
                if config and config.Type == ItemType.ITEM_PASSIVE and config.Quality > 0 then
                    newItemID = testID
                    break
                end
            end

            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, newItemID, pos, Vector.Zero, nil)
        end
    end
end

-- Aplica bônus de sorte
function mod:EvaluateCloverCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_LUCK == CacheFlag.CACHE_LUCK then
        local itemCount = player:GetCollectibleNum(dClover)
        player.Luck = player.Luck + dCloverUp * itemCount
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.TrackLastQualityZeroItem)
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.OnCloverPickup)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCloverCache)
    -- D-CLOVER END

    -- PAPER KNIFE BEGIN
local paperKnife = Isaac.GetItemIdByName("Paper Knife")
function mod:OnUseConsumable(_, player, _, _, _)
    if player:HasCollectible(paperKnife) then
        local data = player:GetData()
        data.pk_dmgBonus = (data.pk_dmgBonus or 0) + 0.75
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:EvaluateItems()
    end
end

mod:AddCallback(ModCallbacks.MC_USE_CARD, mod.OnUseConsumable)

-- Aplica o bônus de dano
function mod:EvaluateCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        local data = player:GetData()
        if data.pk_dmgBonus then
            player.Damage = player.Damage + data.pk_dmgBonus
        end
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)

-- Zera o bônus ao tomar dano
function mod:OnPlayerDamaged(entity, amount, flags, source, countdown)
    if entity:ToPlayer() then
        local player = entity:ToPlayer()
        if player:HasCollectible(paperKnife) then
            local data = player:GetData()
            
            -- ignora Dano proposital
            if flags & DamageFlag.DAMAGE_RED_HEARTS ~= 0
            or flags & DamageFlag.DAMAGE_IV_BAG ~= 0
            or flags & DamageFlag.DAMAGE_CURSED_DOOR ~= 0
            or flags & DamageFlag.DAMAGE_FAKE ~= 0 then
                return
            end

            -- se tinha buff, reseta
            if data.pk_dmgBonus and data.pk_dmgBonus > 0 then
                data.pk_dmgBonus = 0
                data.pk_lostBuff = true -- Marca que o buff foi perdido
                player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
                player:EvaluateItems()
            end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnPlayerDamaged, EntityType.ENTITY_PLAYER)

-- Restaura o bônus ao usar Glowing Hourglass
function mod:HourglassUse(item, rng, player, flags, slot, varData)
    if item == CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS then
        local data = player:GetData()
        if data.pk_lostBuff and data.pk_lastLostBonus and data.pk_lastLostBonus > 0 then
            data.pk_dmgBonus = (data.pk_dmgBonus or 0) + data.pk_lastLostBonus
            data.pk_lostBuff = false
            data.pk_lastLostBonus = nil -- limpa para não reaplicar várias vezes
            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
            player:EvaluateItems()
        end
    end
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.HourglassUse)
    -- PAPER KNIFE END

-- WORN TIRE BEGIN
local wornTire = Isaac.GetItemIdByName("Worn Tire")
local wornTireUp = 0.2

-- Avalia o cache de Speed
function mod:EvaluateTireCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED then
        if player:HasCollectible(wornTire) then
            local itemCount = player:GetCollectibleNum(wornTire)
            local data = player:GetData()

            -- Bônus normal do item
            player.MoveSpeed = player.MoveSpeed + (wornTireUp * itemCount)

            -- Inicializa o mínimo, se não existir
            if not data.wornTireMinSpeed then
                data.wornTireMinSpeed = player.MoveSpeed
            end

            -- Atualiza o mínimo sempre que a Speed atual for maior
            if player.MoveSpeed >= data.wornTireMinSpeed then
                data.wornTireMinSpeed = player.MoveSpeed
            else
                player.MoveSpeed = data.wornTireMinSpeed
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateTireCache)

-- Garante que o jogo recalcula sempre que necessário
function mod:OnUpdate(player)
    if player:HasCollectible(wornTire) then
        player:AddCacheFlags(CacheFlag.CACHE_SPEED)
        player:EvaluateItems()
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.OnUpdate)
-- WORN TIRE END




-- ITENS ATIVOS

    -- MIRROR OF HEARTS BEGIN
local mirrorOfHearts = Isaac.GetItemIdByName("Mirror of Hearts")
local mirrorCostumeHead = Isaac.GetCostumeIdByPath("gfx/characters/MirrorHead.anm2")
local mirrorCostumeBody = Isaac.GetCostumeIdByPath("gfx/characters/MirrorBody.anm2")

-- Alterna o estado do espelho apenas para o jogador que usou o item
function mod:HeartMirrorUse(_, _, player)
    local data = player:GetData()

    data.heartMirrorOn = not data.heartMirrorOn

    if data.heartMirrorOn then
        player:AddNullCostume(mirrorCostumeHead)
        player:AddNullCostume(mirrorCostumeBody)
    else
        player:TryRemoveNullCostume(mirrorCostumeHead)
        player:TryRemoveNullCostume(mirrorCostumeBody)
    end

    return true
end

-- Redireciona dano de soul hearts para corações vermelhos
function mod:OnPlayerTakeDamage(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
    local player = entity:ToPlayer()
    if player then
        local data = player:GetData()

        if data.heartMirrorOn then
            if player:GetEternalHearts() ~= 0 then
                player:AddEternalHearts(-1)
                player:AddSoulHearts(damageAmount + 1)
            else
                if player:GetSoulHearts() > 0 and player:GetHearts() > 0 then
                    player:AddSoulHearts(damageAmount)
                    player:AddHearts(-damageAmount)
                end
            end
            return true
        end
    end
end

-- Remove o efeito do jogador no início de cada novo andar
function mod:NewLevelMirror()
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        local data = player:GetData()

        if data.heartMirrorOn then
            data.heartMirrorOn = false
            player:TryRemoveNullCostume(mirrorCostumeHead)
            player:TryRemoveNullCostume(mirrorCostumeBody)
        end
    end
end

-- Garante que o costume seja removido caso o efeito esteja desligado
function mod:PostPlayerEffect(player)
    local data = player:GetData()

    if not data.heartMirrorOn then
        player:TryRemoveNullCostume(mirrorCostumeHead)
        player:TryRemoveNullCostume(mirrorCostumeBody)
    end
end

-- Detecta quando uma wisp morre
function mod:OnEntityKill(entity)
    if entity.Type == EntityType.ENTITY_FAMILIAR and entity.Variant == FamiliarVariant.WISP then
        local familiar = entity:ToFamiliar()
        if familiar and familiar.SubType == mirrorOfHearts then
            local player = familiar.Player
            if player then
                player:AddSoulHearts(1) -- 1 = meio coração azul
            end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.HeartMirrorUse, mirrorOfHearts)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnPlayerTakeDamage, EntityType.ENTITY_PLAYER)
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.PostPlayerEffect)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.NewLevelMirror)
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.OnEntityKill)
    -- MIRROR OF HEARTS END



    -- HACKER LAPTOP BEGIN
local hackerLaptopID = Isaac.GetItemIdByName("Hacker Laptop")
local game = Game()
local itemPool = game:GetItemPool()

-- Lista de pools válidas
local validPools = {
    ItemPoolType.POOL_TREASURE,
    ItemPoolType.POOL_SHOP,
    ItemPoolType.POOL_ANGEL,
    ItemPoolType.POOL_DEVIL,
    ItemPoolType.POOL_SECRET,
    ItemPoolType.POOL_BOSS,
    ItemPoolType.POOL_LIBRARY,
    ItemPoolType.POOL_CURSE,
    ItemPoolType.POOL_PLANETARIUM,
    ItemPoolType.POOL_RED_CHEST,
    ItemPoolType.POOL_CRANE_GAME,
    ItemPoolType.POOL_ULTRA_SECRET,
    ItemPoolType.POOL_GREED_TREASURE,
    ItemPoolType.POOL_GREED_SHOP,
    ItemPoolType.POOL_GREED_CURSE
}

function mod:UseHackerLaptop(item, rng, player, flags, slot, varData)
    local currentRoomPool = itemPool:GetPoolForRoom(RoomType.ROOM_DEFAULT, game:GetLevel():GetStage(), player:GetCollectibleRNG(hackerLaptopID))
    local room = game:GetRoom()
    local pos = room:FindFreePickupSpawnPosition(player.Position, 40, true)

    -- Filtra pools que não sejam a da sala atual
    local otherPools = {}
    for _, pool in ipairs(validPools) do
        if pool ~= currentRoomPool then
            table.insert(otherPools, pool)
        end
    end

    -- Escolhe uma pool aleatória
    local chosenPool = otherPools[rng:RandomInt(#otherPools) + 1]
    local collectibleID = itemPool:GetCollectible(chosenPool, true, rng:Next())

    -- Spawna o item na frente do jogador
    if collectibleID ~= 0 then
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, collectibleID, pos, Vector.Zero, nil)
    end

    return true -- previne uso padrão do item
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.UseHackerLaptop, hackerLaptopID)
    -- HACKER LAPTOP END

    -- CHESSBOARD BEGIN
local chessboard = Isaac.GetItemIdByName("Chessboard")
local chessboardChange = 0.5

local game = Game()

function mod:ChessboardUse(item, rng, player)
    local data = player:GetData()
    local level = game:GetLevel()
    local currentStage = level:GetStage()

    -- Inicialização
    if not data.ChessboardStage then
        data.ChessboardStage = -1
    end

    -- Primeira ativação no andar
    if data.ChessboardStage ~= currentStage then
        data.OriginalColor = player:GetColor()

        local colorRNG = player:GetCollectibleRNG(chessboard)
        local randomValue = colorRNG:RandomFloat()

        if randomValue < chessboardChange then
            -- Branco
            player:SetColor(Color(2, 2, 2, 1, 0, 0, 0), -1, 1, false, false)
            data.IsaacColor = "W"
            data.ChessboardDamageMult = 0.65
            data.ChessboardFireDelayMult = 0.5
        else
            -- Preto
            player:SetColor(Color(0.1, 0.1, 0.1, 1, 0, 0, 0), -1, 1, false, false)
            data.IsaacColor = "B"
            data.ChessboardDamageMult = 2
            data.ChessboardFireDelayMult = 1.35
        end

        data.ChessboardStage = currentStage

    else
        -- Inversão da cor
        if data.IsaacColor == "W" then
            player:SetColor(Color(0.1, 0.1, 0.1, 1, 0, 0, 0), -1, 1, false, false)
            data.IsaacColor = "B"
            data.ChessboardDamageMult = 2
            data.ChessboardFireDelayMult = 1.35
        else
            player:SetColor(Color(2, 2, 2, 1, 0, 0, 0), -1, 1, false, false)
            data.IsaacColor = "W"
            data.ChessboardDamageMult = 0.65
            data.ChessboardFireDelayMult = 0.5
        end
    end

    -- Atualiza os atributos via cache
    player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_FIREDELAY)
    player:EvaluateItems()

    return true
end

-- Aplica os multiplicadores no cache
function mod:OnCache(player, cacheFlag)
    local data = player:GetData()

    if data.ChessboardDamageMult and cacheFlag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage * data.ChessboardDamageMult
    end

    if data.ChessboardFireDelayMult and cacheFlag == CacheFlag.CACHE_FIREDELAY then
        player.MaxFireDelay = player.MaxFireDelay * data.ChessboardFireDelayMult
    end
end

-- Limpa os dados ao entrar em um novo andar
function mod:OnNewLevel()
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        local data = player:GetData()

        -- Restaura a cor original se salva
        if data.OriginalColor then
            player:SetColor(data.OriginalColor, -1, 1, false, false)
        end

        -- Remove multiplicadores
        data.ChessboardDamageMult = nil
        data.ChessboardFireDelayMult = nil
        data.IsaacColor = nil
        data.OriginalColor = nil
        data.ChessboardStage = nil

        -- Reavalia os atributos
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
        player:EvaluateItems()
    end
end

-- Callbacks
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.ChessboardUse, chessboard)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OnCache)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.OnNewLevel)
    -- CHESSBOARD END


-- TRINKETS

    -- OLD CREDIT CARD BEGIN
local oldCreditCardID = Isaac.GetTrinketIdByName("Old Credit Card")

local previousCharge = {}

-- Hook que roda a cada update de jogador
function mod:OnCreditCardUpdate(player)
    local item = player:GetActiveItem(ActiveSlot.SLOT_PRIMARY)
    local item2 = player:GetActiveItem(ActiveSlot.SLOT_SECONDARY)
    local item3 = player:GetActiveItem(ActiveSlot.SLOT_POCKET)
    local charge = player:GetActiveCharge()
    local percentage = 0.1 -- Aumento de 10% padrão

    if player:HasTrinket(oldCreditCardID) and item ~= 0 and item ~= Isaac.GetItemIdByName("Isaac's Tears") then
        if item == CollectibleType.COLLECTIBLE_MOMS_BOX or item2 == CollectibleType.COLLECTIBLE_MOMS_BOX or item3 == CollectibleType.COLLECTIBLE_MOMS_BOX then
            percentage = 0.2 -- Aumento para 20% se estiver com Mom's Box
        end
        if previousCharge[player.Index] == nil then
            previousCharge[player.Index] = charge
        else
            local oldCharge = previousCharge[player.Index]
            local chargeDiff = charge - oldCharge
            if chargeDiff > 0 then
                -- Cálculo de 10% das moedas
                local coins = player:GetNumCoins()
                local bonus = math.floor(coins * percentage)
                if bonus > 0 then
                    player:AddCoins(bonus)
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, player.Position, Vector(0,0), player)
                end
            end
            previousCharge[player.Index] = charge
        end
    else
        previousCharge[player.Index] = nil
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.OnCreditCardUpdate)
    --OLD CREDIT CARD END

    -- MAGGIE'S DRAWING BEGIN
local momBoxID = CollectibleType.COLLECTIBLE_MOMS_BOX
local trinketID = Isaac.GetTrinketIdByName("Maggie's Drawing")

-- Armazenar se os buffs estão ativos para cada jogador
local isBuffActive = {}

-- Função utilitária: checa se o player tem Mom's Box em qualquer slot
function HasMomsBox(player)
    for slot = 0, 2 do  -- PRIMARY, SECONDARY, POCKET
        if player:GetActiveItem(slot) == momBoxID then
            return true
        end
    end
    return false
end

-- Callback para atualizar atributos do jogador
function mod:OnEvaluateCache(player, cacheFlag)
    local hasTrinket = player:HasTrinket(trinketID)
    local hasMomsBox = HasMomsBox(player)
    local drawStatsUp = 1.5

    if hasTrinket and hasMomsBox then
        -- Ativa os buffs apropriados
        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage * drawStatsUp -- Aumenta Damage
        end
        if cacheFlag == CacheFlag.CACHE_FIREDELAY then
            player.MaxFireDelay = player.MaxFireDelay / drawStatsUp -- Aumenta Tears
        end
        if cacheFlag == CacheFlag.CACHE_RANGE then
            player.TearRange = player.TearRange * drawStatsUp -- Aumenta range
        end
        isBuffActive[player.Index] = true
    else
        isBuffActive[player.Index] = false
    end
end

-- Verifica constantemente se houve mudança que exige recalcular os atributos
function mod:OnDrawingUpdate(player)
    local hasTrinket = player:HasTrinket(trinketID)
    local hasMomsBox = HasMomsBox(player)
    local index = player.Index

    -- Detecta se a ativação/desativação mudou
    local shouldBeActive = hasTrinket and hasMomsBox
    if isBuffActive[index] ~= shouldBeActive then
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_FIREDELAY | CacheFlag.CACHE_RANGE)
        player:EvaluateItems()
    end
end

-- Callbacks
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OnEvaluateCache)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.OnDrawingUpdate)
    --MAGGIE'S DRAWING END

    -- FIRE KILLER BEGIN
local fireKillerTrinket = Isaac.GetTrinketIdByName("Fire Killer")

-- Remove fogueiras ao entrar na sala
function mod:OnNewRoom()
    for _, player in ipairs(Isaac.FindByType(EntityType.ENTITY_PLAYER)) do
        if player:ToPlayer():HasTrinket(fireKillerTrinket) then
            for _, entity in ipairs(Isaac.GetRoomEntities()) do
                if entity.Type == EntityType.ENTITY_FIREPLACE then
                    local fireVariant = entity.Variant
                    if fireVariant >= 0 and fireVariant <= 3 then
                        entity:GetDropRNG()
                        entity:Die()
                    end
                else
                    for i = 0, 3 do
                        if player:ToPlayer():GetActiveItem(i) == CollectibleType.COLLECTIBLE_MOMS_BOX then
                            if entity.Type == EntityType.ENTITY_FIRE_WORM or entity.Type == EntityType.ENTITY_WILLO or entity.Type == EntityType.ENTITY_WILLO_L2 then
                                entity:GetDropRNG()
                                entity:Die()
                                SFXManager():Play(SoundEffect.SOUND_FIREDEATH_HISS)
                            end
                        end
                    end
                end
            end
            break
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)

-- Imunidade a dano de fogo
function mod:OnDamageTaken(entity, damageAmount, damageFlags, source, countdown)
    local player = entity:ToPlayer()
    if player and player:HasTrinket(fireKillerTrinket) then
        if damageFlags & DamageFlag.DAMAGE_FIRE > 0 then
            return false -- Cancela o dano
        end
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnDamageTaken, EntityType.ENTITY_PLAYER)
    -- FIRE KILLER END