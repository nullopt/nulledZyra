--[[
	Zyra:
	- Rooting enemies in combo
	- Use plants while casting spells
	- R on X amount of plants
	- R on X enemies

	- anti gapcloser with E

	- KS logic
]]

-- check if we're playing as zyra
-- if we're not playing as zyra, then exit
if myHero.charName ~= "Zyra" then
    print("You're not playing as Zyra")
    return
end

-- load TS
local DreamTS = require("DreamTS")
-- ModernUOL
local UOL = {}

-- create zyra object
local Zyra = {
    q = {
        type = "circular",
        radius = 345, -- TODO: check this is the correct value
        speed = math.huge,
        range = 600,
        delay = 0.25
    },
    w = {},
    e = {
        type = "linear",
        width = 80, -- TODO: get real value
        speed = 1150,
        range = 1100,
        delay = 0.25
    },
    r = {},
    menu = {},
    rates = {"instant", "slow", "very slow"}
}

-- initial function to create:
--	menu
--	target selector
--	add events
function Zyra:__init()
    -- create our menu
	--[[
		[nulledZyra]
			-> [Combo]
			-> [Harass]
			-> [KS]
			-> [Anti-Gap]
	]]

    self.menu = Menu("nulledZyra", "nulledZyra")
    self.menu:sub("dreamTs", "Target Selector")

    self.TS = DreamTS(self.menu.dreamTs, {
        Damage = DreamTS.Damages.AP
    })

    self.menu:sub("combo", "Combo")
    self.menu.combo:checkbox("useq", "Use Q", true)
    self.menu.combo:checkbox("usee", "Use E", true)

    -- 1,             2,            3,
    -- instant,       slow,         veryslow
    -- :list(id, name, value, list, isPriority, isUnremovable)
    self.menu.combo:list("pred", "Hit Chance", 2, self.rates)

    AddEvent(Events.OnTick, function()
        self:OnTick()
    end)

    PrintChat("Loaded nulledZyra")
end

-- get the prediction from the menu
function Zyra:GetCastRate()
    return self.rates[self.menu.combo.pred.value]
end

function Zyra:ComboQ()
    -- check use q - return if disabled
    if not self.menu.combo.useq:get() then
        return
    end

    -- check if spell is ready - return if not
    if not myHero.spellbook:CanUseSpell(SpellSlot.Q) == 0 then
        return
    end

    -- get the most valid target
    -- get the prediction on the target
    local qTarget, qPred = self.TS:GetTarget(self.q)

    -- check if target is valid - return if not
    if not qTarget then
        return
    end

    -- check if pred is valid - return if not
    if not qPred then
        return
    end

    -- check if the rate (hit chance) is the same or better than
    -- the menu value
    if not qPred.rates[self:GetCastRate()] then
        return
    end

    -- cast the spell on the pred position
    myHero.spellbook:CastSpell(SpellSlot.Q, qPred.castPosition)
end

function Zyra:ComboE()
    -- check use e - return if disabled
    if not self.menu.combo.usee:get() then
        return
    end

    -- check if spell is ready - return if not
    if not myHero.spellbook:CanUseSpell(SpellSlot.E) == 0 then
        return
    end

    -- get the most valid target
    -- get the prediction on the target
    local eTarget, ePred = self.TS:GetTarget(self.e)

    -- check if target is valid - return if not
    if not eTarget then
        return
    end

    -- check if pred is valid - return if not
    if not ePred then
        return
    end

    -- check if the rate (hit chance) is the same or better than
    -- the menu value
    if not ePred.rates[self:GetCastRate()] then
        return
    end

    -- cast the spell on the pred position
    myHero.spellbook:CastSpell(SpellSlot.E, ePred.castPosition)
end

function Zyra:OnTick()
    if UOL:GetMode() == "Combo" then
        -- cast e logic
        Zyra:ComboE()
        -- cast q logic
        Zyra:ComboQ()
    end
end

---@param obj GameObject
function Zyra:OnCreateObject(obj)
    -- look for plants
end

-- list of dependencies
local dependencies = {{"DreamPred", PaidScript.DREAM_PRED, function()
    return _G.Prediction
end}}

-- load dependencies
_G.LoadDependenciesAsync(dependencies, function(success)
    if success then
        -- load MED
        UOL = require("ModernUOL")
        if not UOL then -- UOL not present on the computer we download it
            DownloadInternalFileAsync("ModernUOL.lua", COMMON_PATH, function(successTwo)
                if successTwo then
                    PrintChat("[nulledZyra] ModernUOL Updated: Press F6 to reload.")
                end
            end)
        else
            -- Load MED as default orbwalker
            UOL:SetDefaultOrbwalker(_G.PaidScript.MED, 15)
            UOL:OnOrbLoad(function()
                -- all our onload functionality
                Zyra:__init()
            end)
        end
    else
        print("unable to load dependencies")
        return
    end
end)

-- return the zyra object
-- might be useful if you're creating an AIO
return Zyra
