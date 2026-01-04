return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	opts = {
		filesystem = {
			filtered_items = {
				visible = true,
				hide_dotfiles = false,
			},
		},
	},
	lazy = false,
	---@module "neo-tree"
	---@type neotree.Config?
	config = function()
		require("neo-tree").setup({
			filesystem = {
				filtered_items = {
					hide_dotfiles = false,
					visible = true,
				},
			},
		})
		vim.keymap.set("n", "<leader>n", ":Neotree filesystem toggle reveal left<CR>")
	end,
}
