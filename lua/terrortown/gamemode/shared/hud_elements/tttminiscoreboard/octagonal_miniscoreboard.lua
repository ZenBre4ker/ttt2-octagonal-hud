local base = "octagonal_element"

HUDELEMENT.Base = base

DEFINE_BASECLASS(base)

HUDELEMENT.togglable = true

if CLIENT then
	local margin = 0
	local element_margin = 0
	local row_count = 2

	local const_defaults = {
		basepos = {x = 0, y = 0},
		size = {w = 60, h = 60},
		minsize = {w = 0, h = 0}
	}

	function HUDELEMENT:PreInitialize()
		hudelements.RegisterChildRelation(self.id, "octagonal_roundinfo", false)
	end

	HUDELEMENT.icon_in_conf = Material("vgui/ttt/indirect_confirmed")
	HUDELEMENT.icon_revived = Material("vgui/ttt/revived")

	function HUDELEMENT:Initialize()
		self.margin = margin
		self.element_margin = element_margin
		self.column_count = 0
		self.parentInstance = hudelements.GetStored(self.parent)
		self.curPlayerCount = 0
		self.ply_ind_size = 0
		self.scale = 1.0
		self.basecolor = self:GetHUDBasecolor()

		BaseClass.Initialize(self)
	end

	-- parameter overwrites
	function HUDELEMENT:ShouldDraw()
		return GAMEMODE.round_state == ROUND_ACTIVE
	end

	function HUDELEMENT:InheritParentBorder()
		return true
	end
	-- parameter overwrites end

	function HUDELEMENT:GetDefaults()
		return const_defaults
	end

	function HUDELEMENT:PerformLayout()
		local parent_pos = self.parentInstance:GetPos()
		local parent_size = self.parentInstance:GetSize()
		local parent_defaults = self.parentInstance:GetDefaults()
		local h = parent_size.h

		self.basecolor = self:GetHUDBasecolor()
		self.scale = h / parent_defaults.size.h
		self.margin = margin * self.scale
		self.element_margin = element_margin * self.scale
		self.ply_ind_size = math.Round((h - self.element_margin - self.margin * 2) / row_count)

		local players = util.GetFilteredPlayers(function (ply)
			return ply:IsTerror() or ply:IsDeadTerror()
		end)

		self.curPlayerCount = #players
		self.column_count = math.Round(#players * 0.5)

		local w = self.element_margin * (self.column_count - 1) + self.ply_ind_size * self.column_count + 2 * self.margin

		self:SetPos(parent_pos.x + parent_size.w, parent_pos.y)
		self:SetSize(w, h)

		BaseClass.PerformLayout(self)
	end

	local function GetMSBColorForPlayer(ply, basecolor)
		local color = basecolor -- not yet confirmed
		if ply:OnceFound() then
			if ply:RoleKnown() then
				color = ply:GetRoleColor() -- role known
			else
				color = Color(150,150,150,255) -- indirect confirmed
			end
		end

		return hook.Run("TTT2ModifyMiniscoreboardColor", ply, color) or color
	end

	function HUDELEMENT:Draw()
		local players = util.GetFilteredPlayers(function (ply)
			return ply:IsTerror() or ply:IsDeadTerror()
		end)

		if #players ~= self.curPlayerCount then
			self:PerformLayout()
		end

		-- sort playerlist: confirmed players should be in the first position
		table.sort(players, function(a, b)
			if not a:OnceFound() then
				return false
			end

			if b:OnceFound() and (a:GetFirstFound() >= b:GetFirstFound()) then -- bodies were confirmed and body a was confirmed prior to body b
				return false
			end

			return true
		end)

		-- draw bg and shadow
		--self:DrawBg(self.pos.x, self.pos.y, self.size.w, self.size.h, self.basecolor)

		-- draw squares
		local tmp_x, tmp_y = self.pos.x, self.pos.y

		for i, p in ipairs(players) do
			tmp_x = self.pos.x + self.margin + (self.element_margin + self.ply_ind_size) * math.floor((i - 1) / row_count)
			tmp_y = self.pos.y + self.margin + (self.element_margin + self.ply_ind_size) * ((i - 1) % row_count)

			local ply_color = GetMSBColorForPlayer(p, self.basecolor)

            self:DrawBg(tmp_x, tmp_y, self.ply_ind_size, self.ply_ind_size, ply_color)

			if p:Revived() then
				util.DrawFilteredTexturedRect(tmp_x +3, tmp_y +3, self.ply_ind_size -6, self.ply_ind_size -6, self.icon_revived, 180, {r=0,g=0,b=0})
			elseif p:OnceFound() and not p:RoleKnown() then -- draw marker on indirect confirmed bodies
				util.DrawFilteredTexturedRect(tmp_x +3, tmp_y +3, self.ply_ind_size -6, self.ply_ind_size -6, self.icon_in_conf, 120, {r=0,g=0,b=0})
			end
		end
	end
end
