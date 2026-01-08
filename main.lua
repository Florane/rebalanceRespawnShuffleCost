dofile(ModPath .. "automenubuilder.lua")

if not RebalanceRespawnShuffleCost then
	_G.RebalanceRespawnShuffleCost = _G.RebalanceRespawnShuffleCost or {}
	RebalanceRespawnShuffleCost._save_path = SavePath .. "RebalanceRespawnShuffleCost.txt"
	RebalanceRespawnShuffleCost.restart_cost = RebalanceRespawnShuffleCost.restart_cost or 0.0

	RebalanceRespawnShuffleCost.settings = {
		respawn_enable = true,
		respawn_base_cost = 6,
		respawn_cost_growth_curve = 1,
		divider = 0,
		shuffle_enable = true,
		shuffle_starting_cost = 6,
		shuffle_growth_cost = 0.7,
	}
	RebalanceRespawnShuffleCost.values = {
		respawn_base_cost = {0,24,1},
		respawn_cost_growth_curve = {"menu_RRSC_linear","menu_RRSC_exponential"},
		divider = "divider",
		shuffle_starting_cost = {0,24,1},
		shuffle_growth_cost = {0,2.0,0.1},
	}

	local function orderList(order)
		local ret = {}
		for i, v in ipairs(order) do
			ret[v] = -i
		end
		return ret
	end
	RebalanceRespawnShuffleCost.order = orderList({
		"respawn_enable",
		"respawn_base_cost",
		"respawn_cost_growth_curve",
		"divider",
		"shuffle_enable",
		"shuffle_starting_cost",
		"shuffle_growth_cost"})

	function RebalanceRespawnShuffleCost:load()
        local file = io.open(self._save_path, "r")
		if file then
			RebalanceRespawnShuffleCost.restart_cost = file:read("*n") or 0.0
		end
		file:close()
    end
	Hooks:PostHook(CrimeSpreeManager, "load", "load_RebalanceRespawnShuffleCost", function (self)
		RebalanceRespawnShuffleCost:load()
	end)

	function RebalanceRespawnShuffleCost:save()
        local file = io.open(self._save_path, "w")
        if file then
            file:write(RebalanceRespawnShuffleCost.restart_cost)
        end
		file:close()
    end
	Hooks:PostHook(CrimeSpreeManager, "save", "save_RebalanceRespawnShuffleCost", function (self)
		RebalanceRespawnShuffleCost:save()
	end)

	Hooks:PostHook(CrimeSpreeManager, "reset_crime_spree", "reset_restart_cost", function (self)
		RebalanceRespawnShuffleCost.restart_cost = 0.0
		RebalanceRespawnShuffleCost:save()
	end)

	Hooks:PostHook(CrimeSpreeManager, "get_continue_cost", "get_continue_cost_rebalanced", function (self)
		if not RebalanceRespawnShuffleCost.settings.respawn_enable then return Hooks:GetReturn() end

		if Hooks:GetReturn() == 0 then return 0 end
		return math.max(RebalanceRespawnShuffleCost.settings.respawn_base_cost,(RebalanceRespawnShuffleCost.restart_cost*RebalanceRespawnShuffleCost.settings.respawn_base_cost))
	end)

	Hooks:OverrideFunction(CrimeSpreeManager, "continue_crime_spree", function (self) --rewritten to remove shuffling heists on restart.
		if not self:can_continue_spree() then
			return false
		end

		local cost = self:get_continue_cost(self:spree_level())

		managers.custom_safehouse:deduct_coins(cost, TelemetryConst.economy_origin.continue_crime_spree)

		self._global.failure_data = nil
		self._global.randomization_cost = false

		if RebalanceRespawnShuffleCost.settings.respawn_enable then
			if RebalanceRespawnShuffleCost.settings.respawn_cost_growth_curve == 0 then
				RebalanceRespawnShuffleCost.restart_cost = RebalanceRespawnShuffleCost.restart_cost+1
			elseif RebalanceRespawnShuffleCost.settings.respawn_cost_growth_curve == 1 then
				RebalanceRespawnShuffleCost.restart_cost = RebalanceRespawnShuffleCost.restart_cost*2
			end
			if RebalanceRespawnShuffleCost.restart_cost < 1 then RebalanceRespawnShuffleCost.restart_cost = 1.0 end
		else
			self:generate_new_mission_set()
			--there is a better way to implement disabling changes
			--but this one is funnier
		end

		if Network:multiplayer() and managers.network:session() then
			self:_send_crime_spree_level_to_peers()
		else
			print("[CrimeSpreeManager:continue_crime_spree] offline")
		end

		return true
	end)


	Hooks:PostHook(CrimeSpreeManager, "randomization_cost", "randomization_cost_rebalanced", function (self)
		if not RebalanceRespawnShuffleCost.settings.shuffle_enable then return Hooks:GetReturn() end

		local level = self:spree_level()
		if level == 0 then
			return RebalanceRespawnShuffleCost.settings.shuffle_starting_cost
		else
			return math.floor(RebalanceRespawnShuffleCost.settings.shuffle_starting_cost + RebalanceRespawnShuffleCost.settings.shuffle_growth_cost * (level or 0))
		end
	end)

	Hooks:Add("MenuManagerBuildCustomMenus","MenuManagerBuildCustomMenusRRSC", function (menu_manager, nodes)
		AutoMenuBuilder_mod:load_settings(RebalanceRespawnShuffleCost.settings, "RebalanceRespawnShuffleCostSettings")
		AutoMenuBuilder_mod:create_menu_from_table(nodes, RebalanceRespawnShuffleCost.settings, "RebalanceRespawnShuffleCostSettings", "blt_options",RebalanceRespawnShuffleCost.values,RebalanceRespawnShuffleCost.order)
	end)

	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitRRSC", function (loc)
		loc:add_localized_strings({
			["menu_RebalanceRespawnShuffleCostSettings"] = "Rebalance Spree Continue Cost",

			["menu_RebalanceRespawnShuffleCostSettings_respawn_enable"] = "ENABLE CONTINUE",
			["menu_RebalanceRespawnShuffleCostSettings_respawn_base_cost"] = "BASE COST",
			["menu_RebalanceRespawnShuffleCostSettings_respawn_cost_growth_curve"] = "GROWTH CURVE",
			["menu_RebalanceRespawnShuffleCostSettings_shuffle_enable"] = "ENABLE SHUFFLE",
			["menu_RebalanceRespawnShuffleCostSettings_shuffle_starting_cost"] = "STARTING COST",
			["menu_RebalanceRespawnShuffleCostSettings_shuffle_growth_cost"] = "GROWTH COST",

			["menu_RebalanceRespawnShuffleCostSettings_respawn_base_cost_desc"] = "Base cost for continues.",
			["menu_RebalanceRespawnShuffleCostSettings_respawn_cost_growth_curve_desc"] = "Exponential multiplies cost by 2 every continue(n=n*2),\nLinear increases current cost by base cost every continue(n=n+1)",
			["menu_RebalanceRespawnShuffleCostSettings_shuffle_starting_cost_desc"] = "Base cost for shuffle.",
			["menu_RebalanceRespawnShuffleCostSettings_shuffle_growth_cost_desc"] = "Multiplier for shuffle cost growth per level.",

			["menu_RRSC_linear"] = "LINEAR",
			["menu_RRSC_exponential"] = "EXPONENTIAL",
		})
	end)
end

