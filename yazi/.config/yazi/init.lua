-- Automatically update zoxide DB from yazi navigation
require("zoxide"):setup({
    update_db = true
})

require("full-border"):setup {
    type = ui.Border.ROUNDED, -- or ui.Border.PLAIN
}
