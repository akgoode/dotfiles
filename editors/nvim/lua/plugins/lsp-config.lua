local all = {
	"lua_ls",
	"ts_ls",
	"terraformls",
	"basedpyright",
	"black",
	"delve",
	"nvim-dap-python",
	"opa",
	"gofumpt",
	"goimports_reviser",
	"golines",
	"gopls",
	"csharpier",
	"djlint",
	"golangci-lint",
	"regal",
	"rego",
	"terraform",
}
local lsps = { "lua_ls", "ts_ls", "basedpyright", "gopls", "regal" }
return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		opts = {
			ensure_installed = all,
		},
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		opts = {
			automatic_enable = lsps,
			ensure_installed = lsps,
		},
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local tfcapabilities = vim.lsp.protocol.make_client_capabilities()
			tfcapabilities.textDocument.completion.completionItem.snippetSupport = true
			local util = require("lspconfig/util")
			local lspconfig = require("lspconfig")
			lspconfig.lua_ls.setup({
				capabilities = capabilities,
			})
			lspconfig.ts_ls.setup({
				capabilities = capabilities,
			})
			lspconfig.terraformls.setup({
				capabilities = tfcapabilities,
			})
			lspconfig.basedpyright.setup({
				capabilities = capabilities,
			})
			lspconfig.gopls.setup({
				capabilities = capabilities,
				cmd = { "gopls" },
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
				root_dir = util.root_pattern("go.work", "go.mod", ".git"),
				settings = {
					gopls = {
						completeUnimported = true,
						usePlaceholders = true,
						analyses = {
							unusedparams = true,
						},
					},
				},
			})
			lspconfig.regal.setup({
				capabilities = capabilities,
			})
			lspconfig.yamlls.setup({
				capabilities = capabilities,
				settings = {
					yaml = {
						schemaStore = {
							enable = false,
							url = "",
						},
						schemas = require("schemastore").yaml.schemas({
							replace = {
								["Azure Pipelines"] = {
									description = "Azure Pipelines overridden",
									fileMatch = {
										"/azure-pipeline*.y*l",
										"/azure_pipeline*/*.y*l",
										"/templates/**/*.y*l",
									},
									name = "Azure Pipelines",
									url = "https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json",
								},
							},
						}),
						validate = { enable = true },
						completion = { enable = true },
						editor = {
							tabSize = 2,
						},
					},
				},
			})
			vim.keymap.set("n", "<Leader>H", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "<Leader>h", vim.diagnostic.open_float, {})
			vim.keymap.set("n", "<Leader>gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "<Leader>gr", vim.lsp.buf.references, {})
			vim.keymap.set("n", "<Leader>.", vim.lsp.buf.code_action, {})
		end,
	},
}
