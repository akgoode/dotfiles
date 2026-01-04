return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	lazy = false,
	build = ":TSUpdate",
	opts = {
		ensure_installed = {
			"go",
			"lua",
			"typescript",
			"javascript",
			"python",
			"bash",
			"c",
			"markdown_inline",
			"json",
			"yaml",
			"terraform",
			"rego",
			"html",
			"htmldjango",
			"dockerfile",
			"bash",
			"tsx",
			"c_sharp",
		},
		highlight = { enable = true },
		indent = { enable = true },
	},
	config = function(_, opts)
		require("nvim-treesitter.configs").setup(opts)
	end,
}
