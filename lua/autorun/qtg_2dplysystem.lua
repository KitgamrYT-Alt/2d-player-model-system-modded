AddCSLuaFile()

-- Core file
-- You don't need to write any lua, you just need to create a folder to add 2Dplayer
-- You can customize according to the template

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

local function sortf(a,b)
    a = string.gsub(a,'.png','')
    a = string.gsub(a,'.vtf','')
    
    if tonumber(a) then
        a = tonumber(a)
    end

    b = string.gsub(b,'.png','')
    b = string.gsub(b,'.vtf','')

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
end)

concommand.Add('qtg_2dply_reload',function(p,c,a,as)
    if SERVER then
        QTG2DPLY.Init()

        net.Start('qtg_2dply_reload')
        net.Broadcast()
    elseif p:IsAdmin() then
        QTG2DPLY.Init()

        net.Start('qtg_2dply_reload')
        net.SendToServer()
    end
end)

if CLIENT then
    function QTG2DPLY.FindMat(n)
        local t = QTG2DPLY.List[n].mats
        local pa =  QTG2DPLY.GetPath(n)
        local f,d = file.Find('materials/'..pa..'/*','GAME')

        t['normal'] = {}

        for k,v in pairs(d) do
            local f2,d2 = file.Find('materials/'..pa..'/'..v..'/*','GAME')

            t['normal'][v] = {}

            table.sort(f2,sortf)

            for k2,v2 in ipairs(f2) do
                t['normal'][v][#t['normal'][v]+1] = Material(pa..'/'..v..'/'..v2)
            end

            for k3,v3 in pairs(d2) do
                if !t[v3] then
                    t[v3] = {}
                end

                t[v3][v] = {}

                local f3,d3 = file.Find('materials/'..pa..'/'..v..'/'..v3..'/*','GAME')

                table.sort(f3,sortf)

                for k4,v4 in ipairs(f3) do
                    t[v3][v][#t[v3][v]+1] = Material(pa..'/'..v..'/'..v3..'/'..v4)
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

                if IsValid(w) then
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

            local function draw2d()
                local lcolor = render.ComputeLighting(pos,Vector(0,0,1))
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

                surface.SetMaterial(tbl[st][p.__qtg2di])
                surface.DrawTexturedRect(-250,-250,500,500)

                if st2 != '' then
                    if tbl[st2] and tbl[st2][p.__qtg2di] then
                        surface.SetMaterial(tbl[st2][p.__qtg2di])
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
                draw2d()
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

                    self:DrawModel()

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

                    self:DrawModel()

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
    
                    self:DrawModel()
    
                    return self:__oldRenderOverride()
                end
            end
        end
    end)

    timer.Simple(0,function()
        local p = vgui.GetControlTable('SpawnIcon')

        if p then
            p.__oldPaint = p.__oldPaint or p.Paint

            function p:Paint(w,h)
                if self.playermodel and QTG2DPLY.Is2DPly(self.playermodel) and !self.__isinit then
                    local mat = QTG2DPLY.GetMat(self.playermodel)

                    self.__isinit = true

                    if mat and mat.normal and mat.normal.default and mat.normal.default[1] and !mat.normal.default[1]:IsError() then
                        self.Icon:SetSpawnIcon(mat.normal.default[1]:GetName()..'.png')
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

                        if mat and mat.normal and mat.normal.default and mat.normal.default[1] and !mat.normal.default[1]:IsError() then
                            self.Image:SetImageColor(Color(255,255,255,255))
                            self.Image:SetMaterial(mat.normal.default[1])
                        end
                    else
                        self.Image:SetImageColor(Color(255,255,255,0))
                    end

                    self.Entity.RenderOverride = function(self)
                        if bool then
                            return
                        else
                            self:DrawModel()
                        end
            
                        return self:__oldRenderOverride()
                    end
                end

                self:__oldPaint(w,h)
            end
        end
    end)
else
    resource.AddWorkshop(2049178348)

    util.AddNetworkString('qtg_2dply_reload')
    util.AddNetworkString('qtg_2dply_npcdeath')
    util.AddNetworkString('qtg_2dply_serveris2d')

    net.Receive('qtg_2dply_serveris2d',function(_,p)
        local pm = net.ReadString()

        p:SetNWBool('qtg_2dply_is2dply',QTG2DPLY.Is2DPly(p) and pm == p:GetModel())
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