-- Tuning values for combat. Server and client both read this module.
local Config = {}

Config.Player = {
	MaxHealth = 300,
	MaxStamina = 100,
	StaminaRegenPerSecond = 40,
	StaminaRegenDelay = 0.8, -- seconds after spending stamina before it refills
	WalkSpeed = 14,
	MaxPoise = 50,
	MaxMana = 120,
	ManaRegenPerSecond = 8,
	ManaRegenDelay = 1.5,
}

Config.Weapon = {
	Length = 7,
	GripOffset = CFrame.new(0, -0.25, 0),
	RestAngle = -30, -- blade pitch in degrees; negative points the tip down
}

-- Spells are learned from scrolls, picked on the spell wheel, and cast with the cast key.
Config.Spells = {
	Zoltraak = {
		DisplayName = "Zoltraak",
		Description = "Ordinary offensive magic. A fast bolt that strikes the first foe in its path.",
		Icon = "Z",
		Color = Color3.fromRGB(190, 160, 255),
		Mana = 15,
		Cooldown = 0.8,
		CastTime = 0.25,
		Recovery = 0.25,
		MoveSpeed = 8,
		Damage = 40,
		PoiseDamage = 15,
		Range = 150,
	},
	Judradjim = {
		DisplayName = "Judradjim",
		Description = "Calls a bolt of lightning down on the target area after a short delay.",
		Icon = "J",
		Color = Color3.fromRGB(255, 220, 110),
		Mana = 35,
		Cooldown = 5,
		CastTime = 0.5,
		Recovery = 0.4,
		MoveSpeed = 4,
		Damage = 70,
		PoiseDamage = 50,
		Range = 90,
		Radius = 10,
		Delay = 0.6,
	},
	Catastravia = {
		DisplayName = "Catastravia",
		Description = "A rain of light arrows that falls across a wide area.",
		Icon = "C",
		Color = Color3.fromRGB(150, 230, 255),
		Mana = 50,
		Cooldown = 10,
		CastTime = 0.7,
		Recovery = 0.5,
		MoveSpeed = 2,
		Damage = 16,
		PoiseDamage = 12,
		Range = 90,
		Radius = 14,
		Arrows = 12,
		ArrowRadius = 4,
		Duration = 1.2,
	},
	Barrier = {
		DisplayName = "Defensive Magic",
		Description = "A barrier of mana that blocks all damage for a moment.",
		Icon = "B",
		Color = Color3.fromRGB(110, 170, 255),
		Mana = 25,
		Cooldown = 6,
		CastTime = 0.1,
		Recovery = 0.2,
		MoveSpeed = 10,
		Duration = 1.5,
	},
}

-- Order spells appear in on the wheel and for the number-key quick slots.
Config.SpellOrder = { "Zoltraak", "Judradjim", "Catastravia", "Barrier" }

-- Greatsword attacks. Timings are in seconds: Windup -> Active (hitbox live) -> Recovery.
Config.Attacks = {
	Light = {
		Stamina = 18,
		Windup = 0.3,
		Active = 0.15,
		Recovery = 0.35,
		Damage = 32,
		PoiseDamage = 22,
		Range = 9,
		Width = 8,
		MoveSpeed = 5,
		ComboWindow = 0.5, -- time after an attack ends to chain the next one
		ComboMultipliers = { 1, 1.1, 1.4 },
	},
	Heavy = {
		Stamina = 35,
		Windup = 0.75,
		Active = 0.2,
		Recovery = 0.6,
		Damage = 75,
		PoiseDamage = 60,
		Range = 10,
		Width = 10,
		MoveSpeed = 2,
	},
}

Config.Dodge = {
	Stamina = 22,
	Speed = 50,
	Duration = 0.3,
	InvulnerableTime = 0.28,
	Recovery = 0.15,
}

Config.Poise = {
	RegenDelay = 3, -- poise resets to full after this long without being hit
	StaggerDuration = 1.2,
}

Config.LockOn = {
	Range = 60,
	BreakRange = 80,
	CameraDistance = 12,
	CameraHeight = 4,
}

Config.Combat = {
	PvP = false,
	InputBuffer = 0.4, -- inputs pressed this long before you can act still go through
}

Config.Dummy = {
	Health = 500,
	MaxPoise = 80,
	RespawnTime = 5,
	Count = 3,
}

Config.Debug = {
	ShowHitboxes = true,
}

Config.Keybinds = {
	Light = { Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR1 },
	Heavy = { Enum.KeyCode.F, Enum.KeyCode.ButtonR2 },
	Dodge = { Enum.KeyCode.Q, Enum.KeyCode.ButtonB },
	LockOn = { Enum.KeyCode.Tab, Enum.UserInputType.MouseButton3, Enum.KeyCode.ButtonR3 },
	Cast = { Enum.KeyCode.E, Enum.KeyCode.ButtonL1 },
	SpellWheel = { Enum.KeyCode.G, Enum.KeyCode.ButtonL2 }, -- hold to open, release to equip
}

Config.QuickSlotKeys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }

return Config
