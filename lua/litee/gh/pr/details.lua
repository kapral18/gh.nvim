local lib_tree_node = require('litee.lib.tree.node')
local config = require('litee.gh.config')

local M = {}

local symbols = {
    top = '╭',
    left = '│',
    bottom = '╰',
    tab = '  ',
}

local function parse_comment(body, left_sign, bottom_sign)
    local lines = {}
    body = vim.fn.split(body, '\n')
    for _, line in ipairs(body) do
        line = vim.fn.substitute(line, '\r', '', 'g')
        line = vim.fn.substitute(line, '\n', '', 'g')
        line = vim.fn.substitute(line, '\t', symbols.tab, 'g')
        if left_sign then
            line = symbols.left .. line
        end
        table.insert(lines, line)
    end
    return lines
end

function M.details_func(_, node)
    if node.pr ~= nil then
        local buffer_lines = {}
        table.insert(
            buffer_lines,
            string.format('%s %s  PR: #%s', symbols.top, config.icon_set['GitPullRequest'], node.pr['number'])
        )
        table.insert(
            buffer_lines,
            string.format('%s %s  Author: %s', symbols.left, config.icon_set['Account'], node.pr['user']['login'])
        )
        table.insert(
            buffer_lines,
            string.format('%s %s  Created: %s', symbols.left, config.icon_set['Calendar'], node.pr['created_at'])
        )
        table.insert(
            buffer_lines,
            string.format('%s %s  Last Updated: %s', symbols.left, config.icon_set['Calendar'], node.pr['updated_at'])
        )
        table.insert(
            buffer_lines,
            string.format('%s %s  Title: %s', symbols.left, config.icon_set['Pencil'], node.pr['title'])
        )
        table.insert(buffer_lines, symbols.left)
        local body = parse_comment(node.pr['body'], true, false)
        for _, l in ipairs(body) do
            table.insert(buffer_lines, l)
        end
        table.insert(buffer_lines, symbols.bottom)
        return buffer_lines
    end
    if node.commit ~= nil then
        local author = 'unknown'
        if node.commit['author'] ~= vim.NIL then
            author = node.commit['author']['login']
        elseif node.commit['commit'] ~= nil and node.commit['commit']['author'] ~= nil then
            if node.commit['commit']['author']['name'] ~= nil then
                author = node.commit['commit']['author']['name']
            elseif node.commit['commit']['author']['email'] ~= nil then
                author = node.commit['commit']['author']['email']
            end
        end
        local buffer_lines = {}
        table.insert(buffer_lines, symbols.top)
        local message = parse_comment(node.commit.commit['message'], true, true)
        for _, l in ipairs(message) do
            table.insert(buffer_lines, l)
        end
        table.insert(buffer_lines, symbols.bottom)
        return buffer_lines
    end
    if node.review ~= nil then
        local buffer_lines = {}
        table.insert(buffer_lines, symbols.top)
        local author = node.review['user']['login']
        local body = parse_comment(node.review['body'], true, true)
        for _, l in ipairs(body) do
            table.insert(buffer_lines, l)
        end
        table.insert(buffer_lines, symbols.bottom)
        return buffer_lines
    end
    if node.comment ~= nil then
        local buffer_lines = {}
        table.insert(buffer_lines, symbols.top)
        local author = node.comment['author']['login']
        local body = parse_comment(node.comment['body'], true, true)
        for _, l in ipairs(body) do
            table.insert(buffer_lines, l)
        end
        table.insert(buffer_lines, symbols.bottom)
        return buffer_lines
    end
end

