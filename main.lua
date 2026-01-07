dofile(ModPath .. "automenubuilder.lua")

if not RebalanceRespawnShuffleCost then
	_G.RebalanceRespawnShuffleCost = _G.RebalanceRespawnShuffleCost or {}
	RebalanceRespawnShuffleCost._save_path = SavePath .. "RebalanceRespawnShuffleCost.txt"
	RebalanceRespawnShuffleCost.restart_cost = RebalanceRespawnShuffleCost.restart_cost or 0.0

	RebalanceRespawnShuffleCost.settings = {
		respawn_enable = true,
		respawn_base_cost = 6,
		respawn_cost_growth_curve = 1,
		shuffle_enable = true,
		shuffle_starting_cost = 6,
		shuffle_growth_cost = 0.7,
	}
	RebalanceRespawnShuffleCost.values = {
		respawn_base_cost = {0,24,1},
		respawn_cost_growth_curve = {"linear","exponential"},
		shuffle_starting_cost = {0,24,1},
		shuffle_growth_cost = {0,2.0,0.1},
	}
	RebalanceRespawnShuffleCost.order = {
		respawn_enable = -1,
		respawn_base_cost = -2,
		respawn_cost_growth_curve = -3,
		shuffle_enable = -4,
		shuffle_starting_cost = -5,
		shuffle_growth_cost = -6,
	}

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
		return math.max(RebalanceRespawnShuffleCost.settings.respawn_starting_cost,(RebalanceRespawnShuffleCost.restart_cost*RebalanceRespawnShuffleCost.settings.respawn_starting_cost))
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
			if RebalanceRespawnShuffleCost.settings.respawn_cost_growth_curve == "exponential" then
				RebalanceRespawnShuffleCost.restart_cost = RebalanceRespawnShuffleCost.restart_cost*2
			elseif RebalanceRespawnShuffleCost.settings.respawn_cost_growth_curve == "linear"
				RebalanceRespawnShuffleCost.restart_cost = RebalanceRespawnShuffleCost.restart_cost+1
			end
			if RebalanceRespawnShuffleCost.restart_cost < 1 then RebalanceRespawnShuffleCost.restart_cost = 1.0 end
		else
			self:generate_new_mission_set()
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
		AutoMenuBuilder:load_settings(RebalanceRespawnShuffleCost.settings, "RebalanceRespawnShuffleCostSettings")
		AutoMenuBuilder:create_menu_from_table(nodes, RebalanceRespawnShuffleCost.settings, "RebalanceRespawnShuffleCostSettings", "blt_options",RebalanceRespawnShuffleCost.values)
	end)

	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitRRSC", function (loc)
		loc:add_localized_strings({
			["menu_RebalanceRespawnShuffleCostSettings"] = "Rebalance Respawn and Shuffle Cost",
			["menu_RebalanceRespawnShuffleCostSettings_respawn_base_cost_desc"] = "Base cost for restarts.",
			["menu_RebalanceRespawnShuffleCostSettings_respawn_cost_growth_curve_desc"] = "Exponential multiplies cost by 2 every restart(n=n*2), Linear increases current cost by base cost every restart(n=n+1)/",
			["menu_RebalanceRespawnShuffleCostSettings_shuffle_starting_cost_desc"] = "Base cost for shuffle.",
			["menu_RebalanceRespawnShuffleCostSettings_shuffle_growth_cost_desc"] = "Multiplier for shuffle cost growth per level."
		})
	end)
end

