return {
	setup = function()
		return {
			temp_ascii = function()
				vim.g.imselect_test_input = false
			end,
			restore = function()
				vim.g.imselect_test_input = true
			end,
		}
	end,
}
