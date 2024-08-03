AddCSLuaFile()

-- Core file
-- You don't need to write any lua, you just need to create a folder to add 2Dplayer
-- You can customize according to the template

local function addconvar(n,v,b)
    return CreateClientConVar('qtg_2dply_'..n,v,true,b)
end

local hidewep

if CLIENT then
    hidewep = addconvar('hidewep',1)
    CreateClientConVar( "qtg_2dply_brightness", "1", true)
end

local function addhook(a,b,c)
    hook.Add(a,c or 'qtg_2dply',b)
end

local function remhook(a,b)
    hook.Remove(a,b or 'qtg_2dply')
end

local function iargs(n,t,...)
    n = n or ''
    t = t or 'nil'

    for i = 1,select('#',...) do
        local ty = type(select(i,...))

        if t == 'Entity' and isentity(select(i,...)) then
            ty = 'Entity'
        end

        if ty != t then
            error('[2D Player Model System] bad argument #'..i..' to \''..n..'\' ('..t..' expected, got '..type(select(i,...))..')')
        end
    end
end

local nt = {
    '.png',
    '.jpg',
    '.jpeg',
    '.vtf'
}

local function sortf(a,b)
    for k,v in pairs(nt) do
        a = string.gsub(a,v,'')
    end
    
    if tonumber(a) then
        a = tonumber(a)
    end

    for k,v in pairs(nt) do
        b = string.gsub(b,v,'')
    end

    if tonumber(b) then
        b = tonumber(b)
    end

    if !isnumber(a) or !isnumber(b) then
        a = tostring(a)
        b = tostring(b)
    end

    return a < b
end

QTG2DPLY = QTG2DPLY or {}
QTG2DPLY.List = QTG2DPLY.List or {}

function QTG2DPLY.Add2DPly(n,b)
    iargs('Add2DPly','string',n)

    local id = string.lower(string.gsub(n,' ','_'))

    QTG2DPLY.List[n] = {
        name = n,
        mats = {}
    }

    player_manager.AddValidModel(n,'models/player/alyx.mdl')
    player_manager.AddValidHands(n,'models/weapons/c_arms_citizen.mdl',0,'0000000')

    if b then
        for i = 1,2 do
            local t = {}

            t.Name = n..' '..(i == 1 and '(Friendly)' or '(Enemy)')
            t.Class = i == 1 and 'npc_citizen' or 'npc_combine_s'
            t.Health = 100
            t.Category = '2D NPC'
            t.KeyValues = {target = 'qtg_2dply_is2dnpc|'..n}
            
            if i == 1 then
                t.KeyValues.citizentype = CT_DEFAULT
                t.KeyValues.SquadName = 'resistance'

                list.Set('NPC',id..'_friendly',t)
            else
                t.Numgrenades = 4
                t.Weapons = {'weapon_smg1','weapon_ar2'}

                list.Set('NPC',id..'_enemy',t)
            end
        end
    end
end

function QTG2DPLY.GetPlyModelName(p)
    iargs('GetPlyModelName','Entity',p)

    if p:IsPlayer() then
        if p:IsBot() then
            return p.__qtg2dplymodelbot or ''
        else
            return p:GetNWString('qtg_2dply_cl_playermodel')
        end
    end

    return ''
end

function QTG2DPLY.SetBot2dPly(p,s)
    if !p:IsBot() then return end

    p.__qtg2dplymodelbot = s or ''

    p:SetModel('models/player/alyx.mdl')
end

function QTG2DPLY.Is2DPly(p)
    if isstring(p) then
        return tobool(QTG2DPLY.List[p])
    end

    if IsValid(p) and p:IsNPC() then
        return p:GetNWBool('qtg_2dply_is2dnpc')
    end

    if CLIENT and !IsValid(p) then
        p = LocalPlayer()
    end

    if !IsValid(p) then return false end

    local pm = QTG2DPLY.GetPlyModelName(p)

    if !pm then return false end

    if CLIENT then
        if QTG2DPLY.List[pm] and p:GetModel() == 'models/player/kleiner.mdl' then -- WTF? How??
            p:SetModel('models/player/alyx.mdl')
        end

        net.Start('qtg_2dply_serveris2d')
        net.WriteString(p:GetModel())
        net.SendToServer()
    end

    return tobool(QTG2DPLY.List[pm] and p:GetModel() == 'models/player/alyx.mdl')
end

function QTG2DPLY.NWIs2DPly(p)
    if !IsValid(p) then return false end

    return p:GetNWBool('qtg_2dply_is2dply')