-- build_details_tree builds a sub-tree of pr details.
--
-- @return node (table) the root node of the details sub-tree with children
-- attached.
function M.build_details_tree(pull, depth, prev_tree)
    local prev_root = nil
    if prev_tree ~= nil and prev_tree.depth_table[depth] ~= nil then
        for _, prev_node in ipairs(prev_tree.depth_table[depth]) do
            if prev_node.key == 'Details:' then
                prev_root = prev_node
            end
        end
    end

    local root = lib_tree_node.new_node(
        'Details:',
        'Details:',
        depth -- we a subtree of root
    )
    root.expanded = true
    if prev_root ~= nil then
        root.expanded = prev_root.expanded
    end
    root.details = {
        name = root.name,
        detail = '',
        icon = '',
    }

    local number = lib_tree_node.new_node(
        'number:',
        'number:',
        depth + 1 -- we are a child to the root details node created above, selfsame for all following.
    )
    number.details = {
        name = number.name,
        detail = string.format('%d', pull['number']),
        icon = config.icon_set['Number'],
    }
    number.expanded = true

    local state = lib_tree_node.new_node(
        'state:',
        'state:',
        depth + 1 -- we are a child to the root details node created above, selfsame for all following.
    )
    local status = pull['state']
    local icon = config.icon_set['GitPullRequest']
    if pull['merged_at'] ~= vim.NIL then
        status = 'merged'
        icon = config.icon_set['GitMerge']
    end
    if pull['draft'] == true then
        status = 'draft'
        icon = config.icon_set['Pencil']
    end
    state.details = {
        name = state.name,
        detail = status,
        icon = icon,
    }
    state.expanded = true

    local author = lib_tree_node.new_node(
        'author:',
        'author:',
        depth + 1 -- we are a child to the root details node created above, selfsame for all following.
    )
    author.details = {
        name = author.name,
        detail = pull['user']['login'],
        icon = config.icon_set['Account'],
    }
    author.expanded = true

    local base = lib_tree_node.new_node(
        'base:',
        'base:',
        depth + 1 -- we are a child to the root details node created above, selfsame for all following.
    )
    base.details = {
        name = base.name,
        detail = pull['base']['label'],
        icon = config.icon_set['GitBranch'],
    }
    base.expanded = true

    local head = lib_tree_node.new_node(
        'head:',
        'head:',
        depth + 1 -- we are a child to the root details node created above, selfsame for all following.
    )
    head.details = {
        name = head.name,
        detail = pull['head']['label'],
        icon = config.icon_set['GitBranch'],
    }
    head.expanded = true

    local repo = lib_tree_node.new_node(
        'repo:',
        'repo:',
        depth + 1 -- we are a child to the root details node created above, selfsame for all following.
    )
    repo.details = {
        name = repo.name,
        detail = pull['base']['repo']['full_name'],
        icon = config.icon_set['GitRepo'],
    }
    repo.expanded = true

    local labels = lib_tree_node.new_node(
        'labels:',
        'labels',
        depth + 1 -- we are a child to the root details node created above, selfsame for all following.
    )
    labels.details = {
        name = labels.name,
        detail = '',
        icon = config.icon_set['Bookmark'],
    }
    labels.expanded = true
    for _, label in ipairs(pull['labels']) do
        local l_node = lib_tree_node.new_node(
            label['name'],
            label['id'],
            depth + 2 -- we are a child to the root details node created above, selfsame for all following.
        )
        l_node.label = label
        l_node.details = {
            name = l_node.name,
            detail = '',
            icon = config.icon_set['Bookmark'],
        }
        l_node.expanded = true
        table.insert(labels.children, l_node)
    end

    local assignees = lib_tree_node.new_node(
        'assignees:',
        'assignees',
        depth + 1 -- we are a child to the root details node created above, selfsame for all following.
    )
    assignees.details = {
        name = assignees.name,
        detail = '',
        icon = '',
    }
    assignees.expanded = true
    for _, assignee in ipairs(pull['assignees']) do
        local a_node = lib_tree_node.new_node(
            assignee['login'],
            'assignees:' .. assignee['login'],
            depth + 2 -- we are a child to the root details node created above, selfsame for all following.
        )
        a_node.assignee = a_node
        a_node.details = {
            name = a_node.name,
            detail = '',
            icon = config.icon_set['Account'],
        }
        a_node.expanded = true
        table.insert(assignees.children, a_node)
    end

    -- add all our details children
    local children = {
        number,
        author,
        state,
        repo,
        base,
        head,
    }
    if #labels.children > 0 then
        table.insert(children, labels)
    end
    if #assignees.children > 0 then
        table.insert(children, assignees)
    end

    root.children = children
    return root
end

return M
