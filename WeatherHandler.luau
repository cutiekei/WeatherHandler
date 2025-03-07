local Lighting = game:GetService("Lighting")
local Atmosphere = Lighting:WaitForChild("Atmosphere")

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local weatherParticles = game.Workspace:WaitForChild("WeatherParticles")

-- Weather settings
local transitionTime = 3       -- Transition time between weathers
local timeBetweenChanges = 5   -- Time between weather changes
local soundFadeTime = 2        -- Time for sounds to fade in/out
local particleFadeTime = 2     -- Time for particles to fade in/out

-- Initializing
local timeSinceLastChange = 0
local currentWeatherData = nil

-- Define weather types
local weatherTypes = {
	{
		name = "Sunny",
		ambientColor = Color3.fromRGB(255, 255, 255),
		outdoorAmbientColor = Color3.fromRGB(180, 180, 180),
		brightness = 3,
		skyDensity = 0.1,
		timeOfDay = 14,
		sounds = {SoundService.SunnySound},
	},
	{
		name = "Rainy",
		ambientColor = Color3.fromRGB(0, 0, 255),
		outdoorAmbientColor = Color3.fromRGB(0, 0, 255),
		brightness = 1,
		skyDensity = 0.6,
		timeOfDay = 14,
		particles = {weatherParticles.Rain["Floor effect"].ParticleEmitter, weatherParticles.Rain.Rain.ParticleEmitter},
		sounds = {SoundService.RainSound},
		maxVolume = 0.7,
		maxParticleRate = 100,
	},
	{
		name = "Snowy",
		ambientColor = Color3.fromRGB(170, 255, 255),
		outdoorAmbientColor = Color3.fromRGB(170, 255, 255),
		brightness = 1,
		skyDensity = 0.5,
		timeOfDay = 14,
		particles = {weatherParticles.Snow.ParticleEmitter},
		sounds = {SoundService.SnowySound},
		maxVolume = 0.7,
		maxParticleRate = 175,
	},
	{
		name = "Cloudy",
		ambientColor = Color3.fromRGB(170, 255, 255),
		outdoorAmbientColor = Color3.fromRGB(170, 255, 255),
		brightness = 2,
		skyDensity = 0.2,
		timeOfDay = 14,
	}
}

-- Main weather function
local function changeWeather(newWeather)
	if newWeather == currentWeatherData then
		return
	end

	-- Fades out old vfx
	if currentWeatherData and currentWeatherData.sounds then
		for _, sound in ipairs(currentWeatherData.sounds) do
			local fadeOut = TweenService:Create(sound, TweenInfo.new(soundFadeTime), {Volume = 0})
			fadeOut:Play()

			fadeOut.Completed:Connect(function()
			end)
		end
	end

	if currentWeatherData and currentWeatherData.particles then
		for _, particleEmitter in ipairs(currentWeatherData.particles) do
			local fadeOut = TweenService:Create(particleEmitter, TweenInfo.new(particleFadeTime), {Rate = 0})
			fadeOut:Play()

			fadeOut.Completed:Connect(function()
			end)
		end
	end

	-- Store the new weather data
	currentWeatherData = newWeather
	print("Changing weather to: " .. newWeather.name)

	-- Tweening lighting/atmosphere
	local tweenInfo = TweenInfo.new(transitionTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	local lightingTween = TweenService:Create(Lighting, tweenInfo, {
		Ambient = newWeather.ambientColor,
		OutdoorAmbient = newWeather.outdoorAmbientColor,
		Brightness = newWeather.brightness,
		ClockTime = newWeather.timeOfDay,
	})
	local atmosphereTween = TweenService:Create(Atmosphere, tweenInfo, {
		Density = newWeather.skyDensity,
	})
	lightingTween:Play()
	atmosphereTween:Play()

	-- Fades in new vfx
	if newWeather.particles then
		for _, particleEmitter in ipairs(newWeather.particles) do
			particleEmitter.Rate = 0
			particleEmitter.Enabled = true

			local fadeIn = TweenService:Create(particleEmitter, TweenInfo.new(particleFadeTime), {Rate = newWeather.maxParticleRate or 20})
			fadeIn:Play()
		end
	end

	if newWeather.sounds then
		for _, sound in ipairs(newWeather.sounds) do
			sound.Volume = 0
			sound:Play()

			local fadeIn = TweenService:Create(sound, TweenInfo.new(soundFadeTime), {Volume = newWeather.maxVolume or 0.5})
			fadeIn:Play()
		end
	end
end

-- Picks a random weather type
local function pickRandomWeather()
	local randomIndex = math.random(#weatherTypes)
	changeWeather(weatherTypes[randomIndex])
end

-- Start with sunny weather
changeWeather(weatherTypes[1])

-- Checks when to change weather
RunService.Heartbeat:Connect(function(deltaTime)
	timeSinceLastChange = timeSinceLastChange + deltaTime

	if timeSinceLastChange >= timeBetweenChanges then
		timeSinceLastChange = 0
		pickRandomWeather()
	end
end)
