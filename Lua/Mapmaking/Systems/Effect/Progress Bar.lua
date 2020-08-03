do
    --  Credits to JesusHipster for the sick hp-bar model
    local tb    = protected_table({
        MODEL   = "war3mapImported\\HPbar.mdx"
    })
    ProgressBar = setmetatable({}, tb)
end