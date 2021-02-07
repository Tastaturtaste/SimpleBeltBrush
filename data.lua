local Data = require('__stdlib__/stdlib/data/data')

data:extend({
	{
		type = "custom-input",
		name = "brush-inc",
		key_sequence = "",--"PAD +",
		linked_game_control = "larger-terrain-building-area"
	},
	{
		type = "custom-input",
		name = "brush-dec",
		key_sequence = "",--"PAD -",
		linked_game_control = "smaller-terrain-building-area"
	}
})
