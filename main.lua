if not RebalanceRespawnShuffleCost then
	_G.RebalanceRespawnShuffleCost = _G.RebalanceRespawnShuffleCost or {}
	RebalanceRespawnShuffleCost._save_path = SavePath .. "RebalanceRespawnShuffleCost.txt"

	function RebalanceRespawnShuffleCost:load()
        local file = io.open(self._save_path, "r")
		RebalanceRespawnShuffleCost.restart_cost = RebalanceRespawnShuffleCost.restart_cost or 0.0
		if file and RebalanceRespawnShuffleCost.restart_cost == 0.0 then
			RebalanceRespawnShuffleCost.restart_cost = file:read("n") or 0.0
		end
		log("RRSC1 " .. tostring(RebalanceRespawnShuffleCost.restart_cost))
    end

	function RebalanceRespawnShuffleCost:save()
        local file = io.open(self._save_path, "w")
        if file then
            file:write(tostring(RebalanceRespawnShuffleCost.restart_cost))
        end
    end

	Hooks:PostHook(CrimeSpreeManager, "load", "load_RebalanceRespawnShuffleCost", function (self)
		RebalanceRespawnShuffleCost:load()
	end)

	Hooks:PostHook(CrimeSpreeManager, "save", "save_RebalanceRespawnShuffleCost", function (self)
		RebalanceRespawnShuffleCost:save()
	end)

	Hooks:PostHook(CrimeSpreeManager, "get_continue_cost", "get_continue_cost_rebalanced", function (self)
		if Hooks:GetReturn() == 0 then return 0 end
		return math.max(6,(RebalanceRespawnShuffleCost.restart_cost*6))
	end)

	Hooks:OverrideFunction(CrimeSpreeManager, "continue_crime_spree", function (self) --rewritten to remove shuffling heists on restart.
		if not self:can_continue_spree() then
			return false
		end

		local cost = self:get_continue_cost(self:spree_level())

		managers.custom_safehouse:deduct_coins(cost, TelemetryConst.economy_origin.continue_crime_spree)

		self._global.failure_data = nil
		self._global.randomization_cost = false

		if Network:multiplayer() and managers.network:session() then
			self:_send_crime_spree_level_to_peers()
		else
			print("[CrimeSpreeManager:continue_crime_spree] offline")
		end

		RebalanceRespawnShuffleCost.restart_cost = RebalanceRespawnShuffleCost.restart_cost*2
		if RebalanceRespawnShuffleCost.restart_cost < 1 then RebalanceRespawnShuffleCost.restart_cost = 1.0 end

		return true
	end)


	Hooks:PostHook(CrimeSpreeManager, "randomization_cost", "randomization_cost_rebalanced", function (self)
		local level = self:spree_level()
		log("RRSC2 " .. tostring( math.floor(tweak_data.crime_spree.continue_cost[1] + tweak_data.crime_spree.continue_cost[2] * (level or 0)) ))
		if level == 0 then
			return 6
		else
			return math.floor(tweak_data.crime_spree.continue_cost[1] + tweak_data.crime_spree.continue_cost[2] * (level or 0))
		end
	end)

end

