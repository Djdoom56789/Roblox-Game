-- Tuning values for combat. Server and client both read this module.
local Config = {}

Config.Player = {
	MaxHealth = 300,
	MaxStamina = 100,
	StaminaRegenPerSecond = 40,
	StaminaRegenDelay = 0.8, -- seconds after spending stamina before it refills
	WalkSpeed = 14,
	MaxPoise = 50,
}

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
}

return Config
