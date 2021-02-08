local Data = require('__stdlib__/stdlib/data/data')

data:extend({
	{
		type = "custom-input",
		name = "brush-inc-lanes",
		key_sequence = "",--"PAD +",
		linked_game_control = "larger-terrain-building-area"
	},
	{
		type = "custom-input",
		name = "brush-dec-lanes",
		key_sequence = "",--"PAD -",
		linked_game_control = "smaller-terrain-building-area"
	},
	{
		type = "custom-input",
		name = "brush-inc-depth",
		key_sequence = "SHIFT + KP_PLUS"
	},
	{
		type = "custom-input",
		name = "brush-dec-depth",
		key_sequence = "SHIFT + KP_MINUS"
	}
})