end

function QTG2DPLY.GetList()
    return QTG2DPLY.List
end

function QTG2DPLY.GetPath(n)
    iargs('GetPath','string',n)

    if !QTG2DPLY.List[n] then return '' end

    return '2dplayers/'..string.lower(string.gsub(QTG2DPLY.List[n].name,' ','_'))
end

function QTG2DPLY.Init()
    local f,d = file.Find('materials/2dplayers/*','GAME')

    for k,v in pairs(d) do
        local f2,d2 = file.Find('materials/2dplayers/'..v..'/*','GAME')

        if next(d2) != nil then
            v = string.lower(string.gsub(v,'_',' '))
            v = string.upper(string.sub(v,1,1))..string.sub(v,2)

            QTG2DPLY.Add2DPly(v,true)
        end
    end
end

QTG2DPLY.Init()

net.Receive('qtg_2dply_reload',function()
    QTG2DPLY.Init()

    if SERVER then
        net.Start('qtg_2dply_reload')
        net.Broadcast()
    end
end)

concommand.Add('qtg_2dply_reload',function(p,c,a,as)
    if SERVER then
        QTG2DPLY.Init()

        net.Start('qtg_2dply_reload')
        net.Broadcast()
    elseif p:IsAdmin() then
        -- QTG2DPLY.Init()

        net.Start('qtg_2dply_reload')
        net.SendToServer()
    end
end)

