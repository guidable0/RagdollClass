--[[ Variables ]]--

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local ContextActionService = game:GetService("ContextActionService");

-- References
local client = Players.LocalPlayer;
local ragdollRemote = ReplicatedStorage:WaitForChild("RagdollRemote");
local currentCamera = workspace.CurrentCamera;

-- require RagdollClass
local RagdollClass = require(ReplicatedStorage:WaitForChild("RagdollClass"));

-- Configurations
local ragdollKeybind = Enum.KeyCode.R;

-- Other variables
local clientRagdoll;
local head;
local humanoid;
local ragdollEnabled = false;

--[[ Functions ]]--

-- The callback that is gonna be used by ContextActionService, when the user presses the ragdoll keybind.
local function handleAction(_, userInputState)
	-- Check if the userInputState is in the begin state, as we only want the ragdoll toggling when the user initially presses the ragdoll keybind.
	if userInputState == Enum.UserInputState.Begin then
		-- Make the ragdollEnabled variable toggle.
		ragdollEnabled = not ragdollEnabled;

		-- I recommend setting the camera subject to the head when the ragdoll is enabled.
		if head and ragdollEnabled then
			currentCamera.CameraSubject = head;
		elseif humanoid and not ragdollEnabled then
			currentCamera.CameraSubject = humanoid;
		end
		-- We can assume that the RagdollClass object exists, as the action can only be binded when the character spawns in, which is when the ragdoll gets created.
		clientRagdoll:SetRagdollEnabled(ragdollEnabled);
		-- Tell the server, "Hey, the ragdoll is in this state!", so that they can create or remove the ragdoll on their side, to show that this user is in this state.
		-- We also replicate the ragdoll seed, in order to make the random velocity result the same.
		ragdollRemote:FireServer(ragdollEnabled, RagdollClass.Seed);
	end;
end;

-- We need this function to setup the ragdoll when the character spawns, and to remove the ragdoll when they die, to not cause any memory leaks.
-- It's also used to bind the actions.
local function onCharacterAdded(character)
	-- Wait for the humanoid, it's not always available when the character gets added.
	humanoid = character:WaitForChild("Humanoid");
	head = character:FindFirstChild("Head");
	-- Create a new ragdoll class, and set the ragdoll variable to it.
	-- We need to set the ragdoll variable outside of this scope, so that the handleAction function can access it.
	clientRagdoll = RagdollClass.new(character);
	-- Bind the ragdoll action, so that we can detect when the user presses the ragdoll keybind, and then enable/disable the ragdoll.
	ContextActionService:BindAction("Ragdoll", handleAction, true, ragdollKeybind);
	-- Connect to humanoid.Died
	local c;
	c = humanoid.Died:Connect(function()
		-- Disconnect the connection, as Humanoid.Died can fire multiple times.
		c:Disconnect();
		c = nil;
		-- Unbind the ragdoll action, to not get any unintended errors outputted when the user tries to ragdoll when they are not alive.
		ContextActionService:UnbindAction("Ragdoll");

		-- Destroy the ragdoll class to not cause a memory leak
		clientRagdoll:Destroy();

		-- Set variables to nil, so there are no references to stuff that is no longer in use.
		clientRagdoll = nil;
		head = nil;
		humanoid = nil;

		-- Set ragdollEnabled to false, so that the next time the user presses the ragdoll keybind (when the character spawns in again)
		-- handleAction doesn't think that the ragdoll is enabled and then tries to disable it.
		ragdollEnabled = false;
	end);
end;

--[[ Connections ]]--

client.CharacterAdded:Connect(onCharacterAdded);