if CLIENT then
    concommand.Add('qtg_2dply_reload_client',function(p,c,a,as)
        QTG2DPLY.Init()
    end)

    function QTG2DPLY.FindMat(n)
        local t = QTG2DPLY.List[n].mats
        local pa =  QTG2DPLY.GetPath(n)
        local f,d = file.Find('materials/'..pa..'/*','GAME')

        t['normal'] = {}

        for k,v in pairs(d) do
            local f2,d2 = file.Find('materials/'..pa..'/'..v..'/*','GAME')

            t['normal'][v] = {}

            print(v)

            table.sort(f2,sortf)

            for k2,v2 in ipairs(f2) do
                local typ = string.Split(pa..'/'..v..'/'..v2,'.')
                typ = tostring(typ[#typ])

                if typ == 'vmt' then
                    continue
                end

                t['normal'][v][#t['normal'][v]+1] = {
                    mat = Material(pa..'/'..v..'/'..v2,v != 'back' and v != 'default' and 'nocull' or nil),
                    type = typ or ''
                }
            end

            for k3,v3 in pairs(d2) do
                if !t[v3] then
                    t[v3] = {}
                end

                t[v3][v] = {}

                local f3,d3 = file.Find('materials/'..pa..'/'..v..'/'..v3..'/*','GAME')

                table.sort(f3,sortf)

                for k4,v4 in ipairs(f3) do
                    local typ = string.Split(pa..'/'..v..'/'..v3..'/'..v4,'.')
                    typ = tostring(typ[#typ])

                    if typ == 'vmt' then
                        continue
                    end

                    t[v3][v][#t[v3][v]+1] = {
                        mat = Material(pa..'/'..v..'/'..v3..'/'..v4,v != 'back' and v != 'default' and 'nocull' or nil),
                        type = typ or ''
                    }
                end
            end
        end
    end

    function QTG2DPLY.GetMat(s,p)
        if !IsValid(p) then
            p = LocalPlayer()
        end

        local c = QTG2DPLY.GetPlyModelName(p)

        if s then
            c = s
        end

        if !c then return end
        if !QTG2DPLY.List[c] then return end
        if next(QTG2DPLY.List[c].mats) == nil then
            QTG2DPLY.FindMat(c)
        end
    
        return QTG2DPLY.List[c].mats
    end

    function QTG2DPLY.RenderOverride(p,e)
        if !IsValid(p) then return end

        if p:IsPlayer() then
            local c = QTG2DPLY.GetPlyModelName(p)

            if QTG2DPLY.List[c] then
                local w = p:GetActiveWeapon()

                if IsValid(w) and hidewep:GetBool() then
                    w:SetNoDraw(p:GetModel() == 'models/player/alyx.mdl' or QTG2DPLY.NWIs2DPly(p))
                end
            end
        else
            local w = p:GetActiveWeapon()

            if IsValid(w) then
                w:SetNoDraw(true)
            end
        end

        if QTG2DPLY.Is2DPly(p) or QTG2DPLY.NWIs2DPly(p) then
            local pos = p:GetPos():ToScreen()
            local iserror = false
            local veh = p:IsPlayer() and p:GetVehicle() or nil

            if !pos.visible then
                return true
            end

            local t = QTG2DPLY.GetMat(p:IsNPC() and p:GetNWString('qtg_2dply_npctype') or nil,p)

            if !t then
                iserror = true
            end

            local tbl = {}
            local Alive = p:IsNPC() and !IsValid(e) or p:Alive()

            if !iserror then
                tbl = t.normal

                if p:IsPlayer() and p:Crouching() and !IsValid(e) and (t.duck or t.crouch) then
                    local tt

                    if t.crouch then
                        tt = t.crouch
                    elseif t.duck then
                        tt = t.duck
                    end

                    tbl = tt
                end

                if p:IsPlayer() and !p:IsOnGround() and !IsValid(e) and t.jump then
                    tbl = t.jump
                end

                if p:GetMoveType() == MOVETYPE_NOCLIP and !IsValid(e) and t.noclip then
                    tbl = t.noclip
                end

                if IsValid(veh) and !IsValid(e) and t.sit then
                    tbl = t.sit
                end

                if !Alive and t.death then
                    tbl = t.death
                end

                if p:WaterLevel() > 1 and !IsValid(e) and t.swimming then
                    tbl = t.swimming
                end
            end

            local st = 'default'
            local st2 = ''
            local w = p:GetActiveWeapon()

            if IsValid(w) then
                local mn = string.gsub(w:GetModel() or '','.mdl','')
                mn = string.gsub(mn,'/','.')

                if tbl[mn] then
                    st2 = mn
                end
                
                if tbl[w:GetClass()] then
                    st2 = w:GetClass()
                end
            end

            if !iserror and (next(tbl) == nil or next(tbl[st]) == nil) then
                tbl = t.normal
            end

            if next(tbl) == nil or next(tbl[st]) == nil then
                iserror = true
            end

            local time = 0.02
            local pvel = p:GetVelocity():Length()
            local pvb = pvel/200

            time = time/pvb
            time = math.min(time,0.5)

            if !iserror then
                if !p.__qtg2di then
                    p.__qtg2di = 1
                end

                if !p.__qtg2ditime then
                    p.__qtg2ditime = CurTime()+time
                end

                if p.__qtg2ditime <= CurTime() and pvb > 0 and !IsValid(e) then
                    p.__qtg2di = p.__qtg2di+1
                    p.__qtg2ditime = CurTime()+time
                end

                if p.__qtg2di > #tbl[st] then
                    p.__qtg2di = 1
                end
            end

            local pos = p:GetPos()+p:GetUp()*p:OBBCenter().z
            local ang = p:EyeAngles()
            local vehfix = Angle(0,90,0)

            if IsValid(veh) then
                pos = p:GetPos()+p:GetUp()*(p:OBBCenter().z/2)
                ang = p:GetAngles()
            end

            if IsValid(e) then
                if e:GetClass() == 'class C_BaseFlex' then
                    ang = e:EyeAngles()
                    pos = e:GetPos()+Vector(0,0,e:OBBCenter().z)+ang:Right()*30+ang:Up()*20+ang:Forward()*-50
                else
                    local eye = e:GetAttachment(e:LookupAttachment('mouth'))

                    pos = e:GetPos()

                    if eye then
                        ang = eye.Ang
                    end
                end
            elseif !Alive then
                return
            elseif !IsValid(veh) then
                ang.p = math.Clamp(ang.p,-20,20)
            end

            local fixr = Vector(0,90,90)

            ang:RotateAroundAxis(ang:Right(),fixr.x)
            ang:RotateAroundAxis(ang:Up(),fixr.y)
            ang:RotateAroundAxis(ang:Forward(),fixr.z)

            local function draw2d(isback)
            	local brightness = GetConVar( "qtg_2dply_brightness" )
                local lcolor = render.ComputeLighting(pos,Vector(0,0,( brightness:GetFloat() )))
                local c = p:GetColor()

                c.r = c.r*math.Clamp(lcolor.x,0,1)
                c.g = c.g*math.Clamp(lcolor.y,0,1)
                c.b = c.b*math.Clamp(lcolor.z,0,1)

                surface.SetDrawColor(Color(c.r,c.g,c.b,c.a))

                if iserror then
                    surface.DrawRect(-125,-250,250,500)
                    surface.SetFont('DermaLarge')
                    surface.SetTextColor(0,0,0)
                    surface.SetTextPos(-100,-80)
                    surface.DrawText('2D Player Model')
                    surface.SetTextPos(-100,-40)
                    surface.DrawText('Invalid Material')

                    return
                end

                if isback and tbl.back then
                    surface.SetMaterial(tbl.back[p.__qtg2di].mat)
                    surface.DrawTexturedRect(-250,-250,500,500)
                else
                    surface.SetMaterial(tbl[st][p.__qtg2di].mat)
                    surface.DrawTexturedRect(-250,-250,500,500)
                end

                if st2 != '' and !isback then
                    if tbl[st2] and tbl[st2][p.__qtg2di] and tbl[st2][p.__qtg2di].mat then
                        surface.SetMaterial(tbl[st2][p.__qtg2di].mat)
                        surface.DrawTexturedRect(-250,-250,500,500)
                    end
                end
            end

            cam.Start3D2D(pos,ang,0.15)
                draw2d()
            cam.End3D2D()

            fixr = Vector(0,-90,90)
            ang = p:EyeAngles()

            if IsValid(veh) then
                ang = p:GetAngles()
            end

            if IsValid(e) then
                if e:GetClass() == 'class C_BaseFlex' then
                    ang = e:EyeAngles()
                else
                    local eye = e:GetAttachment(e:LookupAttachment('mouth'))

                    if eye then
                        ang = eye.Ang
                    end
                end
            elseif !IsValid(veh) then
                ang.p = math.Clamp(ang.p,-20,20)
            end

            ang:RotateAroundAxis(ang:Right(),fixr.x)
            ang:RotateAroundAxis(ang:Up(),fixr.y)
            ang:RotateAroundAxis(ang:Forward(),fixr.z)

            cam.Start3D2D(pos,ang,0.15)
                draw2d(true)
            cam.End3D2D()

            return true
        end
    end

    addhook('HUDPaint',function()
        for k,p in pairs(player.GetAll()) do
            if !IsValid(p) then return end
            if QTG2DPLY.Is2DPly(p) and !p.__qtg2dplyisofunc then
                p.__qtg2dplyisofunc = true

                local old = p.RenderOverride or function(self) self:DrawModel() end

                p.RenderOverride = function(self)
                    local r = QTG2DPLY.RenderOverride(self)

                    if r then
                        return
                    end

                    return old(self)
                end
            end

            if QTG2DPLY.Is2DPly(p) and IsValid(p:GetRagdollEntity()) and !p:GetRagdollEntity().__qtg2dplyisofunc then
                p:GetRagdollEntity().__qtg2dplyisofunc = true

                local old = p:GetRagdollEntity().RenderOverride or function(self) self:DrawModel() end

                p:GetRagdollEntity().RenderOverride = function(self)
                    local r = QTG2DPLY.RenderOverride(p,self)

                    if r then
                        return
                    end

                    return old(self)
                end
            end
        end

        local t = {}

        for k,v in pairs(ents.FindByClass('npc_citizen')) do
            t[#t+1] = v
        end

        for k,v in pairs(ents.FindByClass('npc_combine_s')) do
            t[#t+1] = v
        end

        for k,v in pairs(t) do
            if v:GetNWBool('qtg_2dply_is2dnpc') then
                local old = v.RenderOverride or function(self) self:DrawModel() end
                v.__oldRenderOverride = v.__oldRenderOverride or old

                v.RenderOverride = function(self)
                    local r = QTG2DPLY.RenderOverride(self)
    
                    if r then
                        return
                    end
    
                    return self:__oldRenderOverride()
                end
            end
        end
    end)

    local p = vgui.GetControlTable('SpawnIcon')

    if p then
        p.__oldPaint = p.__oldPaint or p.Paint

        function p:Paint(w,h)
            if self.playermodel and QTG2DPLY.Is2DPly(self.playermodel) and !self.__isinit then
                local mat = QTG2DPLY.GetMat(self.playermodel)

                self.__isinit = true

                if mat and mat.normal and mat.normal.default and mat.normal.default[1] and mat.normal.default[1].mat and !mat.normal.default[1].mat:IsError() then
                    if mat.normal.default[1].type == 'png' then
                        -- Only .png images can be used with this function.

                        self.Icon:SetSpawnIcon(mat.normal.default[1].mat:GetName()..'.'..mat.normal.default[1].type)
                    end
                end
            end

            self:__oldPaint(w,h)
        end
    end

    local p = vgui.GetControlTable('DModelPanel')

    if p then
        p.__oldPaint = p.__oldPaint or p.Paint

        function p:Paint(w,h)
            if IsValid(self.Entity) then
                local old = self.Entity.RenderOverride or function(self) self:DrawModel() end
                self.Entity.__oldRenderOverride = self.Entity.__oldRenderOverride or old

                local p = LocalPlayer()
                local c = GetConVar('cl_playermodel')
                local bool = c and QTG2DPLY.List[c:GetString()] and self.Entity:GetModel() == 'models/player/alyx.mdl'

                if !IsValid(self.Image) then
                    self.Image = self:Add('DImage')
                    self.Image:SetPos(0,0)
                    self.Image:SetSize(w,h)
                    self.Image:SetMouseInputEnabled(false)
                    self.Image:SetKeyboardInputEnabled(false)
                end

                if bool then
                    local mat = QTG2DPLY.GetMat(self.playermodel)

                    if mat and mat.normal and mat.normal.default and mat.normal.default[1] and mat.normal.default[1].mat and !mat.normal.default[1].mat:IsError() then
                        self.Image:SetImageColor(Color(255,255,255,255))
                        self.Image:SetMaterial(mat.normal.default[1].mat)
                    end
                else
                    self.Image:SetImageColor(Color(255,255,255,0))
                end

                self.Entity.RenderOverride = function(self)
                    if bool then
                        return
                    end
        
                    return self:__oldRenderOverride()
                end
            end

            self:__oldPaint(w,h)
        end
    end

    local p = {}

    function p:Init()
        self.btnMinim:SetVisible(false)
        self.btnMaxim:SetVisible(false)
        
        self.btnClose:SetTextColor(Color(255,255,255))
        self.btnClose:SetFont('marlett')
        self.btnClose:SetText('r')
        self.btnClose.Paint = function(me,w,h)
            surface.SetDrawColor(255,0,0,200)
            surface.DrawRect(0,5,w,h/1.6)
        end

        self.lblTitle:SetTextColor(Color(255,255,255,255))
    end

    function p:Paint(w,h)
        surface.SetDrawColor(0,0,0,180)
        surface.DrawRect(0,0,w,h)
        surface.DrawRect(0,0,w,25)
    end

    vgui.Register('qtg_2dplyframe',p,'DFrame')

    local function createvgui(p)
        local newp = false
        local lp = LocalPlayer()

        if !IsValid(p) then
            local p2 = vgui.Create('qtg_2dplyframe')

            if IsValid(p2) then
                p2:SetTitle('2D Player Model selector menu')

                local w,h = math.min(ScrW()-16,960),math.min(ScrH()-16,700)

                p2:SetSize(w,h)
                p2:Center()
                p2:MakePopup()
                -- p2:SetKeyboardInputEnabled(false)

                p = p2
                newp = true
            end
        end

        local i = p:Add('DImage')
        i:Dock(FILL)
        i:SetMouseInputEnabled(false)
        i:SetKeyboardInputEnabled(false)

        local s = p:Add('DPropertySheet')
		s:Dock(RIGHT)
        s:SetSize(430,0)
        
        local mp = p:Add('DPanel')
        mp:DockPadding(8,8,8,8)

        local sb = mp:Add('DTextEntry')
		sb:Dock(TOP)
		sb:DockMargin(0,0,0,8)
		sb:SetUpdateOnType(true)
        sb:SetPlaceholderText('#spawnmenu.quick_filter')
        sb.__base = p
        
        local ps = mp:Add('DPanelSelect')
        ps:Dock(FILL)

        for n,t in SortedPairs(QTG2DPLY.List) do
            if next(t.mats) == nil then
                QTG2DPLY.FindMat(n)
            end

            local i = vgui.Create('DImageButton')

            local mat = t.mats

            if mat and mat.normal and mat.normal.default and mat.normal.default[1] and mat.normal.default[1].mat and !mat.normal.default[1].mat:IsError() then
                i:SetColor(Color(255,255,255,255))
                i:SetMaterial(mat.normal.default[1].mat)
            else
                i:SetColor(Color(255,255,255,0))
            end

            i:SetSize(64,64)
			i:SetTooltip(n)
            i.name = n

            local oldPaint = i.Paint or function() end

            function i:Paint(w,h)
                self.OverlayFade = math.Clamp((self.OverlayFade or 0 )-RealFrameTime()*640*2,0,255)
            
                if dragndrop.IsDragging() or !self:IsHovered() then return end
            
                self.OverlayFade = math.Clamp(self.OverlayFade+RealFrameTime()*640*8,0,255)

                oldPaint(self,w,h)
            end

            local border = 4
            local border_w = 5
            local matHover = Material('gui/sm_hover.png','nocull')
            local boxHover = GWEN.CreateTextureBorder(border,border,64-border*2,64-border*2,border_w,border_w,border_w,border_w,matHover)
            local oldPaintOver = i.PaintOver or function() end

            function i:PaintOver(w,h)
                if self.OverlayFade > 0 then
                    boxHover(0,0,w,h,Color(255,255,255,self.OverlayFade))
                end

                oldPaintOver(self,w,h)
            end

            ps:AddPanel(i,{cl_playermodel = n})
        end
        
        sb.OnValueChange = function(s,str)
			for id,pl in pairs(ps:GetItems()) do
				if !pl.name:find(str,1,true) then
					pl:SetVisible(false)
				else
					pl:SetVisible(true)
				end
            end
            
			ps:InvalidateLayout()
		end
        
        s:AddSheet('#smwidget.model',mp,'icon16/user.png')

        local url = 'https://steamcommunity.com/workshop/browse/?appid=4000&searchtext=2DPM&childpublishedfileid=0&browsesort=textsearch&section=items'
        local wp = p:Add('DPanel')
        wp:DockPadding(8,8,8,8)

        local wc = wp:Add('DHTMLControls')
        wc:Dock(TOP)
        wc:DockMargin(0,0,0,8)
        wc.__base = p

        local w = wp:Add('DHTML')
        w:Dock(FILL)

        function w:LoadedURL(u)
            if !u or u == '' then return end

            local id = tonumber(u:match('://steamcommunity.com/sharedfiles/filedetails/.*[%?%&]id=(%d+)') or u:match('://steamcommunity.com/workshop/filedetails/.*[%?%&]id=(%d+)'))

            self.id = isnumber(id) and id or nil
        end

        function w:SelectorModel()
            if !self.id then return end

            notification.AddProgress('qtg_2dplydownload_'..self.id,'Downloading 2D Player Model ('..(self.id)..') ...')

            steamworks.DownloadUGC(self.id,function(n,f)
                notification.Kill('qtg_2dplydownload_'..self.id)

                if f then
                    notification.AddLegacy('2D Player Model ('..(self.id)..') download completed',NOTIFY_GENERIC,3)
                    surface.PlaySound('buttons/button15.wav')
                else
                    notification.AddLegacy('2D Player Model ('..(self.id)..') download failed, please try again',NOTIFY_ERROR,3)
                    surface.PlaySound('buttons/button10.wav')

                    return
                end

                local b,t = game.MountGMA(n)

                if b then
                    local modelname = ''

                    for k,v in pairs(t) do
                        if string.StartWith(v,'materials/2dplayers/') then
                            local text = string.Split(v,'/')

                            if text[3] then
                                modelname = text[3]

                                break
                            end
                        end
                    end

                    if modelname == '' then
                        notification.AddLegacy('This mod is not a 2D Player Model ('..(self.id)..')',NOTIFY_ERROR,3)
                        surface.PlaySound('buttons/button10.wav')

                        return
                    end

                    modelname = string.lower(string.gsub(modelname,'_',' '))
                    modelname = string.upper(string.sub(modelname,1,1))..string.sub(modelname,2)

                    if QTG2DPLY.Is2DPly(modelname) then
                        notification.AddLegacy('2D Player Model already exists ('..(self.id)..')',NOTIFY_ERROR,3)
                        surface.PlaySound('buttons/button10.wav')

                        return
                    end

                    QTG2DPLY.Add2DPly(modelname,true)

                    net.Start('qtg_2dply_workshopds')
                    net.WriteUInt(self.id,32)
                    net.SendToServer()

                    if IsValid(p) then
                        p:Remove()
                    end
                else
                    notification.AddLegacy('2D Player Model installation failed ('..(self.id)..')',NOTIFY_ERROR,3)
                    surface.PlaySound('buttons/button10.wav')
                end
            end)
        end

        w:AddFunction('gmod','qtg_tpsubscribe',function()
            w:SelectorModel()
        end)

        function w:OnDocumentReady(u)
            self.url = u

            self:LoadedURL(u)
            self:InjectScripts()
        end

        function w:InjectScripts()
            self:QueueJavascript(string.format([[
                function SubscribeItem(){
                    gmod.qtg_tpsubscribe()
                }
                
                setTimeout(function(){
                    function SubscribeItem(){
                        gmod.qtg_tpsubscribe()
                    }
                
                    var sub = document.getElementById("SubscribeItemOptionAdd")

                    if (sub){
                        sub.innerText = "%s"
                    }
                },0)
            ]],'Select'))
        end

        wc:SetHTML(w)
        wc.AddressBar:SetText(url)

        w:MoveBelow(wc)
        w:OpenURL(url)

        s:AddSheet('Workshop Model',wp,'icon16/user.png')

        -- local ip = p:Add('DPanel')
        -- ip:DockPadding(8,8,8,8)

        -- s:AddSheet('Internet Model (Undone)',ip,'icon16/user.png')

        local sp = p:Add('DPanel')
        sp:DockPadding(8,8,8,8)

        local ob = sp:Add('DButton')
        ob:SetText('Client reload all 2D Player Model')
        ob:Dock(TOP)
        ob:DockMargin(0,0,0,8)
        ob:SetHeight(30)

        function ob:DoClick()
            RunConsoleCommand('qtg_2dply_reload_client')
        end

        local ob = sp:Add('DCheckBoxLabel')
        ob:SetText('Hidden weapon?')
        ob:Dock(TOP)
        ob:SetConVar('qtg_2dply_hidewep')
        ob:DockMargin(0,0,0,8)
        ob:SetHeight(15)
        ob:SetTextColor(Color(0,0,0,255))
        
        local ob = sp:Add('DNumSlider')
        ob:SetText('Light Intensity')
        ob:SetDark( true )
        ob:Dock(TOP)
        ob:DockMargin(0,0,0,8)
        ob:SetHeight(15)
		ob:SetMin( 0 )				 	-- Set the minimum number you can slide to
		ob:SetMax( 10 )				-- Set the maximum number you can slide to
		ob:SetDecimals( 1 )				-- Decimal places - zero for whole number
		ob:SetConVar( "qtg_2dply_brightness" )	-- Changes the ConVar when you slide
        	
        if lp:IsAdmin() then
        
        	local ob = sp:Add('DLabel')
        	ob:SetText( "------ADMIN STUFF------" )
        	ob:SetDark( true )
            ob:Dock(TOP)
            ob:DockMargin(150,0,0,8)
        	ob:SetHeight(15)
			
            local ob = sp:Add('DButton')
            ob:SetText('Admin reload all 2D Player Model')
            ob:Dock(TOP)
            ob:DockMargin(0,0,0,8)
            ob:SetHeight(30)

            function ob:DoClick()
                RunConsoleCommand('qtg_2dply_reload')
            end
            
            local ob = sp:Add('DLabel')
        	ob:SetText( "-----------------------------" )
        	ob:SetDark( true )
            ob:Dock(TOP)
            ob:DockMargin(150,0,0,8)
        	ob:SetHeight(15)
        	end
			
        s:AddSheet('Settings',sp,'icon16/cog.png')
        
        local function update()
            local lp = LocalPlayer()
            local c = GetConVar('cl_playermodel')
            local bool = c and QTG2DPLY.List[c:GetString()] and lp:GetModel() == 'models/player/alyx.mdl'

            if QTG2DPLY.List[c:GetString()] and lp:GetModel() == 'models/player/kleiner.mdl' then
                lp:SetModel('models/player/alyx.mdl')
            end

            if bool then
                local mat = QTG2DPLY.GetMat(c:GetString())

                if mat and mat.normal and mat.normal.default and mat.normal.default[1] and mat.normal.default[1].mat and !mat.normal.default[1].mat:IsError() then
                    i:SetImageColor(Color(255,255,255,255))
                    i:SetMaterial(mat.normal.default[1].mat)
                else
                    i:SetImageColor(Color(255,255,255,0))
                end
            else
                i:SetImageColor(Color(255,255,255,0))
            end
        end

        update()

        function ps:OnActivePanelChanged(o,n)
            timer.Simple(0,function()
                update()
            end)
        end
    end

    list.Set('DesktopWindows','qtg_2dplymenu',{
        title = '2D Player Model',
        icon = 'icon64/playermodel.png',
        width = 960,
        height = 700,
        onewindow = true,
        init = function(i,w)
            function w:Init2()
                self.btnMinim:SetVisible(false)
                self.btnMaxim:SetVisible(false)
                
                self.btnClose:SetTextColor(Color(255,255,255))
                self.btnClose:SetFont('marlett')
                self.btnClose:SetText('r')
                self.btnClose.Paint = function(me,w,h)
                    surface.SetDrawColor(255,0,0,200)
                    surface.DrawRect(0,5,w,h/1.6)
                end

                self.lblTitle:SetTextColor(Color(255,255,255,255))
            end

            w:Init2()
        
            function w:Paint(w,h)
                surface.SetDrawColor(0,0,0,180)
                surface.DrawRect(0,0,w,h)
                surface.DrawRect(0,0,w,25)
            end

            w:SetTitle('2D Player Model selector menu')
            w:SetSize(math.min(ScrW()-16,w:GetWide()),math.min(ScrH()-16,w:GetTall()))
            w:SetSizable(true)
            w:SetMinWidth(w:GetWide())
            w:SetMinHeight(w:GetTall())
            w:Center()

            createvgui(w)
        end
    })

    concommand.Add('qtg_2dply_menu',function(p,s,a,as)
        createvgui()
    end)

    net.Receive('qtg_2dply_workshopds_client',function(_,p)
        local id = net.ReadUInt(32)

        notification.AddProgress('qtg_2dplydownload_'..id,'Downloading 2D Player Model ('..(id)..') ...')

        steamworks.DownloadUGC(id,function(n,f)
            notification.Kill('qtg_2dplydownload_'..id)

            if f then
                notification.AddLegacy('2D Player Model ('..(id)..') download completed',NOTIFY_GENERIC,3)
                surface.PlaySound('buttons/button15.wav')
            else
                notification.AddLegacy('2D Player Model ('..(id)..') download failed',NOTIFY_ERROR,3)
                surface.PlaySound('buttons/button10.wav')

                return
            end

            local b,t = game.MountGMA(n)

            if b then
                local modelname = ''

                for k,v in pairs(t) do
                    if string.StartWith(v,'materials/2dplayers/') then
                        local text = string.Split(v,'/')

                        if text[3] then
                            modelname = text[3]

                            break
                        end
                    end
                end

                if modelname == '' then
                    return
                end

                modelname = string.lower(string.gsub(modelname,'_',' '))
                modelname = string.upper(string.sub(modelname,1,1))..string.sub(modelname,2)

                if QTG2DPLY.Is2DPly(modelname) then
                    return
                end

                QTG2DPLY.Add2DPly(modelname,true)
            end
        end)
    end)
else
    resource.AddWorkshop(2049178348)

    util.AddNetworkString('qtg_2dply_reload')
    util.AddNetworkString('qtg_2dply_npcdeath')
    util.AddNetworkString('qtg_2dply_serveris2d')
    util.AddNetworkString('qtg_2dply_workshopds')
    util.AddNetworkString('qtg_2dply_workshopds_client')

    net.Receive('qtg_2dply_serveris2d',function(_,p)
        local pm = net.ReadString()

        p:SetNWBool('qtg_2dply_is2dply',QTG2DPLY.Is2DPly(p) and pm == p:GetModel())
    end)

    local workshopneedtod = {}

    net.Receive('qtg_2dply_workshopds',function(_,p)
        local id = net.ReadUInt(32)

        workshopneedtod[id] = true

        for k,v in pairs(player.GetAll()) do
            if v != p then
                net.Start('qtg_2dply_workshopds_client')
                net.WriteUInt(id,32)
                net.Send(v)
            end
        end
    end)

    addhook('PlayerInitialSpawn',function(p,t)
        hook.Add('SetupMove',p,function(self,p,mv,cmd)
            if self == p and not cmd:IsForced() then
                hook.Run('PlayerFullLoad',self,t,mv,cmd)
                hook.Remove('SetupMove',self)
            end
        end)
    end)

    addhook('PlayerFullLoad',function(p,t,mv,cmd)
        for id,v in pairs(workshopneedtod) do
            net.Start('qtg_2dply_workshopds_client')
            net.WriteUInt(id,32)
            net.Send(p)
        end
    end)

    addhook('PlayerSpawnedNPC',function(p,e)
        if !IsValid(e) then return end

        local t = e:GetKeyValues()

        if t.target and string.find(t.target,'qtg_2dply_is2dnpc') then
            t.target = string.Split(t.target,'|')

            e:SetKeyValue('target','')
            e:SetNWBool('qtg_2dply_is2dnpc',true)

            if t.target[2] then
                e:SetNWString('qtg_2dply_npctype',t.target[2])
            end
        end
    end)

    addhook('Think',function()
        for k,v in pairs(player.GetAll()) do
            if v:GetNWString('qtg_2dply_cl_playermodel') != v:GetInfo('cl_playermodel') then
                v:SetNWString('qtg_2dply_cl_playermodel',v:GetInfo('cl_playermodel'))
            end
        end
    end)
end